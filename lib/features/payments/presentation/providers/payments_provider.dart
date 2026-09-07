import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/billing_models.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/providers/billing_repository.dart';
import '../../data/models/payment_models_dto.dart';
import '../../data/services/payments_api_service.dart';

/// Provider for PaymentsApiService
final paymentsApiServiceProvider = Provider<PaymentsApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PaymentsApiService(apiClient);
});

/// State for recording customer receipts
class ReceiptEntryState {
  final bool isLoading;
  final bool isLoadingInvoices;
  final String? error;
  final List<ReceiptUnpaidInvoiceDto> unpaidInvoices;

  const ReceiptEntryState({
    this.isLoading = false,
    this.isLoadingInvoices = false,
    this.error,
    this.unpaidInvoices = const [],
  });

  ReceiptEntryState copyWith({
    bool? isLoading,
    bool? isLoadingInvoices,
    String? error,
    bool clearError = false,
    List<ReceiptUnpaidInvoiceDto>? unpaidInvoices,
  }) {
    return ReceiptEntryState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingInvoices: isLoadingInvoices ?? this.isLoadingInvoices,
      error: clearError ? null : (error ?? this.error),
      unpaidInvoices: unpaidInvoices ?? this.unpaidInvoices,
    );
  }
}

class ReceiptEntryNotifier extends StateNotifier<ReceiptEntryState> {
  final PaymentsApiService _apiService;
  final Ref _ref;

  ReceiptEntryNotifier(this._apiService, this._ref) : super(const ReceiptEntryState());

  /// Fetch live unpaid invoices from backend for selected customer
  Future<List<ReceiptUnpaidInvoiceDto>> loadUnpaidInvoices(String customerId) async {
    state = state.copyWith(isLoadingInvoices: true, clearError: true);
    try {
      final invoices = await _apiService.getUnpaidInvoices(customerId);
      state = state.copyWith(isLoadingInvoices: false, unpaidInvoices: invoices);
      return invoices;
    } catch (e) {
      state = state.copyWith(isLoadingInvoices: false, error: e.toString());
      return [];
    }
  }

  /// Submit customer receipt to backend and sync with local repository
  Future<Receipt> submitReceipt({
    required String customerId,
    required String customerName,
    required double amount,
    required DateTime date,
    required String paymentMode,
    String? referenceNumber,
    String? notes,
    required Map<String, double> allocations,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final allocationList = allocations.entries.map((e) {
        return {
          'invoiceId': e.key,
          'allocatedAmount': e.value,
        };
      }).toList();

      final resDto = await _apiService.createReceipt(
        customerId: customerId,
        amount: amount,
        receiptDate: date,
        paymentMode: paymentMode,
        referenceNumber: referenceNumber,
        notes: notes,
        allocations: allocationList,
      );

      final domainReceipt = resDto.toDomain();

      // Sync with local BillingRepository
      await _ref.read(billingRepositoryProvider.notifier).addReceipt(domainReceipt);

      state = state.copyWith(isLoading: false);
      return domainReceipt;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

final receiptEntryProvider =
    StateNotifierProvider<ReceiptEntryNotifier, ReceiptEntryState>((ref) {
  final apiService = ref.watch(paymentsApiServiceProvider);
  return ReceiptEntryNotifier(apiService, ref);
});

/// State for recording supplier payments
class PaymentEntryState {
  final bool isLoading;
  final bool isLoadingPurchases;
  final String? error;
  final List<PaymentUnpaidPurchaseDto> unpaidPurchases;

  const PaymentEntryState({
    this.isLoading = false,
    this.isLoadingPurchases = false,
    this.error,
    this.unpaidPurchases = const [],
  });

  PaymentEntryState copyWith({
    bool? isLoading,
    bool? isLoadingPurchases,
    String? error,
    bool clearError = false,
    List<PaymentUnpaidPurchaseDto>? unpaidPurchases,
  }) {
    return PaymentEntryState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingPurchases: isLoadingPurchases ?? this.isLoadingPurchases,
      error: clearError ? null : (error ?? this.error),
      unpaidPurchases: unpaidPurchases ?? this.unpaidPurchases,
    );
  }
}

class PaymentEntryNotifier extends StateNotifier<PaymentEntryState> {
  final PaymentsApiService _apiService;
  final Ref _ref;

  PaymentEntryNotifier(this._apiService, this._ref) : super(const PaymentEntryState());

  /// Fetch live unpaid purchases from backend for selected supplier
  Future<List<PaymentUnpaidPurchaseDto>> loadUnpaidPurchases(String supplierId) async {
    state = state.copyWith(isLoadingPurchases: true, clearError: true);
    try {
      final purchases = await _apiService.getUnpaidPurchases(supplierId);
      state = state.copyWith(isLoadingPurchases: false, unpaidPurchases: purchases);
      return purchases;
    } catch (e) {
      state = state.copyWith(isLoadingPurchases: false, error: e.toString());
      return [];
    }
  }

  /// Submit supplier payment to backend and sync with local repository
  Future<Payment> submitPayment({
    required String supplierId,
    required String supplierName,
    required double amount,
    required DateTime date,
    required String paymentMode,
    String? referenceNumber,
    String? notes,
    required Map<String, double> allocations,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final allocationList = allocations.entries.map((e) {
        return {
          'purchaseId': e.key,
          'amountAllocated': e.value,
        };
      }).toList();

      final resDto = await _apiService.createPayment(
        supplierId: supplierId,
        amount: amount,
        paymentDate: date,
        paymentMode: paymentMode,
        referenceNumber: referenceNumber,
        notes: notes,
        allocations: allocationList,
      );

      final domainPayment = resDto.toDomain();

      // Sync with local BillingRepository
      await _ref.read(billingRepositoryProvider.notifier).addPayment(domainPayment);

      state = state.copyWith(isLoading: false);
      return domainPayment;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

final paymentEntryProvider =
    StateNotifierProvider<PaymentEntryNotifier, PaymentEntryState>((ref) {
  final apiService = ref.watch(paymentsApiServiceProvider);
  return PaymentEntryNotifier(apiService, ref);
});
