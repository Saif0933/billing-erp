import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/billing_models.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/providers/billing_repository.dart';
import '../../data/models/stock_valuation_dto.dart';
import '../../data/services/stock_valuation_api_service.dart';

final stockValuationApiServiceProvider =
    Provider<StockValuationApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return StockValuationApiService(apiClient);
});

class StockValuationState {
  final bool isLoading;
  final bool isSavingAdjustment;
  final String? error;
  final String searchQuery;
  final bool lowStockOnly;
  final String? warehouseId;
  final StockValuationSummaryDto? summary;
  final List<StockValuationItemDto> items;
  final List<StockLedgerEntryDto> movements;
  final bool isUsingLocalFallback;

  const StockValuationState({
    this.isLoading = false,
    this.isSavingAdjustment = false,
    this.error,
    this.searchQuery = '',
    this.lowStockOnly = false,
    this.warehouseId,
    this.summary,
    this.items = const [],
    this.movements = const [],
    this.isUsingLocalFallback = false,
  });

  StockValuationState copyWith({
    bool? isLoading,
    bool? isSavingAdjustment,
    String? error,
    bool clearError = false,
    String? searchQuery,
    bool? lowStockOnly,
    String? warehouseId,
    bool clearWarehouseId = false,
    StockValuationSummaryDto? summary,
    List<StockValuationItemDto>? items,
    List<StockLedgerEntryDto>? movements,
    bool? isUsingLocalFallback,
  }) {
    return StockValuationState(
      isLoading: isLoading ?? this.isLoading,
      isSavingAdjustment: isSavingAdjustment ?? this.isSavingAdjustment,
      error: clearError ? null : (error ?? this.error),
      searchQuery: searchQuery ?? this.searchQuery,
      lowStockOnly: lowStockOnly ?? this.lowStockOnly,
      warehouseId: clearWarehouseId ? null : (warehouseId ?? this.warehouseId),
      summary: summary ?? this.summary,
      items: items ?? this.items,
      movements: movements ?? this.movements,
      isUsingLocalFallback:
          isUsingLocalFallback ?? this.isUsingLocalFallback,
    );
  }

  List<Product> get products => items.map((e) => e.toProduct()).toList();

  List<StockMovement> get domainMovements =>
      movements.map((e) => e.toDomain()).toList();
}

class StockValuationNotifier extends StateNotifier<StockValuationState> {
  final StockValuationApiService _apiService;
  final Ref _ref;

  StockValuationNotifier(this._apiService, this._ref)
      : super(const StockValuationState()) {
    loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait([
        _apiService.getSummary(warehouseId: state.warehouseId),
        _apiService.getItems(
          search: state.searchQuery,
          warehouseId: state.warehouseId,
          lowStockOnly: state.lowStockOnly,
          limit: 200,
        ),
        _apiService.getMovements(
          search: state.searchQuery,
          warehouseId: state.warehouseId,
          limit: 200,
        ),
      ]);

      final summary = results[0] as StockValuationSummaryDto;
      final itemsRes = results[1] as StockValuationItemsResponseDto;
      final movementsRes = results[2] as StockMovementsResponseDto;

      state = state.copyWith(
        isLoading: false,
        summary: summary,
        items: itemsRes.items,
        movements: movementsRes.items,
        isUsingLocalFallback: false,
      );
    } catch (e) {
      _computeFromLocalRepository(fallbackError: e.toString());
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    loadData();
  }

  void setLowStockOnly(bool value) {
    state = state.copyWith(lowStockOnly: value);
    loadData();
  }

  void setWarehouseId(String? warehouseId) {
    if (warehouseId == null || warehouseId.trim().isEmpty) {
      state = state.copyWith(clearWarehouseId: true);
    } else {
      state = state.copyWith(warehouseId: warehouseId.trim());
    }
    loadData();
  }

  Future<bool> createAdjustment({
    required String productId,
    required double quantity,
    required String reason,
    String? warehouseId,
  }) async {
    state = state.copyWith(isSavingAdjustment: true, clearError: true);
    try {
      await _apiService.createAdjustment(
        productId: productId,
        quantity: quantity,
        reason: reason,
        warehouseId: warehouseId ?? state.warehouseId,
      );

      await _ref.read(billingRepositoryProvider.notifier).adjustStock(
            productId,
            quantity,
            reason,
            warehouseId: warehouseId ?? state.warehouseId ?? 'main',
          );

      state = state.copyWith(isSavingAdjustment: false);
      await loadData();
      return true;
    } catch (e) {
      try {
        await _ref.read(billingRepositoryProvider.notifier).adjustStock(
              productId,
              quantity,
              reason,
              warehouseId: warehouseId ?? state.warehouseId ?? 'main',
            );
        _computeFromLocalRepository();
        state = state.copyWith(isSavingAdjustment: false);
        return true;
      } catch (_) {
        state = state.copyWith(
          isSavingAdjustment: false,
          error: e.toString(),
        );
        return false;
      }
    }
  }

  void _computeFromLocalRepository({String? fallbackError}) {
    final billingState = _ref.read(billingRepositoryProvider);
    final query = state.searchQuery.trim().toLowerCase();

    final products = billingState.products.where((p) {
      final matchesQuery = query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          p.code.toLowerCase().contains(query) ||
          p.sku.toLowerCase().contains(query);
      final matchesLow =
          !state.lowStockOnly || p.currentStock <= p.minStockLevel;
      return matchesQuery && matchesLow;
    }).toList();

    final items = products
        .map(
          (p) => StockValuationItemDto(
            productId: p.id,
            name: p.name,
            itemCode: p.code,
            sku: p.sku,
            barcode: p.barcode,
            primaryUnit: p.primaryUnit,
            category: p.category,
            purchasePrice: p.purchasePrice,
            sellingPrice: p.sellingPrice,
            openingStock: p.openingStock,
            currentStock: p.currentStock,
            minStockLevel: p.minStockLevel,
            stockValue: p.currentStock * p.purchasePrice,
            isLowStock: p.currentStock <= p.minStockLevel,
            isActive: p.isActive,
          ),
        )
        .toList();

    final totalValuation =
        items.fold<double>(0, (sum, i) => sum + i.stockValue);
    final totalUnits = items.fold<double>(0, (sum, i) => sum + i.currentStock);
    final lowStockCount = items.where((i) => i.isLowStock).length;

    final movements = billingState.stockMovements.where((m) {
      return query.isEmpty ||
          m.productName.toLowerCase().contains(query) ||
          m.referenceNumber.toLowerCase().contains(query);
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final ledger = movements
        .map(
          (m) => StockLedgerEntryDto(
            id: m.id,
            productId: m.productId,
            productName: m.productName,
            warehouseId: m.warehouseId,
            movementType: m.type.name,
            quantity: m.quantity,
            referenceNumber: m.referenceNumber,
            movementDate: m.date,
            createdAt: m.date,
          ),
        )
        .toList();

    state = state.copyWith(
      isLoading: false,
      error: fallbackError,
      summary: StockValuationSummaryDto(
        totalStockValuation: totalValuation,
        totalUnits: totalUnits,
        uniqueProductCount: items.length,
        inStockCount: items.where((i) => i.currentStock > 0).length,
        lowStockCount: lowStockCount,
        zeroStockCount: items.where((i) => i.currentStock <= 0).length,
      ),
      items: items,
      movements: ledger,
      isUsingLocalFallback: true,
    );
  }
}

final stockValuationProvider =
    StateNotifierProvider<StockValuationNotifier, StockValuationState>((ref) {
  final api = ref.watch(stockValuationApiServiceProvider);
  return StockValuationNotifier(api, ref);
});

