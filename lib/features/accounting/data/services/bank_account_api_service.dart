import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../models/bank_account_dto.dart';

/// Provider for BankAccountApiService
final bankAccountApiServiceProvider = Provider<BankAccountApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BankAccountApiService(apiClient);
});

class BankAccountApiService {
  final ApiClient _apiClient;

  BankAccountApiService(this._apiClient);

  /// 1. Fetch Bank Accounts with KPI metrics, filters, recent transactions, and donut distribution
  Future<BankAccountsResponseDto> getBankAccounts({
    String? tab,
    String? search,
    String? category,
    String? status,
    String? sortBy,
    int page = 1,
    int limit = 10,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };

    if (tab != null &&
        tab.trim().isNotEmpty &&
        tab.toLowerCase() != 'all' &&
        tab != 'All Accounts') {
      queryParams['tab'] = tab.trim().toLowerCase();
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (category != null && category.trim().isNotEmpty && category != 'all') {
      queryParams['category'] = category.trim().toLowerCase();
    }
    if (status != null && status.trim().isNotEmpty && status.toLowerCase() != 'all') {
      queryParams['status'] = status.trim();
    }
    if (sortBy != null && sortBy.trim().isNotEmpty) {
      queryParams['sortBy'] = sortBy.trim();
    }

    final response = await _apiClient.get(
      ApiEndpoints.bankAccounts,
      queryParameters: queryParams,
    );

    if (response.data is Map<String, dynamic>) {
      final map = response.data as Map<String, dynamic>;
      final payload = map['data'] ?? map;
      if (payload is Map<String, dynamic>) {
        return BankAccountsResponseDto.fromJson(payload);
      }
    }

    return BankAccountsResponseDto.empty();
  }

  /// 2. Fetch Bank Summary KPI cards & donut breakdown
  Future<Map<String, dynamic>> getBankSummary() async {
    final response = await _apiClient.get(ApiEndpoints.bankAccountsSummary);
    if (response.data is Map<String, dynamic>) {
      final map = response.data as Map<String, dynamic>;
      return (map['data'] as Map<String, dynamic>?) ?? map;
    }
    return {};
  }

  /// 3. Fetch Recent Transactions
  Future<List<BankTransactionItemDto>> getRecentTransactions({int limit = 10}) async {
    final response = await _apiClient.get(
      ApiEndpoints.bankAccountsTransactions,
      queryParameters: {'limit': limit},
    );

    if (response.data is Map<String, dynamic>) {
      final map = response.data as Map<String, dynamic>;
      final data = map['data'] as List? ?? [];
      return data
          .whereType<Map<String, dynamic>>()
          .map((e) => BankTransactionItemDto.fromJson(e))
          .toList();
    }
    return [];
  }

  /// 4. Fetch Single Bank Account Detail
  Future<BankAccountItemDto?> getAccountDetail(String id) async {
    final response = await _apiClient.get('${ApiEndpoints.bankAccounts}/$id');
    if (response.data is Map<String, dynamic>) {
      final map = response.data as Map<String, dynamic>;
      final data = map['data'] as Map<String, dynamic>?;
      if (data != null) {
        return BankAccountItemDto.fromJson(data);
      }
    }
    return null;
  }

  /// 5. Create a new Bank Account
  Future<BankAccountItemDto> createBankAccount(CreateBankAccountDto dto) async {
    final response = await _apiClient.post(
      ApiEndpoints.bankAccounts,
      data: dto.toJson(),
    );

    if (response.data is Map<String, dynamic>) {
      final map = response.data as Map<String, dynamic>;
      final data = map['data'] as Map<String, dynamic>? ?? map;
      return BankAccountItemDto.fromJson(data);
    }
    throw Exception('Failed to create bank account');
  }

  /// 6. Update an existing Bank Account
  Future<BankAccountItemDto> updateBankAccount(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.put(
      '${ApiEndpoints.bankAccounts}/$id',
      data: data,
    );

    if (response.data is Map<String, dynamic>) {
      final map = response.data as Map<String, dynamic>;
      final resData = map['data'] as Map<String, dynamic>? ?? map;
      return BankAccountItemDto.fromJson(resData);
    }
    throw Exception('Failed to update bank account');
  }

  /// 7. Delete a Bank Account
  Future<bool> deleteBankAccount(String id) async {
    final response = await _apiClient.delete('${ApiEndpoints.bankAccounts}/$id');
    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    }
    return false;
  }

  /// 8. Toggle Active / Inactive status
  Future<BankAccountItemDto> toggleStatus(String id) async {
    final response = await _apiClient.post('${ApiEndpoints.bankAccounts}/$id/toggle-status');
    if (response.data is Map<String, dynamic>) {
      final map = response.data as Map<String, dynamic>;
      final data = map['data'] as Map<String, dynamic>? ?? map;
      return BankAccountItemDto.fromJson(data);
    }
    throw Exception('Failed to toggle bank account status');
  }

  /// 9. Reconcile Bank Account
  Future<Map<String, dynamic>> reconcileAccount(
    String id, {
    double? statementBalance,
    String? statementDate,
    List<String>? transactionIds,
  }) async {
    final response = await _apiClient.post(
      '${ApiEndpoints.bankAccounts}/$id/reconcile',
      data: {
        if (statementBalance != null) 'statementBalance': statementBalance,
        if (statementDate != null) 'statementDate': statementDate,
        if (transactionIds != null) 'transactionIds': transactionIds,
      },
    );

    if (response.data is Map<String, dynamic>) {
      final map = response.data as Map<String, dynamic>;
      return (map['data'] as Map<String, dynamic>?) ?? map;
    }
    return {};
  }

  /// 10. Export Bank Accounts to CSV
  Future<Map<String, dynamic>> exportBankAccounts({
    String? tab,
    String? search,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.bankAccountsExport,
      queryParameters: {
        'format': 'csv',
        if (tab != null) 'tab': tab,
        if (search != null) 'search': search,
      },
    );

    if (response.data is Map<String, dynamic>) {
      final map = response.data as Map<String, dynamic>;
      return (map['data'] as Map<String, dynamic>?) ?? map;
    }
    return {};
  }
}
