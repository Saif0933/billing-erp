import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/outstanding_dto.dart';

class OutstandingApiService {
  final ApiClient _apiClient;

  OutstandingApiService(this._apiClient);

  /// 1. Fetch overall summary & ageing buckets
  Future<OutstandingSummaryResponseDto> getSummary() async {
    final response = await _apiClient.get('${ApiEndpoints.outstanding}/summary');
    final data = response.data as Map<String, dynamic>;
    final payload = (data['data'] as Map<String, dynamic>?) ?? data;
    return OutstandingSummaryResponseDto.fromJson(payload);
  }

  /// 2. Fetch detailed customer receivables
  Future<OutstandingListResponseDto> getReceivables({
    String status = 'ALL',
    String bucket = 'ALL',
    String? search,
    String? partyId,
    int page = 1,
    int limit = 50,
    String sortBy = 'dueDate',
    String sortOrder = 'asc',
  }) async {
    final queryParams = <String, dynamic>{
      'status': status,
      'bucket': bucket,
      'page': page,
      'limit': limit,
      'sortBy': sortBy,
      'sortOrder': sortOrder,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (partyId != null && partyId.trim().isNotEmpty) 'partyId': partyId.trim(),
    };

    final response = await _apiClient.get(
      '${ApiEndpoints.outstanding}/receivables',
      queryParameters: queryParams,
    );

    final data = response.data as Map<String, dynamic>;
    final payload = (data['data'] as Map<String, dynamic>?) ?? data;
    return OutstandingListResponseDto.fromJson(payload);
  }

  /// 3. Fetch detailed supplier payables
  Future<OutstandingListResponseDto> getPayables({
    String status = 'ALL',
    String bucket = 'ALL',
    String? search,
    String? partyId,
    int page = 1,
    int limit = 50,
    String sortBy = 'dueDate',
    String sortOrder = 'asc',
  }) async {
    final queryParams = <String, dynamic>{
      'status': status,
      'bucket': bucket,
      'page': page,
      'limit': limit,
      'sortBy': sortBy,
      'sortOrder': sortOrder,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (partyId != null && partyId.trim().isNotEmpty) 'partyId': partyId.trim(),
    };

    final response = await _apiClient.get(
      '${ApiEndpoints.outstanding}/payables',
      queryParameters: queryParams,
    );

    final data = response.data as Map<String, dynamic>;
    final payload = (data['data'] as Map<String, dynamic>?) ?? data;
    return OutstandingListResponseDto.fromJson(payload);
  }

  /// 4. Fetch party-specific outstanding overview
  Future<Map<String, dynamic>> getPartyOutstanding(String type, String partyId) async {
    final response = await _apiClient.get(
      '${ApiEndpoints.outstanding}/party/$type/$partyId',
    );
    final data = response.data as Map<String, dynamic>;
    return (data['data'] as Map<String, dynamic>?) ?? data;
  }
}
