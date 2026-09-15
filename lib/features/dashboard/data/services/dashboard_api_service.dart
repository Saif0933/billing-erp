import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../models/dashboard_models.dart';

/// Provider for DashboardApiService
final dashboardApiServiceProvider = Provider<DashboardApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DashboardApiService(apiClient);
});

/// API Service connecting Flutter Dashboard feature to Backend module/dashboard
class DashboardApiService {
  final ApiClient _apiClient;

  DashboardApiService(this._apiClient);

  /// 1. Unified Dashboard Overview (Parallel aggregated with Redis caching)
  Future<DashboardOverviewData> getOverview({
    String period = 'this_year',
    bool refresh = false,
    String? businessId,
  }) async {
    final queryParams = <String, dynamic>{
      'period': period,
      if (refresh) 'refresh': 'true',
      if (businessId != null && businessId.isNotEmpty) 'businessId': businessId,
    };

    final response = await _apiClient.get(
      ApiEndpoints.dashboardOverview,
      queryParameters: queryParams,
    );

    final data = response.data as Map<String, dynamic>;
    final payload = (data['data'] as Map<String, dynamic>?) ?? data;
    return DashboardOverviewData.fromJson(payload);
  }

  /// 2. KPI Financial Metric Cards
  Future<DashboardKpiMetrics> getMetrics({String? businessId}) async {
    final queryParams = <String, dynamic>{
      if (businessId != null && businessId.isNotEmpty) 'businessId': businessId,
    };

    final response = await _apiClient.get(
      ApiEndpoints.dashboardMetrics,
      queryParameters: queryParams,
    );

    final data = response.data as Map<String, dynamic>;
    final payload = (data['data'] as Map<String, dynamic>?) ?? data;
    return DashboardKpiMetrics.fromJson(payload);
  }

  /// 3. Sales & Purchase Trend
  Future<DashboardTrendData> getTrends({
    String period = 'this_year',
    String? businessId,
  }) async {
    final queryParams = <String, dynamic>{
      'period': period,
      if (businessId != null && businessId.isNotEmpty) 'businessId': businessId,
    };

    final response = await _apiClient.get(
      ApiEndpoints.dashboardTrends,
      queryParameters: queryParams,
    );

    final data = response.data as Map<String, dynamic>;
    final payload = (data['data'] as Map<String, dynamic>?) ?? data;
    return DashboardTrendData.fromJson(payload);
  }

  /// 4. Cash & Bank Accounts Summary
  Future<DashboardCashBankSummary> getCashAndBank({String? businessId}) async {
    final queryParams = <String, dynamic>{
      if (businessId != null && businessId.isNotEmpty) 'businessId': businessId,
    };

    final response = await _apiClient.get(
      ApiEndpoints.dashboardCashBank,
      queryParameters: queryParams,
    );

    final data = response.data as Map<String, dynamic>;
    final payload = (data['data'] as Map<String, dynamic>?) ?? data;
    return DashboardCashBankSummary.fromJson(payload);
  }

  /// 5. Inventory Summary Breakdown
  Future<DashboardInventorySummary> getInventorySummary({
    String? businessId,
  }) async {
    final queryParams = <String, dynamic>{
      if (businessId != null && businessId.isNotEmpty) 'businessId': businessId,
    };

    final response = await _apiClient.get(
      ApiEndpoints.dashboardInventorySummary,
      queryParameters: queryParams,
    );

    final data = response.data as Map<String, dynamic>;
    final payload = (data['data'] as Map<String, dynamic>?) ?? data;
    return DashboardInventorySummary.fromJson(payload);
  }

  /// 6. Recent Sales Invoices
  Future<List<DashboardRecentSalesItem>> getRecentSales({
    int limit = 5,
    String? businessId,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      if (businessId != null && businessId.isNotEmpty) 'businessId': businessId,
    };

    final response = await _apiClient.get(
      ApiEndpoints.dashboardRecentSales,
      queryParameters: queryParams,
    );

    final data = response.data as Map<String, dynamic>;
    final payload = (data['data'] as Map<String, dynamic>?) ?? data;
    final list = payload['sales'] as List<dynamic>? ?? [];

    return list
        .map(
          (item) => DashboardRecentSalesItem.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  /// 7. Recent Purchase Orders
  Future<List<DashboardRecentPurchasesItem>> getRecentPurchases({
    int limit = 5,
    String? businessId,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      if (businessId != null && businessId.isNotEmpty) 'businessId': businessId,
    };

    final response = await _apiClient.get(
      ApiEndpoints.dashboardRecentPurchases,
      queryParameters: queryParams,
    );

    final data = response.data as Map<String, dynamic>;
    final payload = (data['data'] as Map<String, dynamic>?) ?? data;
    final list = payload['purchases'] as List<dynamic>? ?? [];

    return list
        .map(
          (item) => DashboardRecentPurchasesItem.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  /// 8. Upcoming Smart Reminders
  Future<List<DashboardReminderItem>> getReminders({
    String? businessId,
  }) async {
    final queryParams = <String, dynamic>{
      if (businessId != null && businessId.isNotEmpty) 'businessId': businessId,
    };

    final response = await _apiClient.get(
      ApiEndpoints.dashboardReminders,
      queryParameters: queryParams,
    );

    final data = response.data as Map<String, dynamic>;
    final payload = (data['data'] as Map<String, dynamic>?) ?? data;
    final list = payload['reminders'] as List<dynamic>? ?? [];

    return list
        .map(
          (item) => DashboardReminderItem.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}
