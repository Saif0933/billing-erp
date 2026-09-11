import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/goods_warehouse_dto.dart';

class GoodsWarehouseApiService {
  final ApiClient _apiClient;

  GoodsWarehouseApiService(this._apiClient);

  Map<String, dynamic> _unwrap(dynamic data) {
    if (data is Map<String, dynamic>) {
      final inner = data['data'];
      if (inner is Map<String, dynamic>) return inner;
      return data;
    }
    return <String, dynamic>{};
  }

  Future<WarehouseListResponseDto> listWarehouses({String? search}) async {
    final response = await _apiClient.get(
      '${ApiEndpoints.goodsWarehouse}/warehouses',
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    return WarehouseListResponseDto.fromJson(_unwrap(response.data));
  }

  Future<WarehouseLocationDto> createWarehouse({
    required String name,
    required String code,
    required String address,
    required String contact,
  }) async {
    final response = await _apiClient.post(
      '${ApiEndpoints.goodsWarehouse}/warehouses',
      data: {
        'name': name,
        'code': code,
        'address': address,
        'contact': contact,
      },
    );
    return WarehouseLocationDto.fromJson(_unwrap(response.data));
  }

  Future<WarehouseLocationDto> updateWarehouse({
    required String id,
    required String name,
    required String code,
    required String address,
    required String contact,
  }) async {
    final response = await _apiClient.patch(
      '${ApiEndpoints.goodsWarehouse}/warehouses/$id',
      data: {
        'name': name,
        'code': code,
        'address': address,
        'contact': contact,
      },
    );
    return WarehouseLocationDto.fromJson(_unwrap(response.data));
  }

  Future<WarehouseProductsResponseDto> listProducts() async {
    final response = await _apiClient.get(
      '${ApiEndpoints.goodsWarehouse}/products',
    );
    return WarehouseProductsResponseDto.fromJson(_unwrap(response.data));
  }

  Future<StockTransferHistoryResponseDto> listTransfers({
    String? search,
    int page = 1,
    int limit = 100,
  }) async {
    final response = await _apiClient.get(
      '${ApiEndpoints.goodsWarehouse}/transfers',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    return StockTransferHistoryResponseDto.fromJson(_unwrap(response.data));
  }

  Future<StockTransferLogDto> createTransfer({
    required String fromWarehouseId,
    required String toWarehouseId,
    required String referenceNumber,
    String notes = '',
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await _apiClient.post(
      '${ApiEndpoints.goodsWarehouse}/transfers',
      data: {
        'fromWarehouseId': fromWarehouseId,
        'toWarehouseId': toWarehouseId,
        'referenceNumber': referenceNumber,
        'notes': notes,
        'items': items,
      },
    );
    return StockTransferLogDto.fromJson(_unwrap(response.data));
  }
}
