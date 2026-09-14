import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../models/journal_entries_dto.dart';

/// Provider for JournalEntriesApiService
final journalEntriesApiServiceProvider = Provider<JournalEntriesApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return JournalEntriesApiService(apiClient);
});

class JournalEntriesApiService {
  final ApiClient _apiClient;

  JournalEntriesApiService(this._apiClient);

  /// 1. Fetch Journal Entries with KPI cards, tab filters, search, and pagination
  Future<GeneralJournalSummaryResponseDto> getJournalEntries({
    String? tab,
    String? search,
    String? type,
    String? status,
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

    if (tab != null && tab.trim().isNotEmpty && tab.toLowerCase() != 'all' && tab != 'Journal List') {
      queryParams['tab'] = tab.trim().toLowerCase();
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (type != null && type.trim().isNotEmpty && type != 'All Types' && type.toLowerCase() != 'all') {
      queryParams['type'] = type.trim().toLowerCase();
    }
    if (status != null && status.trim().isNotEmpty && status != 'All Status' && status.toLowerCase() != 'all') {
      queryParams['status'] = status.trim().toLowerCase();
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
      ApiEndpoints.journalEntries,
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

    return GeneralJournalSummaryResponseDto.fromJson(payload);
  }

  /// 2. Fetch Single Journal Entry Detail with all legs
  Future<JournalEntryItemDto> getJournalDetail(String id) async {
    final response = await _apiClient.get('${ApiEndpoints.journalEntries}/$id');
    final rawData = response.data;
    Map<String, dynamic> payload = {};

    if (rawData is Map<String, dynamic>) {
      if (rawData['data'] is Map<String, dynamic>) {
        payload = rawData['data'] as Map<String, dynamic>;
      } else {
        payload = rawData;
      }
    }

    return JournalEntryItemDto.fromJson(payload);
  }

  /// 3. Fetch Accounts for Dr/Cr dropdown selection
  Future<List<AccountDropdownItemDto>> getAccounts() async {
    final response = await _apiClient.get(ApiEndpoints.journalEntriesAccounts);
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
        .map((a) => AccountDropdownItemDto.fromJson(a))
        .toList();
  }

  /// 4. Post a new Journal Entry
  Future<JournalEntryItemDto> createJournalEntry(CreateJournalEntryDto dto) async {
    final response = await _apiClient.post(
      ApiEndpoints.journalEntries,
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

    return JournalEntryItemDto.fromJson(payload);
  }

  /// 5. Update an existing Journal Entry
  Future<JournalEntryItemDto> updateJournalEntry(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.put(
      '${ApiEndpoints.journalEntries}/$id',
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

    return JournalEntryItemDto.fromJson(payload);
  }

  /// 6. Void a Journal Entry
  Future<bool> voidJournalEntry(String id) async {
    final response = await _apiClient.post('${ApiEndpoints.journalEntries}/$id/void');
    final rawData = response.data;
    if (rawData is Map<String, dynamic>) {
      return rawData['success'] == true;
    }
    return response.statusCode == 200;
  }

  /// 7. Delete a Journal Entry
  Future<bool> deleteJournalEntry(String id) async {
    final response = await _apiClient.delete('${ApiEndpoints.journalEntries}/$id');
    final rawData = response.data;
    if (rawData is Map<String, dynamic>) {
      return rawData['success'] == true;
    }
    return response.statusCode == 200 || response.statusCode == 204;
  }

  /// 8. Export Journal Day Book
  Future<Map<String, dynamic>> exportJournals({
    String format = 'csv',
    String? tab,
    String? search,
    String? type,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? sortBy,
  }) async {
    final queryParams = <String, dynamic>{
      'format': format,
    };

    if (tab != null && tab.trim().isNotEmpty && tab.toLowerCase() != 'all' && tab != 'Journal List') {
      queryParams['tab'] = tab.trim().toLowerCase();
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (type != null && type.trim().isNotEmpty && type != 'All Types') {
      queryParams['type'] = type.trim().toLowerCase();
    }
    if (status != null && status.trim().isNotEmpty && status != 'All Status') {
      queryParams['status'] = status.trim().toLowerCase();
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
      ApiEndpoints.journalEntriesExport,
      queryParameters: queryParams,
    );

    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      if (data['data'] is Map<String, dynamic>) {
        return data['data'] as Map<String, dynamic>;
      }
      return data;
    }

    return {'csv': response.data.toString(), 'filename': 'journal_entries.csv'};
  }
}
