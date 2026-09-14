import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../models/chart_of_accounts_dto.dart';

/// Provider for ChartOfAccountsApiService
final chartOfAccountsApiServiceProvider = Provider<ChartOfAccountsApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ChartOfAccountsApiService(apiClient);
});

class ChartOfAccountsApiService {
  final ApiClient _apiClient;

  ChartOfAccountsApiService(this._apiClient);

  /// 1. Fetch Chart of Accounts tree structure & 4 KPI metrics
  Future<CoaSummaryDataDto> getChartOfAccounts({
    String? category,
    String? search,
    bool showZeroBalances = true,
    String? sortBy,
  }) async {
    final queryParams = <String, dynamic>{
      'showZeroBalances': showZeroBalances,
    };

    if (category != null && category.trim().isNotEmpty && category.toLowerCase() != 'all') {
      queryParams['category'] = category.trim().toLowerCase();
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (sortBy != null && sortBy.trim().isNotEmpty) {
      queryParams['sortBy'] = sortBy.trim();
    }

    final response = await _apiClient.get(
      ApiEndpoints.chartOfAccounts,
      queryParameters: queryParams,
    );

    final rawData = response.data;
    Map<String, dynamic> payload = {};

    if (rawData is Map<String, dynamic>) {
      if (rawData['data'] is Map<String, dynamic>) {
        payload = rawData['data'] as Map<String, dynamic>;
      } else {
        payload = rawData;
      }
    }

    return CoaSummaryDataDto.fromJson(payload);
  }

  /// 2. Fetch Account Groups for parent group dropdown selection
  Future<List<Map<String, dynamic>>> getAccountGroups() async {
    final response = await _apiClient.get(ApiEndpoints.chartOfAccountsGroups);
    final rawData = response.data;

    List<dynamic> list = [];
    if (rawData is Map<String, dynamic>) {
      if (rawData['data'] is List) {
        list = rawData['data'] as List;
      }
    } else if (rawData is List) {
      list = rawData;
    }

    return list.whereType<Map<String, dynamic>>().toList();
  }

  /// 3. Fetch flat account list for search/autocomplete
  Future<List<CoaAccountItemDto>> getFlatAccounts({
    String? type,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{};
    if (type != null && type.trim().isNotEmpty && type.toLowerCase() != 'all') {
      queryParams['type'] = type.trim().toLowerCase();
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final response = await _apiClient.get(
      ApiEndpoints.chartOfAccountsFlat,
      queryParameters: queryParams,
    );

    final rawData = response.data;
    List<dynamic> list = [];
    if (rawData is Map<String, dynamic>) {
      if (rawData['data'] is List) {
        list = rawData['data'] as List;
      }
    } else if (rawData is List) {
      list = rawData;
    }

    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => CoaAccountItemDto.fromJson(e))
        .toList();
  }

  /// 4. Create a new account or account group
  Future<CoaAccountItemDto> createAccount(CreateCoaAccountDto dto) async {
    final response = await _apiClient.post(
      ApiEndpoints.chartOfAccounts,
      data: dto.toJson(),
    );

    final rawData = response.data;
    Map<String, dynamic> payload = {};

    if (rawData is Map<String, dynamic>) {
      if (rawData['data'] is Map<String, dynamic>) {
        payload = rawData['data'] as Map<String, dynamic>;
      } else {
        payload = rawData;
      }
    }

    return CoaAccountItemDto.fromJson(payload);
  }

  /// 5. Update an existing account or group
  Future<CoaAccountItemDto> updateAccount(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.put(
      '${ApiEndpoints.chartOfAccounts}/$id',
      data: data,
    );

    final rawData = response.data;
    Map<String, dynamic> payload = {};

    if (rawData is Map<String, dynamic>) {
      if (rawData['data'] is Map<String, dynamic>) {
        payload = rawData['data'] as Map<String, dynamic>;
      } else {
        payload = rawData;
      }
    }

    return CoaAccountItemDto.fromJson(payload);
  }

  /// 6. Delete an account or group
  Future<bool> deleteAccount(String id) async {
    final response = await _apiClient.delete('${ApiEndpoints.chartOfAccounts}/$id');
    final rawData = response.data;
    if (rawData is Map<String, dynamic>) {
      return rawData['success'] == true;
    }
    return response.statusCode == 200 || response.statusCode == 204;
  }
}
