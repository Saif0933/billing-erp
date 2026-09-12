import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/billing_models.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../models/expense_dto.dart';

/// Provider for ExpenseApiService
final expenseApiServiceProvider = Provider<ExpenseApiService>((ref) {
  final client = ref.watch(apiClientProvider);
  return ExpenseApiService(client);
});

class ExpenseApiService {
  final ApiClient _apiClient;

  ExpenseApiService(this._apiClient);

  /// 1. Query expenses list
  Future<List<Expense>> getExpenses({
    String? search,
    String? category,
    String? paymentMode,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 100,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };

    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (category != null && category.trim().isNotEmpty && category != 'All') {
      queryParams['category'] = category.trim();
    }
    if (paymentMode != null && paymentMode.trim().isNotEmpty && paymentMode != 'All') {
      queryParams['paymentMode'] = paymentMode.trim();
    }
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String();
    }

    final response = await _apiClient.get(
      ApiEndpoints.expenses,
      queryParameters: queryParams,
    );

    final data = response.data as Map<String, dynamic>;
    final payload = (data['data'] as Map<String, dynamic>?) ?? data;
    final list = payload['expenses'] as List<dynamic>? ?? [];

    return list
        .map((item) => ExpenseDto.fromJson(item as Map<String, dynamic>).toDomain())
        .toList();
  }

  /// 2. Get Aggregated Expense Summary & Metrics
  Future<ExpenseSummaryDto> getExpenseSummary({
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
      ApiEndpoints.expenseSummary,
      queryParameters: queryParams,
    );

    final data = response.data as Map<String, dynamic>;
    final payload = (data['data'] as Map<String, dynamic>?) ?? data;

    return ExpenseSummaryDto.fromJson(payload);
  }

  /// 3. Record an Expense to backend
  Future<Expense> createExpense({
    required String category,
    required String vendor,
    required double amount,
    required double gstAmount,
    required String paymentMode,
    required DateTime date,
    String? notes,
    String? referenceNumber,
    String? attachmentUrl,
  }) async {
    final body = <String, dynamic>{
      'category': category,
      'vendorOrPayee': vendor,
      'amount': amount,
      'gstAmount': gstAmount,
      'paymentMode': paymentMode,
      'expenseDate': date.toIso8601String(),
      'notes': notes,
      'referenceNumber': referenceNumber,
      'attachmentUrl': attachmentUrl,
    };

    final response = await _apiClient.post(
      ApiEndpoints.expenses,
      data: body,
    );

    final data = response.data as Map<String, dynamic>;
    final payload = (data['data'] as Map<String, dynamic>?) ?? data;

    return ExpenseDto.fromJson(payload).toDomain();
  }

  /// 4. Delete an expense
  Future<void> deleteExpense(String id) async {
    await _apiClient.delete('${ApiEndpoints.expenses}/$id');
  }
}
