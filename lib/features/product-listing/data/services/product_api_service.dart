import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/product_dto.dart';

/// REST API Service for interacting with backend Products & Catalogue endpoints
class ProductApiService {
  final ApiClient _apiClient;

  ProductApiService(this._apiClient);

  /// Fetch paginated and filtered list of products
  Future<ProductListResponse> getProducts({
    String? search,
    String? category,
    bool? lowStock,
    String? barcode,
    bool? isActive = true,
    int page = 1,
    int limit = 50,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      'sortBy': sortBy,
      'sortOrder': sortOrder,
    };

    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    if (category != null && category.trim().isNotEmpty && category != 'All') {
      queryParams['category'] = category.trim();
    }

    if (lowStock == true) {
      queryParams['lowStock'] = 'true';
    }

    if (barcode != null && barcode.trim().isNotEmpty) {
      queryParams['barcode'] = barcode.trim();
    }

    if (isActive != null) {
      queryParams['isActive'] = isActive.toString();
    }

    final response = await _apiClient.get(
      ApiEndpoints.products,
      queryParameters: queryParams,
    );

    final data = response.data;
    if (data['success'] == true && data['data'] != null) {
      return ProductListResponse.fromJson(data['data'] as Map<String, dynamic>);
    }

    throw Exception(data['message'] ?? 'Failed to retrieve products');
  }

  /// High-speed Barcode/SKU scanner lookup for POS Billing
  Future<ProductDto> findProductByBarcode(String barcode) async {
    final clean = barcode.trim();
    final response = await _apiClient.get(
      '${ApiEndpoints.products}/barcode/$clean',
    );

    final data = response.data;
    if (data['success'] == true && data['data'] != null) {
      return ProductDto.fromJson(data['data'] as Map<String, dynamic>);
    }

    throw Exception(data['message'] ?? 'Product not found for barcode: $barcode');
  }

  /// Get single product details by ID
  Future<ProductDto> getProductById(String id) async {
    final response = await _apiClient.get('${ApiEndpoints.products}/$id');

    final data = response.data;
    if (data['success'] == true && data['data'] != null) {
      return ProductDto.fromJson(data['data'] as Map<String, dynamic>);
    }

    throw Exception(data['message'] ?? 'Failed to fetch product details');
  }

  /// Create a new product
  Future<ProductDto> createProduct(ProductDto product) async {
    final response = await _apiClient.post(
      ApiEndpoints.products,
      data: product.toJson(isUpdate: false),
    );

    final data = response.data;
    if (data['success'] == true && data['data'] != null) {
      return ProductDto.fromJson(data['data'] as Map<String, dynamic>);
    }

    throw Exception(data['message'] ?? 'Failed to create product');
  }

  /// Update an existing product
  Future<ProductDto> updateProduct(ProductDto product) async {
    final response = await _apiClient.put(
      '${ApiEndpoints.products}/${product.id}',
      data: product.toJson(isUpdate: true),
    );

    final data = response.data;
    if (data['success'] == true && data['data'] != null) {
      return ProductDto.fromJson(data['data'] as Map<String, dynamic>);
    }

    throw Exception(data['message'] ?? 'Failed to update product');
  }

  /// Delete a product (smart soft/hard delete on backend)
  Future<void> deleteProduct(String id) async {
    final response = await _apiClient.delete('${ApiEndpoints.products}/$id');

    final data = response.data;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to delete product');
    }
  }

  /// Get directory metrics summary
  Future<ProductMetricsDto> getProductMetrics() async {
    final response = await _apiClient.get(
      '${ApiEndpoints.products}/metrics/summary',
    );

    final data = response.data;
    if (data['success'] == true && data['data'] != null) {
      return ProductMetricsDto.fromJson(data['data'] as Map<String, dynamic>);
    }

    throw Exception(data['message'] ?? 'Failed to retrieve product metrics');
  }
}
