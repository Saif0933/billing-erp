import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../models/report_models.dart';

final reportApiServiceProvider = Provider<ReportApiService>((ref) {
  final client = ref.watch(apiClientProvider);
  return ReportApiService(client);
});

class ReportApiService {
  final ApiClient _apiClient;

  ReportApiService(this._apiClient);

  /// 1. Fetch Sales Register Log
  Future<SalesRegisterData> getSalesRegister({
    DateTime? startDate,
    DateTime? endDate,
    String? warehouseId,
    String? search,
    int page = 1,
    int limit = 100,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };

    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String();
    }
    if (warehouseId != null && warehouseId.isNotEmpty && warehouseId != 'all') {
      queryParams['warehouseId'] = warehouseId;
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final response = await _apiClient.get(
      ApiEndpoints.reportSalesRegister,
      queryParameters: queryParams,
    );

    final data = response.data as Map<String, dynamic>;
    final payload = (data['data'] as Map<String, dynamic>?) ?? data;
    return SalesRegisterData.fromJson(payload);
  }

  /// 2. Fetch Purchase Register Log
  Future<PurchaseRegisterData> getPurchaseRegister({
    DateTime? startDate,
    DateTime? endDate,
    String? warehouseId,
    String? search,
    int page = 1,
    int limit = 100,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };

    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String();
    }
    if (warehouseId != null && warehouseId.isNotEmpty && warehouseId != 'all') {
      queryParams['warehouseId'] = warehouseId;
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final response = await _apiClient.get(
      ApiEndpoints.reportPurchaseRegister,
      queryParameters: queryParams,
    );

    final data = response.data as Map<String, dynamic>;
    final payload = (data['data'] as Map<String, dynamic>?) ?? data;
    return PurchaseRegisterData.fromJson(payload);
  }

  /// 3. Fetch GST Liability Summary & Tax Slabs Breakup
  Future<GstLiabilitySummary> getGstSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, dynamic>{};

    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String();
    }

    final response = await _apiClient.get(
      ApiEndpoints.reportGstSummary,
      queryParameters: queryParams,
    );

    final data = response.data as Map<String, dynamic>;
    final payload = (data['data'] as Map<String, dynamic>?) ?? data;
    return GstLiabilitySummary.fromJson(payload);
  }

  /// 4. Fetch Stock Valuation & Inventory Asset
  Future<StockValuationData> getStockValuation({
    String? warehouseId,
    String? category,
    String? search,
    int page = 1,
    int limit = 200,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };

    if (warehouseId != null && warehouseId.isNotEmpty && warehouseId != 'all') {
      queryParams['warehouseId'] = warehouseId;
    }
    if (category != null && category.isNotEmpty && category != 'All') {
      queryParams['category'] = category;
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final response = await _apiClient.get(
      ApiEndpoints.reportStockValuation,
      queryParameters: queryParams,
    );

    final data = response.data as Map<String, dynamic>;
    final payload = (data['data'] as Map<String, dynamic>?) ?? data;
    return StockValuationData.fromJson(payload);
  }

  /// 5. Trigger Report Export (Excel, PDF, CSV)
  Future<ReportExportResult> exportReport({
    required String reportType,
    required String format,
    String? reportName,
    DateTime? startDate,
    DateTime? endDate,
    String? warehouseId,
  }) async {
    final body = <String, dynamic>{
      'reportType': reportType,
      'reportName': reportName ?? reportType,
      'format': format.toUpperCase(),
    };

    if (startDate != null) {
      body['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      body['endDate'] = endDate.toIso8601String();
    }
    if (warehouseId != null && warehouseId.isNotEmpty) {
      body['warehouseId'] = warehouseId;
    }

    final response = await _apiClient.post(
      ApiEndpoints.reportExport,
      data: body,
    );

    final data = response.data as Map<String, dynamic>;
    final payload = (data['data'] as Map<String, dynamic>?) ?? data;
    return ReportExportResult.fromJson(payload);
  }
}
