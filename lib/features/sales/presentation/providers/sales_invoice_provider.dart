import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/sales_invoice_dto.dart';
import '../../data/services/sales_invoice_api_service.dart';

/// Provider for SalesInvoiceApiService
final salesInvoiceApiServiceProvider = Provider<SalesInvoiceApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SalesInvoiceApiService(apiClient);
});

/// FutureProvider for next sequential invoice number
final salesInvoiceNextNumberProvider = FutureProvider<String>((ref) async {
  final api = ref.watch(salesInvoiceApiServiceProvider);
  return api.getNextInvoiceNumber();
});

/// FutureProvider for daily sales metrics
final salesInvoiceMetricsProvider = FutureProvider<SalesInvoiceMetricsDto?>((ref) async {
  final api = ref.watch(salesInvoiceApiServiceProvider);
  return api.getMetrics();
});

/// FutureProvider for held sales invoices
final salesInvoiceHeldListProvider = FutureProvider<List<SalesInvoiceDto>>((ref) async {
  final api = ref.watch(salesInvoiceApiServiceProvider);
  return api.getHeldInvoices();
});

/// State of Sales Invoice Operations
class SalesInvoiceState {
  final bool isLoading;
  final bool isLoadingList;
  final String? error;
  final String currentInvoiceNumber;
  final List<SalesInvoiceDto> invoices;
  final List<SalesInvoiceDto> heldInvoices;
  final SalesInvoiceMetricsDto? metrics;
  final SalesInvoiceResponse? lastCreatedInvoice;

  const SalesInvoiceState({
    this.isLoading = false,
    this.isLoadingList = false,
    this.error,
    this.currentInvoiceNumber = 'TB/25-26/000123',
    this.invoices = const [],
    this.heldInvoices = const [],
    this.metrics,
    this.lastCreatedInvoice,
  });

  SalesInvoiceState copyWith({
    bool? isLoading,
    bool? isLoadingList,
    String? error,
    bool clearError = false,
    String? currentInvoiceNumber,
    List<SalesInvoiceDto>? invoices,
    List<SalesInvoiceDto>? heldInvoices,
    SalesInvoiceMetricsDto? metrics,
    SalesInvoiceResponse? lastCreatedInvoice,
  }) {
    return SalesInvoiceState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingList: isLoadingList ?? this.isLoadingList,
      error: clearError ? null : (error ?? this.error),
      currentInvoiceNumber: currentInvoiceNumber ?? this.currentInvoiceNumber,
      invoices: invoices ?? this.invoices,
      heldInvoices: heldInvoices ?? this.heldInvoices,
      metrics: metrics ?? this.metrics,
      lastCreatedInvoice: lastCreatedInvoice ?? this.lastCreatedInvoice,
    );
  }
}

/// StateNotifier for orchestrating Sales Invoice backend workflows
class SalesInvoiceNotifier extends StateNotifier<SalesInvoiceState> {
  final SalesInvoiceApiService _apiService;

  SalesInvoiceNotifier(this._apiService) : super(const SalesInvoiceState()) {
    fetchNextNumber();
    refreshHeldInvoices();
    refreshInvoices();
    refreshMetrics();
  }

  /// 1. Fetch next auto-incremented invoice number
  Future<String> fetchNextNumber() async {
    try {
      final num = await _apiService.getNextInvoiceNumber();
      state = state.copyWith(currentInvoiceNumber: num);
      return num;
    } catch (_) {
      return state.currentInvoiceNumber;
    }
  }

  /// 2. Refresh held invoices list
  Future<void> refreshHeldInvoices() async {
    try {
      final list = await _apiService.getHeldInvoices();
      state = state.copyWith(heldInvoices: list);
    } catch (_) {}
  }

  /// 3. Refresh saved sales invoices for the billing list
  Future<List<SalesInvoiceDto>> refreshInvoices({
    String? search,
    String? status,
  }) async {
    state = state.copyWith(isLoadingList: true, clearError: true);
    try {
      final list = await _apiService.getSalesInvoices(
        search: search,
        status: status,
        limit: 200,
      );
      final visible = list.where((inv) => !inv.isHeld).toList();
      state = state.copyWith(isLoadingList: false, invoices: visible);
      return visible;
    } catch (e) {
      state = state.copyWith(isLoadingList: false, error: e.toString());
      return state.invoices;
    }
  }

  /// 4. Refresh metrics
  Future<void> refreshMetrics() async {
    try {
      final m = await _apiService.getMetrics();
      state = state.copyWith(metrics: m);
    } catch (_) {}
  }

  /// 4. Submit confirmed invoice to backend
  Future<SalesInvoiceResponse> createInvoice(Map<String, dynamic> payload) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _apiService.createSalesInvoice(payload);
      state = state.copyWith(
        isLoading: false,
        lastCreatedInvoice: res,
      );
      await fetchNextNumber();
      await refreshInvoices();
      return res;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// 5. Hold / Park bill on backend
  Future<SalesInvoiceDto> holdBill(Map<String, dynamic> payload) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _apiService.holdCart(payload);
      await refreshHeldInvoices();
      await fetchNextNumber();
      state = state.copyWith(isLoading: false);
      return res;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// 6. Resume held bill
  Future<SalesInvoiceDto> resumeHeldBill(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _apiService.resumeHeldInvoice(id);
      await refreshHeldInvoices();
      state = state.copyWith(isLoading: false);
      return res;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

final salesInvoiceNotifierProvider =
    StateNotifierProvider<SalesInvoiceNotifier, SalesInvoiceState>((ref) {
  final api = ref.watch(salesInvoiceApiServiceProvider);
  return SalesInvoiceNotifier(api);
});
