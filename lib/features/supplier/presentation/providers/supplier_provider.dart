import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/billing_models.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/providers/billing_repository.dart';
import '../../data/models/supplier_dto.dart';
import '../../data/services/supplier_api_service.dart';

/// Provider for SupplierApiService
final supplierApiServiceProvider = Provider<SupplierApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SupplierApiService(apiClient);
});

/// State for the Supplier Directory screen
class SupplierListState {
  final List<Supplier> suppliers;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final String selectedGroupFilter;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final SupplierMetricsDto? metrics;

  const SupplierListState({
    this.suppliers = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.selectedGroupFilter = 'All',
    this.total = 0,
    this.page = 1,
    this.limit = 50,
    this.totalPages = 1,
    this.metrics,
  });

  SupplierListState copyWith({
    List<Supplier>? suppliers,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? searchQuery,
    String? selectedGroupFilter,
    int? total,
    int? page,
    int? limit,
    int? totalPages,
    SupplierMetricsDto? metrics,
  }) {
    return SupplierListState(
      suppliers: suppliers ?? this.suppliers,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      searchQuery: searchQuery ?? this.searchQuery,
      selectedGroupFilter: selectedGroupFilter ?? this.selectedGroupFilter,
      total: total ?? this.total,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      totalPages: totalPages ?? this.totalPages,
      metrics: metrics ?? this.metrics,
    );
  }
}

/// StateNotifier for supplier operations, connecting the frontend directly to the backend
class SupplierListNotifier extends StateNotifier<SupplierListState> {
  final SupplierApiService _apiService;
  final Ref _ref;

  SupplierListNotifier(this._apiService, this._ref)
      : super(const SupplierListState()) {
    loadSuppliers();
  }

  /// Load suppliers from backend API
  Future<void> loadSuppliers({bool refresh = false}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final groupParam = state.selectedGroupFilter == 'All'
          ? null
          : state.selectedGroupFilter;

      final res = await _apiService.getSuppliers(
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        supplierGroup: groupParam,
        isActive: true,
        page: state.page,
        limit: state.limit,
      );


      SupplierMetricsDto? metrics;
      try {
        metrics = await _apiService.getSupplierMetrics();
      } catch (_) {}

      state = state.copyWith(
        suppliers: res.suppliers,
        total: res.total,
        page: res.page,
        limit: res.limit,
        totalPages: res.totalPages,
        metrics: metrics,
        isLoading: false,
        clearError: true,
      );

      // Sync with billing repository so offline/local features have active supplier list
      _syncToBillingRepo(res.suppliers);
    } catch (e) {
      // If network/server fails, fall back to billing repository suppliers
      final fallbackSuppliers =
          _ref.read(billingRepositoryProvider).suppliers;
      state = state.copyWith(
        suppliers: fallbackSuppliers,
        total: fallbackSuppliers.length,
        isLoading: false,
        error: e.toString().replaceAll('Exception:', '').trim(),
      );
    }
  }

  /// Update search query and reload
  void setSearchQuery(String query) {
    if (state.searchQuery != query) {
      state = state.copyWith(searchQuery: query, page: 1);
      loadSuppliers();
    }
  }

  /// Update group filter and reload
  void setGroupFilter(String group) {
    if (state.selectedGroupFilter != group) {
      state = state.copyWith(selectedGroupFilter: group, page: 1);
      loadSuppliers();
    }
  }

  /// Create a new supplier on backend
  Future<Supplier> addSupplier(Supplier supplier) async {
    state = state.copyWith(isLoading: true);
    try {
      final created = await _apiService.createSupplier(supplier);

      final updatedList = [created, ...state.suppliers];
      state = state.copyWith(
        suppliers: updatedList,
        total: state.total + 1,
        isLoading: false,
        clearError: true,
      );

      // Sync with billing repository
      await _ref.read(billingRepositoryProvider.notifier).addSupplier(created);
      return created;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  /// Update an existing supplier on backend
  Future<Supplier> updateSupplier(Supplier supplier) async {
    state = state.copyWith(isLoading: true);
    try {
      final updated = await _apiService.updateSupplier(supplier);

      final updatedList = state.suppliers
          .map((s) => s.id == updated.id ? updated : s)
          .toList();
      state = state.copyWith(
        suppliers: updatedList,
        isLoading: false,
        clearError: true,
      );

      // Sync with billing repository
      await _ref
          .read(billingRepositoryProvider.notifier)
          .updateSupplier(updated);
      return updated;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  /// Delete a supplier on backend
  Future<void> deleteSupplier(String supplierId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _apiService.deleteSupplier(supplierId);

      final updatedList =
          state.suppliers.where((s) => s.id != supplierId).toList();
      state = state.copyWith(
        suppliers: updatedList,
        total: state.total > 0 ? state.total - 1 : 0,
        isLoading: false,
        clearError: true,
      );

      // Sync with billing repository
      await _ref
          .read(billingRepositoryProvider.notifier)
          .deleteSupplier(supplierId);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  void _syncToBillingRepo(List<Supplier> list) {
    try {
      _ref.read(billingRepositoryProvider.notifier).setSuppliers(list);
    } catch (_) {}
  }
}

/// Main Supplier Provider for Supplier directory & operations
final supplierProvider =
    StateNotifierProvider<SupplierListNotifier, SupplierListState>((ref) {
  final apiService = ref.watch(supplierApiServiceProvider);
  return SupplierListNotifier(apiService, ref);
});

/// Future provider for fetching supplier details by ID from backend
final supplierDetailProvider =
    FutureProvider.family<SupplierDetailDto, String>((ref, supplierId) async {
  final apiService = ref.watch(supplierApiServiceProvider);
  return apiService.getSupplierById(supplierId);
});
