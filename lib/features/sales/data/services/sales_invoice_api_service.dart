import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/sales_invoice_dto.dart';

/// API Service connecting Flutter Sales features to Backend module/salesopration/sales-invoice
class SalesInvoiceApiService {
  final ApiClient _apiClient;

  SalesInvoiceApiService(this._apiClient);

  /// 1. Get next auto-incremented invoice number (e.g. TB/25-26/000123)
  Future<String> getNextInvoiceNumber() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.salesInvoiceNextNumber);
      final data = response.data as Map<String, dynamic>;
      final payload = (data['data'] as Map<String, dynamic>?) ?? data;
      return payload['invoiceNumber']?.toString() ?? 'TB/25-26/000123';
    } catch (_) {
      return 'TB/25-26/000123';
    }
  }

  /// 2. Fetch sales summary metrics
  Future<SalesInvoiceMetricsDto?> getMetrics() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.salesInvoiceMetrics);
      final data = response.data as Map<String, dynamic>;
      final payload = (data['data'] as Map<String, dynamic>?) ?? data;
      return SalesInvoiceMetricsDto.fromJson(payload);
    } catch (_) {
      return null;
    }
  }

  /// 3. Create confirmed Sales Invoice
  Future<SalesInvoiceResponse> createSalesInvoice(Map<String, dynamic> payload) async {
    final response = await _apiClient.post(
      ApiEndpoints.salesInvoices,
      data: payload,
    );

    final data = response.data as Map<String, dynamic>;
    final result = (data['data'] as Map<String, dynamic>?) ?? data;
    return SalesInvoiceResponse.fromJson(result);
  }

  /// 4. Query list of invoices
  Future<List<SalesInvoiceDto>> getSalesInvoices({
    String? search,
    String? customerId,
    String? status,
    bool? isHeld,
    int page = 1,
    int limit = 100,
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
      if (status != null && status.trim().isNotEmpty) {
        queryParams['status'] = status.trim();
      }
      if (isHeld != null) {
        queryParams['isHeld'] = isHeld;
      }

      final response = await _apiClient.get(
        ApiEndpoints.salesInvoices,
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;
      final payload = (data['data'] as Map<String, dynamic>?) ?? data;
      final invoicesRaw = payload['invoices'] as List<dynamic>? ??
          (payload['data'] is List ? payload['data'] as List<dynamic> : null) ??
          (data['invoices'] as List<dynamic>? ?? []);

      return invoicesRaw
          .whereType<Map>()
          .map((inv) {
            try {
              return SalesInvoiceDto.fromJson(Map<String, dynamic>.from(inv));
            } catch (_) {
              return null;
            }
          })
          .whereType<SalesInvoiceDto>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 5. Fetch single invoice by ID
  Future<SalesInvoiceDto> getInvoiceById(String id) async {
    final response = await _apiClient.get('${ApiEndpoints.salesInvoices}/$id');
    final data = response.data as Map<String, dynamic>;
    final payload = (data['data'] as Map<String, dynamic>?) ?? data;
    final invoiceJson = payload['invoice'] is Map
        ? Map<String, dynamic>.from(payload['invoice'] as Map)
        : payload;
    return SalesInvoiceDto.fromJson(invoiceJson);
  }

  /// 6. Fast hold / park bill
  Future<SalesInvoiceDto> holdCart(Map<String, dynamic> payload) async {
    final response = await _apiClient.post(
      ApiEndpoints.salesInvoiceHold,
      data: payload,
    );

    final data = response.data as Map<String, dynamic>;
    final result = (data['data'] as Map<String, dynamic>?) ?? data;
    return SalesInvoiceDto.fromJson(result);
  }

  /// 7. Fetch all parked / held bills
  Future<List<SalesInvoiceDto>> getHeldInvoices() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.salesInvoiceHeld);
      final dynamic raw = response.data;
      List<dynamic> listRaw = [];
      if (raw is Map<String, dynamic>) {
        final inner = raw['data'];
        if (inner is List) {
          listRaw = inner;
        } else if (inner is Map<String, dynamic> && inner['invoices'] is List) {
          listRaw = inner['invoices'] as List;
        } else if (raw['invoices'] is List) {
          listRaw = raw['invoices'] as List;
        }
      } else if (raw is List) {
        listRaw = raw;
      }

      return listRaw
          .map((inv) => SalesInvoiceDto.fromJson(inv as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 8. Resume parked bill
  Future<SalesInvoiceDto> resumeHeldInvoice(String id) async {
    final response = await _apiClient.post('${ApiEndpoints.salesInvoices}/held/$id/resume');
    final data = response.data as Map<String, dynamic>;
    final payload = (data['data'] as Map<String, dynamic>?) ?? data;
    return SalesInvoiceDto.fromJson(payload);
  }

  /// 9. Cancel sales invoice
  Future<bool> cancelInvoice(String id) async {
    final response = await _apiClient.post('${ApiEndpoints.salesInvoices}/$id/cancel');
    final data = response.data as Map<String, dynamic>;
    return data['success'] == true;
  }

  /// 10. Delete invoice
  Future<bool> deleteInvoice(String id) async {
    final response = await _apiClient.delete('${ApiEndpoints.salesInvoices}/$id');
    final data = response.data as Map<String, dynamic>;
    return data['success'] == true;
  }

  /// 11. Fetch 80mm thermal receipt payload
  Future<Map<String, dynamic>?> getThermalReceipt(String id) async {
    try {
      final response = await _apiClient.get('${ApiEndpoints.salesInvoices}/$id/receipt');
      final data = response.data as Map<String, dynamic>;
      return (data['data'] as Map<String, dynamic>?) ?? data;
    } catch (_) {
      return null;
    }
  }
}
