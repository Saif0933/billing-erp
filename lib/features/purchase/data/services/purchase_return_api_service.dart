import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/purchase_return_model.dart';
import '../models/purchase_return_dto.dart';

/// REST API for Purchase Return / Debit Note module
/// Matches backend: /api/v1/purchase-returns
class PurchaseReturnApiService {
  final ApiClient _apiClient;

  PurchaseReturnApiService(this._apiClient);

  Map<String, dynamic> _unwrap(dynamic data) {
    if (data is Map<String, dynamic>) {
      final inner = data['data'];
      if (inner is Map<String, dynamic>) return inner;
      return data;
    }
    return <String, dynamic>{};
  }

  Future<PurchaseReturnListResponse> getPurchaseReturns({
    String? search,
    String? supplierId,
    String? purchaseId,
    String? status,
    String? fromDate,
    String? toDate,
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };

    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (supplierId != null && supplierId.trim().isNotEmpty) {
      queryParams['supplierId'] = supplierId.trim();
    }
    if (purchaseId != null && purchaseId.trim().isNotEmpty) {
      queryParams['purchaseId'] = purchaseId.trim();
    }
    if (status != null && status.trim().isNotEmpty && status != 'All') {
      queryParams['status'] = status.trim();
    }
    if (fromDate != null && fromDate.isNotEmpty) {
      queryParams['fromDate'] = fromDate;
    }
    if (toDate != null && toDate.isNotEmpty) {
      queryParams['toDate'] = toDate;
    }

    final response = await _apiClient.get(
      ApiEndpoints.purchaseReturns,
      queryParameters: queryParams,
    );

    return PurchaseReturnListResponse.fromJson(_unwrap(response.data));
  }

  Future<PurchaseReturn> getPurchaseReturnById(String id) async {
    final response =
        await _apiClient.get('${ApiEndpoints.purchaseReturns}/$id');
    return PurchaseReturnDto.fromJson(_unwrap(response.data)).toDomain();
  }

  Future<String> getNextDebitNoteNumber() async {
    try {
      final response =
          await _apiClient.get('${ApiEndpoints.purchaseReturns}/next-number');
      final payload = _unwrap(response.data);
      final number = payload['debitNoteNumber']?.toString() ??
          payload['noteNumber']?.toString();
      if (number != null && number.isNotEmpty) return number;
    } catch (_) {}

    final now = DateTime.now();
    final year = now.year;
    final month = now.month;
    final fyStart = month >= 4 ? year : year - 1;
    final fyTag =
        '${fyStart.toString().substring(2)}-${(fyStart + 1).toString().substring(2)}';
    return 'DN/$fyTag/001';
  }

  Future<PurchaseReturnMetricsDto> getMetrics() async {
    final response = await _apiClient
        .get('${ApiEndpoints.purchaseReturns}/metrics/summary');
    return PurchaseReturnMetricsDto.fromJson(_unwrap(response.data));
  }

  Future<List<EligiblePurchaseDto>> getEligiblePurchases({
    String? search,
    int page = 1,
    int limit = 30,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final response = await _apiClient.get(
      '${ApiEndpoints.purchaseReturns}/eligible-purchases',
      queryParameters: queryParams,
    );
    final payload = _unwrap(response.data);
    final list = payload['purchases'];
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => EligiblePurchaseDto.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<EligiblePurchaseDto> getReturnableItems(String purchaseId) async {
    final response = await _apiClient.get(
      '${ApiEndpoints.purchaseReturns}/purchases/$purchaseId/items',
    );
    return EligiblePurchaseDto.fromJson(_unwrap(response.data));
  }

  Future<PurchaseReturn> createPurchaseReturn(
    PurchaseReturn purchaseReturn, {
    required PurchaseReturnStatus saveAs,
  }) async {
    final dto = PurchaseReturnDto.fromDomain(purchaseReturn);
    final response = await _apiClient.post(
      ApiEndpoints.purchaseReturns,
      data: dto.toCreateJson(saveAs: saveAs),
    );
    return PurchaseReturnDto.fromJson(_unwrap(response.data)).toDomain();
  }

  Future<PurchaseReturn> updatePurchaseReturn(
    PurchaseReturn purchaseReturn, {
    PurchaseReturnStatus? saveAs,
  }) async {
    final dto = PurchaseReturnDto.fromDomain(purchaseReturn);
    final response = await _apiClient.put(
      '${ApiEndpoints.purchaseReturns}/${purchaseReturn.id}',
      data: dto.toCreateJson(saveAs: saveAs ?? purchaseReturn.status),
    );
    return PurchaseReturnDto.fromJson(_unwrap(response.data)).toDomain();
  }

  Future<PurchaseReturn> confirmPurchaseReturn(String id) async {
    final response =
        await _apiClient.post('${ApiEndpoints.purchaseReturns}/$id/confirm');
    return PurchaseReturnDto.fromJson(_unwrap(response.data)).toDomain();
  }

  Future<PurchaseReturn> updateStatus(
    String id,
    PurchaseReturnStatus status, {
    double? amountAdjusted,
    String? notes,
  }) async {
    final response = await _apiClient.patch(
      '${ApiEndpoints.purchaseReturns}/$id/status',
      data: {
        'status': statusToApi(status),
        if (amountAdjusted != null) 'amountAdjusted': amountAdjusted,
        if (notes != null) 'notes': notes,
      },
    );
    return PurchaseReturnDto.fromJson(_unwrap(response.data)).toDomain();
  }

  Future<PurchaseReturn> cancelPurchaseReturn(String id) async {
    final response =
        await _apiClient.post('${ApiEndpoints.purchaseReturns}/$id/cancel');
    return PurchaseReturnDto.fromJson(_unwrap(response.data)).toDomain();
  }

  Future<void> deletePurchaseReturn(String id) async {
    await _apiClient.delete('${ApiEndpoints.purchaseReturns}/$id');
  }
}
