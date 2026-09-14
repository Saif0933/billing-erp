import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../models/general_ledger_dto.dart';

/// Provider for GeneralLedgerApiService
final generalLedgerApiServiceProvider = Provider<GeneralLedgerApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return GeneralLedgerApiService(apiClient);
});

class GeneralLedgerApiService {
  final ApiClient _apiClient;

  GeneralLedgerApiService(this._apiClient);

  /// 1. Fetch General Ledger with Summary KPIs, Smart Insights, Filtering, & Pagination
  Future<GeneralLedgerResponseDto> getGeneralLedger({
    String? search,
    String? account,
    String? voucherType,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    String? sortBy,
    int page = 1,
    int limit = 10,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };

    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (account != null && account.trim().isNotEmpty && account != 'All Accounts') {
      queryParams['account'] = account.trim();
    }
    if (voucherType != null && voucherType.trim().isNotEmpty && voucherType != 'All Vouchers') {
      queryParams['voucherType'] = voucherType.trim();
    }
    if (type != null && type.trim().isNotEmpty && type != 'All Types') {
      queryParams['type'] = type.trim();
    }
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String();
    }
    if (sortBy != null && sortBy.trim().isNotEmpty) {
      queryParams['sortBy'] = sortBy.trim();
    }

    final response = await _apiClient.get(
      ApiEndpoints.generalLedger,
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

    return GeneralLedgerResponseDto.fromJson(payload);
  }

  /// 2. Fetch Chart of Accounts dropdown list
  Future<List<String>> getAccounts() async {
    final response = await _apiClient.get(ApiEndpoints.generalLedgerAccounts);
    final rawData = response.data;

    List<dynamic> list = [];
    if (rawData is Map<String, dynamic>) {
      if (rawData['data'] is List) {
        list = rawData['data'] as List;
      }
    } else if (rawData is List) {
      list = rawData;
    }

    return list.map((e) => e.toString()).toList();
  }

  /// 3. Fetch Single Voucher Detail (with Double-Entry Legs)
  Future<LedgerItemDto> getVoucherDetail(String id) async {
    final response = await _apiClient.get('${ApiEndpoints.generalLedger}/$id');
    final rawData = response.data;

    Map<String, dynamic> payload = {};
    if (rawData is Map<String, dynamic>) {
      if (rawData['data'] is Map<String, dynamic>) {
        payload = rawData['data'] as Map<String, dynamic>;
      } else {
        payload = rawData;
      }
    }

    return LedgerItemDto.fromJson(payload);
  }

  /// 4. Export General Ledger
  Future<Map<String, dynamic>> exportLedger({
    String format = 'csv',
    String? search,
    String? account,
    String? voucherType,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    String? sortBy,
  }) async {
    final queryParams = <String, dynamic>{
      'format': format,
    };

    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (account != null && account.trim().isNotEmpty && account != 'All Accounts') {
      queryParams['account'] = account.trim();
    }
    if (voucherType != null && voucherType.trim().isNotEmpty && voucherType != 'All Vouchers') {
      queryParams['voucherType'] = voucherType.trim();
    }
    if (type != null && type.trim().isNotEmpty && type != 'All Types') {
      queryParams['type'] = type.trim();
    }
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String();
    }
    if (sortBy != null && sortBy.trim().isNotEmpty) {
      queryParams['sortBy'] = sortBy.trim();
    }

    final response = await _apiClient.get(
      ApiEndpoints.generalLedgerExport,
      queryParameters: queryParams,
    );

    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      if (data['data'] is Map<String, dynamic>) {
        return data['data'] as Map<String, dynamic>;
      }
      return data;
    }

    return {'csv': response.data.toString(), 'filename': 'general_ledger.csv'};
  }
}
