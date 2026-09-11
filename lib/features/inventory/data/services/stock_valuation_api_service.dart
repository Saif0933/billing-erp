import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/stock_valuation_dto.dart';

class StockValuationApiService {
  final ApiClient _apiClient;

  StockValuationApiService(this._apiClient);

  Map<String, dynamic> _unwrap(dynamic data) {
    if (data is Map<String, dynamic>) {
      final inner = data['data'];
      if (inner is Map<String, dynamic>) return inner;
      return data;
    }
    return <String, dynamic>{};
  }

  Future<StockValuationSummaryDto> getSummary({String? warehouseId}) async {
    final response = await _apiClient.get(
      '${ApiEndpoints.stockValuation}/summary',
      queryParameters: {
        if (warehouseId != null && warehouseId.trim().isNotEmpty)
          'warehouseId': warehouseId.trim(),
      },
    );
    return StockValuationSummaryDto.fromJson(_unwrap(response.data));
  }

  Future<StockValuationItemsResponseDto> getItems({
    String? search,
    String? warehouseId,
    bool lowStockOnly = false,
    int page = 1,
    int limit = 100,
    String sortBy = 'name',
    String sortOrder = 'asc',
  }) async {
    final response = await _apiClient.get(
      '${ApiEndpoints.stockValuation}/items',
      queryParameters: {
        'page': page,
        'limit': limit,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
        'lowStockOnly': lowStockOnly,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (warehouseId != null && warehouseId.trim().isNotEmpty)
          'warehouseId': warehouseId.trim(),
      },
    );
    return StockValuationItemsResponseDto.fromJson(_unwrap(response.data));
  }

  Future<StockMovementsResponseDto> getMovements({
    String? search,
    String? warehouseId,
    String? productId,
    String? movementType,
    int page = 1,
    int limit = 100,
    String sortBy = 'movementDate',
    String sortOrder = 'desc',
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.stockMovements,
      queryParameters: {
        'page': page,
        'limit': limit,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (warehouseId != null && warehouseId.trim().isNotEmpty)
          'warehouseId': warehouseId.trim(),
        if (productId != null && productId.trim().isNotEmpty)
          'productId': productId.trim(),
        if (movementType != null && movementType.trim().isNotEmpty)
          'movementType': movementType.trim(),
      },
    );
    return StockMovementsResponseDto.fromJson(_unwrap(response.data));
  }

  Future<StockLedgerEntryDto> createAdjustment({
    required String productId,
    required double quantity,
    required String reason,
    String? warehouseId,
    double? unitCost,
  }) async {
    final response = await _apiClient.post(
      '${ApiEndpoints.stockValuation}/adjustment',
      data: {
        'productId': productId,
        'quantity': quantity,
        'reason': reason,
        if (warehouseId != null && warehouseId.trim().isNotEmpty)
          'warehouseId': warehouseId.trim(),
        if (unitCost != null) 'unitCost': unitCost,
      },
    );
    return StockLedgerEntryDto.fromJson(_unwrap(response.data));
  }
}

