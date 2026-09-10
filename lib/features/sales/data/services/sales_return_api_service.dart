import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/sales_return_dto.dart';

/// API Service connecting Flutter Sales Return features to Backend module/salesopration/sales-return
class SalesReturnApiService {
  final ApiClient _apiClient;

  SalesReturnApiService(this._apiClient);

  /// 1. Get next auto-formatted return / credit note number (e.g. CN/25-26/0001)
  Future<String> getNextReturnNumber() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.salesReturnNextNumber);
      final data = response.data as Map<String, dynamic>;
      final payload = (data['data'] as Map<String, dynamic>?) ?? data;
      return payload['returnNumber']?.toString() ?? 'CN/25-26/0001';
    } catch (_) {
      return 'CN/25-26/0001';
    }
  }

  /// 2. Fetch sales return summary metrics
  Future<SalesReturnSummaryMetricsDto?> getMetrics() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.salesReturnMetrics);
      final data = response.data as Map<String, dynamic>;
      final payload = (data['data'] as Map<String, dynamic>?) ?? data;
      return SalesReturnSummaryMetricsDto.fromJson(payload);
    } catch (_) {
      return null;
    }
  }

  /// 3. Create Sales Return (Draft or Confirmed)
  Future<SalesReturnDto> createSalesReturn(Map<String, dynamic> payload) async {
    final response = await _apiClient.post(
      ApiEndpoints.salesReturns,
      data: payload,
    );

    final data = response.data as Map<String, dynamic>;
    final result = (data['data'] as Map<String, dynamic>?) ?? data;
    return SalesReturnDto.fromJson(result);
  }

  /// 4. Query list of sales returns
  Future<List<SalesReturnDto>> getSalesReturns({
    String? search,
    String? customerId,
    String? invoiceId,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (customerId != null && customerId.trim().isNotEmpty) {
        queryParams['customerId'] = customerId.trim();
      }
      if (invoiceId != null && invoiceId.trim().isNotEmpty) {
        queryParams['invoiceId'] = invoiceId.trim();
      }
      if (status != null && status.trim().isNotEmpty) {
        queryParams['status'] = status.trim();
      }

      final response = await _apiClient.get(
        ApiEndpoints.salesReturns,
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;
      final payload = (data['data'] as Map<String, dynamic>?) ?? data;
      final returnsRaw = payload['returns'] as List<dynamic>? ?? [];

      return returnsRaw
          .map((ret) => SalesReturnDto.fromJson(ret as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 5. Fetch single return by ID
  Future<SalesReturnDto> getReturnById(String id) async {
    final response = await _apiClient.get('${ApiEndpoints.salesReturns}/$id');
    final data = response.data as Map<String, dynamic>;
    final payload = (data['data'] as Map<String, dynamic>?) ?? data;
    return SalesReturnDto.fromJson(payload);
  }

  /// 6. Confirm sales return (restocks inventory, issues credit note & updates ledger)
  Future<SalesReturnDto> confirmSalesReturn(String id) async {
    final response = await _apiClient.post('${ApiEndpoints.salesReturns}/$id/confirm');
    final data = response.data as Map<String, dynamic>;
    final payload = (data['data'] as Map<String, dynamic>?) ?? data;
    return SalesReturnDto.fromJson(payload);
  }

  /// 7. Cancel sales return (reverses inventory restock & ledger balance)
  Future<SalesReturnDto> cancelSalesReturn(String id) async {
    final response = await _apiClient.post('${ApiEndpoints.salesReturns}/$id/cancel');
    final data = response.data as Map<String, dynamic>;
    final payload = (data['data'] as Map<String, dynamic>?) ?? data;
    return SalesReturnDto.fromJson(payload);
  }

  /// 8. Delete sales return (drafts only)
  Future<bool> deleteSalesReturn(String id) async {
    final response = await _apiClient.delete('${ApiEndpoints.salesReturns}/$id');
    final data = response.data as Map<String, dynamic>;
    return data['success'] == true;
  }

  /// 9. Fetch 80mm thermal credit note receipt payload
  Future<Map<String, dynamic>?> getThermalReceipt(String id) async {
    try {
      final response = await _apiClient.get('${ApiEndpoints.salesReturns}/$id/receipt');
      final data = response.data as Map<String, dynamic>;
      return (data['data'] as Map<String, dynamic>?) ?? data;
    } catch (_) {
      return null;
    }
  }
}
