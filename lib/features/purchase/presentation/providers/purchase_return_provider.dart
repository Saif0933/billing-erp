import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/purchase_return_dto.dart';
import '../../data/services/purchase_return_api_service.dart';
import '../../domain/models/purchase_return_model.dart';

final purchaseReturnApiServiceProvider = Provider<PurchaseReturnApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PurchaseReturnApiService(apiClient);
});

class PurchaseReturnFilterState {
  final String searchQuery;
  final String selectedStatus; // 'All', 'Draft', 'Confirmed', 'Adjusted', 'Refunded', 'Cancelled'
  final String sortBy;
  final int currentPage;
  final int rowsPerPage;

  const PurchaseReturnFilterState({
    this.searchQuery = '',
    this.selectedStatus = 'All',
    this.sortBy = 'Date (Newest)',
    this.currentPage = 1,
    this.rowsPerPage = 10,
  });

  PurchaseReturnFilterState copyWith({
    String? searchQuery,
    String? selectedStatus,
    String? sortBy,
    int? currentPage,
    int? rowsPerPage,
  }) {
    return PurchaseReturnFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      sortBy: sortBy ?? this.sortBy,
      currentPage: currentPage ?? this.currentPage,
      rowsPerPage: rowsPerPage ?? this.rowsPerPage,
    );
  }
}

class PurchaseReturnListState {
  final List<PurchaseReturn> returns;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final PurchaseReturnMetricsDto? metrics;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const PurchaseReturnListState({
    this.returns = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.metrics,
    this.total = 0,
    this.page = 1,
    this.limit = 50,
    this.totalPages = 1,
  });

  PurchaseReturnListState copyWith({
    List<PurchaseReturn>? returns,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
    PurchaseReturnMetricsDto? metrics,
    int? total,
    int? page,
    int? limit,
    int? totalPages,
  }) {
    return PurchaseReturnListState(
      returns: returns ?? this.returns,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      metrics: metrics ?? this.metrics,
      total: total ?? this.total,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}

class PurchaseReturnListNotifier extends StateNotifier<PurchaseReturnListState> {
  final PurchaseReturnApiService _apiService;
  final Ref _ref;

  PurchaseReturnListNotifier(this._apiService, this._ref)
      : super(const PurchaseReturnListState()) {
    loadReturns();
  }

  Future<void> loadReturns({bool refresh = false}) async {
    final filter = _ref.read(purchaseReturnFilterProvider);
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _apiService.getPurchaseReturns(
        search: filter.searchQuery.isNotEmpty ? filter.searchQuery : null,
        status: filter.selectedStatus,
        page: filter.currentPage,
        limit: filter.rowsPerPage,
      );

      PurchaseReturnMetricsDto? metrics;
      try {
        metrics = await _apiService.getMetrics();
      } catch (_) {}

      state = state.copyWith(
        returns: res.returns,
        total: res.total,
        page: res.page,
        limit: res.limit,
        totalPages: res.totalPages,
        metrics: metrics,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception:', '').trim(),
      );
    }
  }

  Future<PurchaseReturn?> createReturn(
    PurchaseReturn item, {
    PurchaseReturnStatus saveAs = PurchaseReturnStatus.confirmed,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final created = await _apiService.createPurchaseReturn(
        item,
        saveAs: saveAs,
      );
      state = state.copyWith(
        returns: [created, ...state.returns],
        isSaving: false,
      );
      await loadReturns(refresh: true);
      return created;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: e.toString().replaceAll('Exception:', '').trim(),
      );
      rethrow;
    }
  }

  Future<void> updateStatus(String id, PurchaseReturnStatus status) async {
    try {
      final updated = await _apiService.updateStatus(id, status);
      state = state.copyWith(
        returns: state.returns
            .map((r) => r.id == id ? updated : r)
            .toList(),
      );
      await loadReturns(refresh: true);
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception:', '').trim(),
      );
      rethrow;
    }
  }

  Future<void> deleteReturn(String id) async {
    try {
      await _apiService.deletePurchaseReturn(id);
      state = state.copyWith(
        returns: state.returns.where((r) => r.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception:', '').trim(),
      );
      rethrow;
    }
  }
}

final purchaseReturnListProvider =
    StateNotifierProvider<PurchaseReturnListNotifier, PurchaseReturnListState>(
        (ref) {
  final apiService = ref.watch(purchaseReturnApiServiceProvider);
  return PurchaseReturnListNotifier(apiService, ref);
});

/// Backward-compatible list of returns (same shape as older mock provider)
final purchaseReturnsProvider = Provider<List<PurchaseReturn>>((ref) {
  return ref.watch(purchaseReturnListProvider).returns;
});

class PurchaseReturnFilterNotifier
    extends StateNotifier<PurchaseReturnFilterState> {
  PurchaseReturnFilterNotifier(this._ref)
      : super(const PurchaseReturnFilterState());

  final Ref _ref;

  void setSearchQuery(String q) {
    state = state.copyWith(searchQuery: q, currentPage: 1);
    _ref.read(purchaseReturnListProvider.notifier).loadReturns();
  }

  void setSelectedStatus(String s) {
    state = state.copyWith(selectedStatus: s, currentPage: 1);
    _ref.read(purchaseReturnListProvider.notifier).loadReturns();
  }

  void setSortBy(String s) => state = state.copyWith(sortBy: s);

  void setPage(int p) {
    state = state.copyWith(currentPage: p);
    _ref.read(purchaseReturnListProvider.notifier).loadReturns();
  }

  void setRowsPerPage(int n) {
    state = state.copyWith(rowsPerPage: n, currentPage: 1);
    _ref.read(purchaseReturnListProvider.notifier).loadReturns();
  }

  void reset() {
    state = const PurchaseReturnFilterState();
    _ref.read(purchaseReturnListProvider.notifier).loadReturns();
  }
}

final purchaseReturnFilterProvider = StateNotifierProvider<
    PurchaseReturnFilterNotifier, PurchaseReturnFilterState>((ref) {
  return PurchaseReturnFilterNotifier(ref);
});

class PurchaseReturnMetrics {
  final int totalReturnsCount;
  final double totalReturnValue;
  final double adjustedAgainstBills;
  final double pendingRefunds;
  final List<PurchaseReturn> filteredItems;

  const PurchaseReturnMetrics({
    required this.totalReturnsCount,
    required this.totalReturnValue,
    required this.adjustedAgainstBills,
    required this.pendingRefunds,
    required this.filteredItems,
  });
}

final purchaseReturnMetricsProvider = Provider<PurchaseReturnMetrics>((ref) {
  final listState = ref.watch(purchaseReturnListProvider);
  final filter = ref.watch(purchaseReturnFilterProvider);
  final allReturns = listState.returns;
  final apiMetrics = listState.metrics;

  var filtered = List<PurchaseReturn>.from(allReturns);

  if (filter.sortBy == 'Date (Newest)') {
    filtered.sort((a, b) => b.returnDate.compareTo(a.returnDate));
  } else if (filter.sortBy == 'Date (Oldest)') {
    filtered.sort((a, b) => a.returnDate.compareTo(b.returnDate));
  } else if (filter.sortBy == 'Amount (High to Low)') {
    filtered.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
  } else if (filter.sortBy == 'Amount (Low to High)') {
    filtered.sort((a, b) => a.totalAmount.compareTo(b.totalAmount));
  }

  return PurchaseReturnMetrics(
    totalReturnsCount:
        apiMetrics?.totalReturnsCount ?? listState.total,
    totalReturnValue: apiMetrics?.totalReturnValue ??
        allReturns.fold(0.0, (sum, r) => sum + r.totalAmount),
    adjustedAgainstBills: apiMetrics?.adjustedAgainstBills ??
        allReturns
            .where((r) =>
                r.status == PurchaseReturnStatus.adjusted ||
                r.status == PurchaseReturnStatus.refunded)
            .fold(0.0, (sum, r) => sum + r.amountAdjusted),
    pendingRefunds: apiMetrics?.pendingRefunds ??
        allReturns
            .where((r) =>
                r.status == PurchaseReturnStatus.confirmed ||
                r.status == PurchaseReturnStatus.draft)
            .fold(
              0.0,
              (sum, r) => sum + (r.totalAmount - r.amountAdjusted),
            ),
    filteredItems: filtered,
  );
});
