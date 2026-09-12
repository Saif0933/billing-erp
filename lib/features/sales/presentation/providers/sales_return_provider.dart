import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/sales_return_dto.dart';
import '../../data/services/sales_return_api_service.dart';

/// Provider for SalesReturnApiService
final salesReturnApiServiceProvider = Provider<SalesReturnApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SalesReturnApiService(apiClient);
});

/// FutureProvider for next sequential return / credit note number
final salesReturnNextNumberProvider = FutureProvider<String>((ref) async {
  final api = ref.watch(salesReturnApiServiceProvider);
  return api.getNextReturnNumber();
});

/// FutureProvider for sales return metrics
final salesReturnMetricsProvider =
    FutureProvider<SalesReturnSummaryMetricsDto?>((ref) async {
  final api = ref.watch(salesReturnApiServiceProvider);
  return api.getMetrics();
});

/// State for Sales Return Operations
class SalesReturnState {
  final bool isLoading;
  final bool isLoadingList;
  final String? error;
  final String currentReturnNumber;
  final List<SalesReturnDto> returnsList;
  final SalesReturnSummaryMetricsDto? metrics;
  final SalesReturnDto? lastCreatedReturn;

  const SalesReturnState({
    this.isLoading = false,
    this.isLoadingList = false,
    this.error,
    this.currentReturnNumber = '',
    this.returnsList = const [],
    this.metrics,
    this.lastCreatedReturn,
  });

  SalesReturnState copyWith({
    bool? isLoading,
    bool? isLoadingList,
    String? error,
    bool clearError = false,
    String? currentReturnNumber,
    List<SalesReturnDto>? returnsList,
    SalesReturnSummaryMetricsDto? metrics,
    SalesReturnDto? lastCreatedReturn,
  }) {
    return SalesReturnState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingList: isLoadingList ?? this.isLoadingList,
      error: clearError ? null : (error ?? this.error),
      currentReturnNumber: currentReturnNumber ?? this.currentReturnNumber,
      returnsList: returnsList ?? this.returnsList,
      metrics: metrics ?? this.metrics,
      lastCreatedReturn: lastCreatedReturn ?? this.lastCreatedReturn,
    );
  }
}

/// StateNotifier for managing backend Sales Return workflows
class SalesReturnNotifier extends StateNotifier<SalesReturnState> {
  final SalesReturnApiService _apiService;

  SalesReturnNotifier(this._apiService) : super(const SalesReturnState()) {
    fetchNextNumber();
    refreshMetrics();
    refreshReturns();
  }

  /// 1. Fetch next auto-incremented return / credit note number
  Future<String> fetchNextNumber() async {
    try {
      final num = await _apiService.getNextReturnNumber();
      state = state.copyWith(currentReturnNumber: num);
      return num;
    } catch (_) {
      return state.currentReturnNumber;
    }
  }

  /// 2. Refresh return metrics
  Future<void> refreshMetrics() async {
    try {
      final m = await _apiService.getMetrics();
      state = state.copyWith(metrics: m);
    } catch (_) {}
  }

  /// 3. Refresh returns list
  Future<List<SalesReturnDto>> refreshReturns({
    String? search,
    String? customerId,
    String? status,
  }) async {
    state = state.copyWith(isLoadingList: true, clearError: true);
    try {
      final list = await _apiService.getSalesReturns(
        search: search,
        customerId: customerId,
        status: status,
        limit: 200,
      );
      state = state.copyWith(isLoadingList: false, returnsList: list);
      return list;
    } catch (e) {
      state = state.copyWith(isLoadingList: false, error: e.toString());
      return state.returnsList;
    }
  }

  /// 4. Create new Sales Return (Draft or Confirmed)
  Future<SalesReturnDto> createReturn(Map<String, dynamic> payload) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _apiService.createSalesReturn(payload);
      state = state.copyWith(
        isLoading: false,
        lastCreatedReturn: res,
      );
      await fetchNextNumber();
      await refreshMetrics();
      await refreshReturns();
      return res;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// 5. Confirm sales return (inventory restock + ledger credit + credit note)
  Future<SalesReturnDto> confirmReturn(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _apiService.confirmSalesReturn(id);
      await refreshMetrics();
      await refreshReturns();
      state = state.copyWith(isLoading: false);
      return res;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// 6. Cancel sales return (inventory debit reversal + ledger reversal)
  Future<SalesReturnDto> cancelReturn(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _apiService.cancelSalesReturn(id);
      await refreshMetrics();
      await refreshReturns();
      state = state.copyWith(isLoading: false);
      return res;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// 7. Delete sales return (drafts only)
  Future<bool> deleteReturn(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final success = await _apiService.deleteSalesReturn(id);
      await refreshMetrics();
      await refreshReturns();
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

final salesReturnNotifierProvider =
    StateNotifierProvider<SalesReturnNotifier, SalesReturnState>((ref) {
  final api = ref.watch(salesReturnApiServiceProvider);
  return SalesReturnNotifier(api);
});

final salesReturnDetailProvider =
    FutureProvider.family<SalesReturnDto?, String>((ref, id) async {
  final cached = ref.watch(salesReturnNotifierProvider).returnsList.where(
        (r) =>
            r.id == id ||
            r.returnNumber.toLowerCase() == id.toLowerCase(),
      );
  if (cached.isNotEmpty) return cached.first;
  try {
    return await ref.read(salesReturnApiServiceProvider).getReturnById(id);
  } catch (_) {
    return null;
  }
});
