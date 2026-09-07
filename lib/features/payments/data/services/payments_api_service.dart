import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/payment_models_dto.dart';

class PaymentsApiService {
  final ApiClient _apiClient;

  PaymentsApiService(this._apiClient);

  /// 1. Create a customer receipt with allocations
  Future<ReceiptResponseDto> createReceipt({
    required String customerId,
    required double amount,
    required DateTime receiptDate,
    required String paymentMode,
    String? referenceNumber,
    String? notes,
    List<Map<String, dynamic>> allocations = const [],
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.receipts,
      data: {
        'customerId': customerId,
        'amount': amount,
        'receiptDate': receiptDate.toIso8601String(),
        'paymentMode': paymentMode.toUpperCase(),
        if (referenceNumber != null && referenceNumber.trim().isNotEmpty)
          'referenceNumber': referenceNumber.trim(),
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        'allocations': allocations,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final payload = (data['data'] as Map<String, dynamic>?) ?? data;
    return ReceiptResponseDto.fromJson(payload);
  }

  /// 2. Fetch unpaid/partially-paid invoices for customer receipt allocation
  Future<List<ReceiptUnpaidInvoiceDto>> getUnpaidInvoices(String customerId) async {
    final response = await _apiClient.get(
      '${ApiEndpoints.receipts}/customer/$customerId/unpaid-invoices',
    );

    final data = response.data;
    List<dynamic> listRaw = [];
    if (data is Map<String, dynamic>) {
      final inner = data['data'];
      if (inner is List) {
        listRaw = inner;
      }
    } else if (data is List) {
      listRaw = data;
    }

    return listRaw
        .map((item) => ReceiptUnpaidInvoiceDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// 3. Get receipt KPI metrics
  Future<ReceiptMetricsDto> getReceiptMetrics() async {
    final response = await _apiClient.get('${ApiEndpoints.receipts}/metrics/summary');
    final data = response.data as Map<String, dynamic>;
    final payload = (data['data'] as Map<String, dynamic>?) ?? data;
    return ReceiptMetricsDto.fromJson(payload);
  }

  /// 4. Record a supplier payment with purchase allocations
  Future<PaymentResponseDto> createPayment({
    required String supplierId,
    required double amount,
    required DateTime paymentDate,
    required String paymentMode,
    String? referenceNumber,
    String? notes,
    String? purchaseId,
    List<Map<String, dynamic>> allocations = const [],
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.payments,
      data: {
        'supplierId': supplierId,
        'amount': amount,
        'paymentDate': paymentDate.toIso8601String(),
        'paymentMode': paymentMode.toUpperCase(),
        if (referenceNumber != null && referenceNumber.trim().isNotEmpty)
          'referenceNumber': referenceNumber.trim(),
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        if (purchaseId != null && purchaseId.isNotEmpty) 'purchaseId': purchaseId,
        'allocations': allocations,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final payload = (data['data'] as Map<String, dynamic>?) ?? data;
    return PaymentResponseDto.fromJson(payload);
  }

  /// 5. Fetch unpaid purchases for supplier bill allocation
  Future<List<PaymentUnpaidPurchaseDto>> getUnpaidPurchases(String supplierId) async {
    final response = await _apiClient.get(
      '${ApiEndpoints.payments}/supplier/$supplierId/unpaid-purchases',
    );

    final data = response.data;
    List<dynamic> listRaw = [];
    if (data is Map<String, dynamic>) {
      final inner = data['data'];
      if (inner is List) {
        listRaw = inner;
      }
    } else if (data is List) {
      listRaw = data;
    }

    return listRaw
        .map((item) => PaymentUnpaidPurchaseDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// 6. Get payment KPI metrics
  Future<PaymentMetricsDto> getPaymentMetrics() async {
    final response = await _apiClient.get('${ApiEndpoints.payments}/metrics/summary');
    final data = response.data as Map<String, dynamic>;
    final payload = (data['data'] as Map<String, dynamic>?) ?? data;
    return PaymentMetricsDto.fromJson(payload);
  }

  /// 7. Get auto-generated next receipt reference number from backend
  Future<String> getNextReceiptRef() async {
    try {
      final response = await _apiClient.get('${ApiEndpoints.receipts}/next-ref');
      final data = response.data as Map<String, dynamic>;
      final payload = (data['data'] as Map<String, dynamic>?) ?? data;
      final refNum = payload['referenceNumber'] as String?;
      if (refNum != null && refNum.isNotEmpty) return refNum;
      return _generateFallbackRef('REC');
    } catch (_) {
      return _generateFallbackRef('REC');
    }
  }

  /// 8. Get auto-generated next payment reference code from backend
  Future<String> getNextPaymentRef() async {
    try {
      final response = await _apiClient.get('${ApiEndpoints.payments}/next-ref');
      final data = response.data as Map<String, dynamic>;
      final payload = (data['data'] as Map<String, dynamic>?) ?? data;
      final refNum = payload['referenceNumber'] as String?;
      if (refNum != null && refNum.isNotEmpty) return refNum;
      return _generateFallbackRef('PAY');
    } catch (_) {
      return _generateFallbackRef('PAY');
    }
  }

  static String _generateFallbackRef(String prefix) {
    final now = DateTime.now();
    final yyyy = now.year.toString();
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    final rand = (now.millisecondsSinceEpoch % 1000).toString().padLeft(4, '0');
    return '$prefix-$yyyy$mm$dd-$rand';
  }
}
