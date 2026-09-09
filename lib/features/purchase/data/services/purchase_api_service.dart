import '../../../../core/models/billing_models.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/purchase_dto.dart';

/// REST API service for Purchase Bill module
/// Matches backend: /api/v1/purchases (module/purchase/purchase-bill)
class PurchaseApiService {
  final ApiClient _apiClient;

  PurchaseApiService(this._apiClient);

  Map<String, dynamic> _unwrap(dynamic data) {
    if (data is Map<String, dynamic>) {
      final inner = data['data'];
      if (inner is Map<String, dynamic>) return inner;
      return data;
    }
    return <String, dynamic>{};
  }

  /// GET /purchases — list / search / filter purchase bills
  Future<PurchaseListResponse> getPurchases({
    String? search,
    String? supplierId,
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
      ApiEndpoints.purchases,
      queryParameters: queryParams,
    );

    return PurchaseListResponse.fromJson(_unwrap(response.data));
  }

  /// GET /purchases/:id
  Future<Purchase> getPurchaseById(String id) async {
    final response = await _apiClient.get('${ApiEndpoints.purchases}/$id');
    return PurchaseDto.fromJson(_unwrap(response.data)).toDomain();
  }

  /// GET /purchases/next-number
  Future<String> getNextPurchaseNumber() async {
    try {
      final response =
          await _apiClient.get('${ApiEndpoints.purchases}/next-number');
      final payload = _unwrap(response.data);
      final number = payload['purchaseNumber']?.toString();
      if (number != null && number.isNotEmpty) return number;
    } catch (_) {}

    final now = DateTime.now();
    final year = now.year;
    final month = now.month;
    final fyStart = month >= 4 ? year : year - 1;
    final fyTag =
        '${fyStart.toString().substring(2)}-${(fyStart + 1).toString().substring(2)}';
    return 'TB/$fyTag/0001';
  }

  /// GET /purchases/metrics/summary
  Future<PurchaseMetricsDto> getMetrics() async {
    final response =
        await _apiClient.get('${ApiEndpoints.purchases}/metrics/summary');
    return PurchaseMetricsDto.fromJson(_unwrap(response.data));
  }

  /// POST /purchases — create draft or confirmed bill
  Future<Purchase> createPurchase(
    Purchase purchase, {
    required PurchaseStatus saveAs,
  }) async {
    final dto = PurchaseDto.fromDomain(purchase);
    final response = await _apiClient.post(
      ApiEndpoints.purchases,
      data: dto.toCreateJson(saveAs: saveAs),
    );
    return PurchaseDto.fromJson(_unwrap(response.data)).toDomain();
  }

  /// PUT /purchases/:id
  Future<Purchase> updatePurchase(
    Purchase purchase, {
    PurchaseStatus? saveAs,
  }) async {
    final dto = PurchaseDto.fromDomain(purchase);
    final response = await _apiClient.put(
      '${ApiEndpoints.purchases}/${purchase.id}',
      data: dto.toCreateJson(saveAs: saveAs ?? purchase.status),
    );
    return PurchaseDto.fromJson(_unwrap(response.data)).toDomain();
  }

  /// POST /purchases/:id/confirm
  Future<Purchase> confirmPurchase(String id) async {
    final response =
        await _apiClient.post('${ApiEndpoints.purchases}/$id/confirm');
    return PurchaseDto.fromJson(_unwrap(response.data)).toDomain();
  }

  /// POST /purchases/:id/cancel
  Future<Purchase> cancelPurchase(String id) async {
    final response =
        await _apiClient.post('${ApiEndpoints.purchases}/$id/cancel');
    return PurchaseDto.fromJson(_unwrap(response.data)).toDomain();
  }

  /// DELETE /purchases/:id (draft only)
  Future<void> deletePurchase(String id) async {
    await _apiClient.delete('${ApiEndpoints.purchases}/$id');
  }

  /// GET /purchases/products — product listing for purchase bill UI
  Future<PurchaseProductListResponse> getPurchaseProducts({
    String? search,
    String? category,
    String? subCategory,
    String? barcode,
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
    if (subCategory != null &&
        subCategory.trim().isNotEmpty &&
        subCategory != 'All') {
      queryParams['subCategory'] = subCategory.trim();
    }
    if (barcode != null && barcode.trim().isNotEmpty) {
      queryParams['barcode'] = barcode.trim();
    }

    final response = await _apiClient.get(
      '${ApiEndpoints.purchases}/products',
      queryParameters: queryParams,
    );

    return PurchaseProductListResponse.fromJson(_unwrap(response.data));
  }

  /// GET /purchases/products/categories
  Future<List<PurchaseCategoryNode>> getProductCategories() async {
    final response =
        await _apiClient.get('${ApiEndpoints.purchases}/products/categories');
    final payload = _unwrap(response.data);
    final list = payload['categories'];
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => PurchaseCategoryNode.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// POST /purchases/products — create product from purchase bill screen
  Future<Product> createPurchaseProduct({
    required String name,
    String? itemCode,
    String? sku,
    String? barcode,
    String? hsnCode,
    String primaryUnit = 'PCS',
    double gstRate = 0,
    double purchasePrice = 0,
    double sellingPrice = 0,
    double mrp = 0,
    String? category,
    String? subCategory,
    String? brand,
    double openingStock = 0,
  }) async {
    final response = await _apiClient.post(
      '${ApiEndpoints.purchases}/products',
      data: {
        'name': name,
        if (itemCode != null && itemCode.isNotEmpty) 'itemCode': itemCode,
        if (sku != null && sku.isNotEmpty) 'sku': sku,
        if (barcode != null && barcode.isNotEmpty) 'barcode': barcode,
        if (hsnCode != null && hsnCode.isNotEmpty) 'hsnCode': hsnCode,
        'primaryUnit': primaryUnit,
        'gstRate': gstRate,
        'gstRatePercent': gstRate,
        'purchasePrice': purchasePrice,
        'sellingPrice': sellingPrice,
        'mrp': mrp,
        if (category != null && category.isNotEmpty) 'category': category,
        if (subCategory != null && subCategory.isNotEmpty)
          'subCategory': subCategory,
        if (brand != null && brand.isNotEmpty) 'brand': brand,
        'openingStock': openingStock,
      },
    );

    return PurchaseProductDto.fromJson(_unwrap(response.data)).toDomain();
  }
}
