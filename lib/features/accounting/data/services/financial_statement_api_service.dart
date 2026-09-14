import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../models/financial_statement_dto.dart';

/// Provider for FinancialStatementApiService
final financialStatementApiServiceProvider = Provider<FinancialStatementApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return FinancialStatementApiService(apiClient);
});

class FinancialStatementApiService {
  final ApiClient _apiClient;

  FinancialStatementApiService(this._apiClient);

  /// 1. Fetch full financial statement with comparative table, summary and trend
  Future<FinancialStatementResponseDto> getFinancialStatement({
    String? reportType,
    String? dateRangeLabel,
    String? compareWith,
    String? trendPeriod,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, dynamic>{};

    if (reportType != null && reportType.trim().isNotEmpty) {
      queryParams['reportType'] = reportType.trim();
    }
    if (dateRangeLabel != null && dateRangeLabel.trim().isNotEmpty) {
      queryParams['dateRangeLabel'] = dateRangeLabel.trim();
    }
    if (compareWith != null && compareWith.trim().isNotEmpty) {
      queryParams['compareWith'] = compareWith.trim();
    }
    if (trendPeriod != null && trendPeriod.trim().isNotEmpty) {
      queryParams['trendPeriod'] = trendPeriod.trim();
    }
    if (startDate != null && startDate.trim().isNotEmpty) {
      queryParams['startDate'] = startDate.trim();
    }
    if (endDate != null && endDate.trim().isNotEmpty) {
      queryParams['endDate'] = endDate.trim();
    }

    final response = await _apiClient.get(
      ApiEndpoints.financialStatements,
      queryParameters: queryParams,
    );

    if (response.data is Map<String, dynamic>) {
      final map = response.data as Map<String, dynamic>;
      final payload = map['data'] ?? map;
      if (payload is Map<String, dynamic>) {
        return FinancialStatementResponseDto.fromJson(payload);
      }
    }

    return FinancialStatementResponseDto.empty();
  }

  /// 2. Fetch financial summary donut breakdown and KPIs
  Future<FinancialStatementSummaryDto> getFinancialSummary({
    String? reportType,
    String? dateRangeLabel,
    String? compareWith,
  }) async {
    final queryParams = <String, dynamic>{};
    if (reportType != null) queryParams['reportType'] = reportType;
    if (dateRangeLabel != null) queryParams['dateRangeLabel'] = dateRangeLabel;
    if (compareWith != null) queryParams['compareWith'] = compareWith;

    final response = await _apiClient.get(
      ApiEndpoints.financialStatementsSummary,
      queryParameters: queryParams,
    );

    if (response.data is Map<String, dynamic>) {
      final map = response.data as Map<String, dynamic>;
      final payload = map['data'] ?? map;
      if (payload is Map<String, dynamic>) {
        return FinancialStatementSummaryDto.fromJson(payload);
      }
    }

    return FinancialStatementSummaryDto.empty();
  }

  /// 3. Fetch profit trend data points
  Future<Map<String, dynamic>> getProfitTrend({String? trendPeriod}) async {
    final queryParams = <String, dynamic>{};
    if (trendPeriod != null) queryParams['trendPeriod'] = trendPeriod;

    final response = await _apiClient.get(
      ApiEndpoints.financialStatementsTrend,
      queryParameters: queryParams,
    );

    if (response.data is Map<String, dynamic>) {
      final map = response.data as Map<String, dynamic>;
      return (map['data'] ?? map) as Map<String, dynamic>;
    }
    return {};
  }

  /// 4. Fetch available report cards metadata
  Future<List<Map<String, dynamic>>> getAvailableReportTypes() async {
    final response = await _apiClient.get(ApiEndpoints.financialStatementsReportTypes);
    if (response.data is Map<String, dynamic>) {
      final map = response.data as Map<String, dynamic>;
      final list = map['data'] as List<dynamic>? ?? [];
      return list.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  /// 5. Create custom report
  Future<Map<String, dynamic>> createCustomReport(Map<String, dynamic> data) async {
    final response = await _apiClient.post(
      ApiEndpoints.financialStatementsCustomReport,
      data: data,
    );
    if (response.data is Map<String, dynamic>) {
      final map = response.data as Map<String, dynamic>;
      return (map['data'] ?? map) as Map<String, dynamic>;
    }
    return {};
  }

  /// 6. Schedule report
  Future<Map<String, dynamic>> scheduleReport(Map<String, dynamic> data) async {
    final response = await _apiClient.post(
      ApiEndpoints.financialStatementsSchedule,
      data: data,
    );
    if (response.data is Map<String, dynamic>) {
      final map = response.data as Map<String, dynamic>;
      return (map['data'] ?? map) as Map<String, dynamic>;
    }
    return {};
  }

  /// 7. Save layout preset
  Future<Map<String, dynamic>> saveLayout(Map<String, dynamic> data) async {
    final response = await _apiClient.post(
      ApiEndpoints.financialStatementsSaveLayout,
      data: data,
    );
    if (response.data is Map<String, dynamic>) {
      final map = response.data as Map<String, dynamic>;
      return (map['data'] ?? map) as Map<String, dynamic>;
    }
    return {};
  }

  /// 8. Export Statement (CSV, JSON, etc.)
  Future<Map<String, dynamic>> exportStatement({
    String format = 'csv',
    String? reportType,
    String? dateRangeLabel,
  }) async {
    final queryParams = <String, dynamic>{
      'format': format,
    };
    if (reportType != null) queryParams['reportType'] = reportType;
    if (dateRangeLabel != null) queryParams['dateRangeLabel'] = dateRangeLabel;

    final response = await _apiClient.get(
      ApiEndpoints.financialStatementsExport,
      queryParameters: queryParams,
    );

    if (response.data is Map<String, dynamic>) {
      final map = response.data as Map<String, dynamic>;
      return (map['data'] ?? map) as Map<String, dynamic>;
    }
    return {};
  }
}
