import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/gst_models.dart';
import '../models/gst_dto.dart';

class GstApiService {
  final ApiClient _apiClient;

  GstApiService(this._apiClient);

  /// Helper to safely extract response data from backend envelope:
  /// { success: true, message: "...", data: { ... } }
  dynamic _extractData(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      if (responseData.containsKey('data')) {
        return responseData['data'];
      }
    }
    return responseData;
  }

  /// Get active business GST Profile
  /// GET /api/v1/gst/profile
  Future<GstProfile> getProfile() async {
    final response = await _apiClient.get(ApiEndpoints.gstProfile);
    final data = _extractData(response.data);
    if (data is Map<String, dynamic>) {
      return GstProfile.fromJson(data);
    }
    throw Exception('Invalid GST Profile response structure');
  }

  /// Update active business GST Profile
  /// PUT /api/v1/gst/profile
  Future<GstProfile> updateProfile(UpdateGstProfileDto dto) async {
    final response = await _apiClient.put(
      ApiEndpoints.gstProfile,
      data: dto.toJson(),
    );
    final data = _extractData(response.data);
    if (data is Map<String, dynamic>) {
      return GstProfile.fromJson(data);
    }
    throw Exception('Invalid GST Profile update response structure');
  }

  /// Get 5 KPI Metrics
  /// GET /api/v1/gst/metrics
  Future<GstKpiMetrics> getMetrics() async {
    final response = await _apiClient.get(ApiEndpoints.gstMetrics);
    final data = _extractData(response.data);
    if (data is Map<String, dynamic>) {
      return GstKpiMetrics.fromJson(data);
    }
    throw Exception('Invalid GST KPI Metrics response structure');
  }

  /// Get list of GST Returns
  /// GET /api/v1/gst/returns
  Future<List<GstReturnRecord>> getReturns({
    String? taxPeriod,
    String? returnType,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{};
    if (taxPeriod != null && taxPeriod.trim().isNotEmpty) {
      queryParams['taxPeriod'] = taxPeriod.trim();
    }
    if (returnType != null && returnType.trim().isNotEmpty) {
      queryParams['returnType'] = returnType.trim();
    }
    if (status != null && status.trim().isNotEmpty) {
      queryParams['status'] = status.trim();
    }

    final response = await _apiClient.get(
      ApiEndpoints.gstReturns,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final data = _extractData(response.data);
    if (data is List) {
      return data
          .map((item) => GstReturnRecord.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Get single return by ID
  /// GET /api/v1/gst/returns/:id
  Future<GstReturnRecord> getReturnById(String id) async {
    final response = await _apiClient.get('${ApiEndpoints.gstReturns}/$id');
    final data = _extractData(response.data);
    if (data is Map<String, dynamic>) {
      return GstReturnRecord.fromJson(data);
    }
    throw Exception('Return record not found');
  }

  /// Submit and File a GST Return
  /// POST /api/v1/gst/returns/file
  Future<FileGstReturnResponseDto> fileReturn(FileGstReturnRequestDto dto) async {
    final response = await _apiClient.post(
      ApiEndpoints.gstFileReturn,
      data: dto.toJson(),
    );
    final data = _extractData(response.data);
    if (data is Map<String, dynamic>) {
      return FileGstReturnResponseDto.fromJson(data);
    }
    return FileGstReturnResponseDto(
      message: (response.data is Map && response.data['message'] != null)
          ? response.data['message'].toString()
          : 'Return filed successfully',
      arn: '',
      filingDate: DateTime.now().toIso8601String(),
    );
  }

  /// Get Tax Liability Summary donut breakdown
  /// GET /api/v1/gst/liability-summary
  Future<GstLiabilitySummary> getLiabilitySummary() async {
    final response = await _apiClient.get(ApiEndpoints.gstLiabilitySummary);
    final data = _extractData(response.data);
    if (data is Map<String, dynamic>) {
      return GstLiabilitySummary.fromJson(data);
    }
    throw Exception('Invalid liability summary response structure');
  }

  /// Verify and lookup any 15-digit GSTIN
  /// POST /api/v1/gst/lookup
  Future<GstinSearchResult> lookupGstin(String gstin) async {
    final response = await _apiClient.post(
      ApiEndpoints.gstLookup,
      data: {'gstin': gstin.trim().toUpperCase()},
    );
    final data = _extractData(response.data);
    if (data is Map<String, dynamic>) {
      return GstinSearchResult.fromJson(data);
    }
    throw Exception('GSTIN verification failed or data unavailable');
  }

  /// Trigger sync with Government GSTN Portal
  /// POST /api/v1/gst/sync
  Future<GstPortalSyncResponseDto> syncFromPortal() async {
    final response = await _apiClient.post(ApiEndpoints.gstSync);
    final data = _extractData(response.data);
    if (data is Map<String, dynamic>) {
      return GstPortalSyncResponseDto.fromJson(data);
    }
    return GstPortalSyncResponseDto(
      success: true,
      message: (response.data is Map && response.data['message'] != null)
          ? response.data['message'].toString()
          : 'Data synchronized with GST Portal!',
      syncTimestamp: DateTime.now().toIso8601String(),
      returnsCount: 0,
    );
  }

  /// Record GST challan payment
  /// POST /api/v1/gst/payments
  Future<Map<String, dynamic>> recordPayment(RecordGstPaymentRequestDto dto) async {
    final response = await _apiClient.post(
      ApiEndpoints.gstPayments,
      data: dto.toJson(),
    );
    return (response.data as Map<String, dynamic>?) ?? {};
  }

  /// Export official GSTR-1 JSON Payload
  /// GET /api/v1/gst/export/json/gstr1/:period
  Future<Map<String, dynamic>> exportGstr1Json(String period) async {
    final cleanPeriod = Uri.encodeComponent(period);
    final response = await _apiClient.get('${ApiEndpoints.gstExportGstr1}/$cleanPeriod');
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return {};
  }
}
