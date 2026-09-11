import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/billing_models.dart';
import '../../../../core/models/warehouse_models.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/providers/billing_repository.dart';
import '../../data/models/goods_warehouse_dto.dart';
import '../../data/services/goods_warehouse_api_service.dart';

final goodsWarehouseApiServiceProvider =
    Provider<GoodsWarehouseApiService?>((ref) {
  try {
    final apiClient = ref.watch(apiClientProvider);
    return GoodsWarehouseApiService(apiClient);
  } catch (_) {
    return null;
  }
});

class GoodsWarehouseState {
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final List<WarehouseLocationDto> warehouses;
  final List<WarehouseProductStockDto> products;
  final List<StockTransferLogDto> transfers;
  final bool isUsingLocalFallback;

  const GoodsWarehouseState({
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.warehouses = const [],
    this.products = const [],
    this.transfers = const [],
    this.isUsingLocalFallback = false,
  });

  GoodsWarehouseState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
    List<WarehouseLocationDto>? warehouses,
    List<WarehouseProductStockDto>? products,
    List<StockTransferLogDto>? transfers,
    bool? isUsingLocalFallback,
  }) {
    return GoodsWarehouseState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      warehouses: warehouses ?? this.warehouses,
      products: products ?? this.products,
      transfers: transfers ?? this.transfers,
      isUsingLocalFallback: isUsingLocalFallback ?? this.isUsingLocalFallback,
    );
  }

  List<Warehouse> get domainWarehouses =>
      warehouses.map((e) => e.toDomain()).toList();

  List<Product> get domainProducts =>
      products.map((e) => e.toProduct()).toList();

  List<StockTransfer> get domainTransfers =>
      transfers.map((e) => e.toDomain()).toList();
}

class GoodsWarehouseNotifier extends StateNotifier<GoodsWarehouseState> {
  final GoodsWarehouseApiService? _apiService;
  final Ref _ref;

  GoodsWarehouseNotifier(this._apiService, this._ref)
      : super(const GoodsWarehouseState()) {
    if (const bool.fromEnvironment('FLUTTER_TEST')) {
      _computeFromLocalRepository();
    } else {
      loadData();
    }
  }

  Future<void> loadData() async {
    if (_apiService == null) {
      _computeFromLocalRepository();
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait([
        _apiService.listWarehouses(),
        _apiService.listProducts(),
        _apiService.listTransfers(limit: 200),
      ]);

      final warehouses = results[0] as WarehouseListResponseDto;
      final products = results[1] as WarehouseProductsResponseDto;
      final transfers = results[2] as StockTransferHistoryResponseDto;

      state = state.copyWith(
        isLoading: false,
        warehouses: warehouses.items,
        products: products.items,
        transfers: transfers.items,
        isUsingLocalFallback: false,
      );
    } catch (e) {
      _computeFromLocalRepository(fallbackError: e.toString());
    }
  }

  Future<bool> saveWarehouse({
    Warehouse? existing,
    required String name,
    required String code,
    required String address,
    required String contact,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      if (_apiService == null) throw Exception('API unavailable');

      if (existing == null) {
        await _apiService.createWarehouse(
          name: name,
          code: code,
          address: address,
          contact: contact,
        );
      } else {
        await _apiService.updateWarehouse(
          id: existing.id,
          name: name,
          code: code,
          address: address,
          contact: contact,
        );
      }

      await _syncLocalWarehouse(
        existing: existing,
        name: name,
        code: code,
        address: address,
        contact: contact,
      );

      state = state.copyWith(isSaving: false);
      await loadData();
      return true;
    } catch (e) {
      try {
        await _syncLocalWarehouse(
          existing: existing,
          name: name,
          code: code,
          address: address,
          contact: contact,
        );
        _computeFromLocalRepository();
        state = state.copyWith(isSaving: false);
        return true;
      } catch (_) {
        state = state.copyWith(isSaving: false, error: e.toString());
        return false;
      }
    }
  }

  Future<bool> recordTransfer({
    required String fromWarehouseId,
    required String toWarehouseId,
    required String referenceNumber,
    required String notes,
    required List<TransferItem> items,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    final transfer = StockTransfer(
      id: 'trans_${DateTime.now().millisecondsSinceEpoch}',
      sourceWarehouseId: fromWarehouseId,
      destinationWarehouseId: toWarehouseId,
      items: items,
      transferDate: DateTime.now(),
      referenceNumber: referenceNumber,
      status: StockTransferStatus.confirmed,
      notes: notes,
    );

    try {
      if (_apiService == null) throw Exception('API unavailable');

      await _apiService.createTransfer(
        fromWarehouseId: fromWarehouseId,
        toWarehouseId: toWarehouseId,
        referenceNumber: referenceNumber,
        notes: notes,
        items: items
            .map(
              (item) => {
                'productId': item.productId,
                'quantity': item.quantity,
              },
            )
            .toList(),
      );

      await _ref.read(billingRepositoryProvider.notifier).transferStock(transfer);
      state = state.copyWith(isSaving: false);
      await loadData();
      return true;
    } catch (e) {
      try {
        await _ref.read(billingRepositoryProvider.notifier).transferStock(transfer);
        _computeFromLocalRepository();
        state = state.copyWith(isSaving: false);
        return true;
      } catch (_) {
        state = state.copyWith(isSaving: false, error: e.toString());
        return false;
      }
    }
  }

  Future<void> _syncLocalWarehouse({
    Warehouse? existing,
    required String name,
    required String code,
    required String address,
    required String contact,
  }) async {
    final repo = _ref.read(billingRepositoryProvider.notifier);
    if (existing == null) {
      await repo.addWarehouse(
        Warehouse(
          id: 'wh_${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          code: code,
          address: address,
          contact: contact,
        ),
      );
    } else {
      await repo.updateWarehouse(
        existing.copyWith(
          name: name,
          code: code,
          address: address,
          contact: contact,
        ),
      );
    }
  }

  void _computeFromLocalRepository({String? fallbackError}) {
    final billingState = _ref.read(billingRepositoryProvider);

    state = state.copyWith(
      isLoading: false,
      error: fallbackError,
      warehouses: billingState.warehouses
          .map(
            (w) => WarehouseLocationDto(
              id: w.id,
              name: w.name,
              code: w.code,
              address: w.address,
              contact: w.contact,
              isActive: w.isActive,
            ),
          )
          .toList(),
      products: billingState.products
          .map(
            (p) => WarehouseProductStockDto(
              productId: p.id,
              name: p.name,
              itemCode: p.code,
              sku: p.sku,
              primaryUnit: p.primaryUnit,
              openingStock: p.openingStock,
              currentStock: p.currentStock,
              warehouseStocks: p.warehouseStocks,
              purchasePrice: p.purchasePrice,
              isActive: p.isActive,
            ),
          )
          .toList(),
      transfers: billingState.stockTransfers
          .map(
            (st) => StockTransferLogDto(
              id: st.id,
              fromWarehouseId: st.sourceWarehouseId,
              toWarehouseId: st.destinationWarehouseId,
              transferDate: st.transferDate,
              notes: st.notes,
              referenceNumber: st.referenceNumber,
              status: st.status.displayName.toUpperCase(),
              items: st.items
                  .map(
                    (item) => StockTransferItemDto(
                      productId: item.productId,
                      productName: item.productName,
                      quantity: item.quantity,
                    ),
                  )
                  .toList(),
            ),
          )
          .toList(),
      isUsingLocalFallback: true,
    );
  }
}

final goodsWarehouseProvider =
    StateNotifierProvider<GoodsWarehouseNotifier, GoodsWarehouseState>((ref) {
  final api = ref.watch(goodsWarehouseApiServiceProvider);
  return GoodsWarehouseNotifier(api, ref);
});
