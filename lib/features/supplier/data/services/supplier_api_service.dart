import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/models/billing_models.dart';
import '../models/supplier_dto.dart';

class SupplierApiService {
  final ApiClient _apiClient;

  SupplierApiService(this._apiClient);

  /// Fetch paginated and filtered suppliers list
  Future<SupplierListResponse> getSuppliers({
    String? search,
    String? supplierGroup,
    bool? isRegistered,
    bool? isActive,
    String? state,
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
    if (supplierGroup != null &&
        supplierGroup != 'All' &&
        supplierGroup.trim().isNotEmpty) {
      queryParams['supplierGroup'] = supplierGroup.trim();
    }
    if (isRegistered != null) {
      queryParams['isRegistered'] = isRegistered;
    }
    if (isActive != null) {
      queryParams['isActive'] = isActive;
    }
    if (state != null && state.trim().isNotEmpty) {
      queryParams['state'] = state.trim();
    }

    final response = await _apiClient.get(
      ApiEndpoints.suppliers,
      queryParameters: queryParams,
    );

    final data = response.data as Map<String, dynamic>;
    final payload = (data['data'] as Map<String, dynamic>?) ?? data;

    return SupplierListResponse.fromJson(payload);
  }

  /// Get single supplier by ID with full transaction history and statistics
  Future<SupplierDetailDto> getSupplierById(String id) async {
    final response = await _apiClient.get(
      '${ApiEndpoints.suppliers}/$id',
    );

    final data = response.data as Map<String, dynamic>;
    final payload = (data['data'] as Map<String, dynamic>?) ?? data;

    return SupplierDetailDto.fromJson(payload);
  }

  /// Create a new supplier
  Future<Supplier> createSupplier(Supplier supplier, {String? businessId}) async {
    final dto = SupplierDto.fromDomain(supplier);
    final payload = dto.toJson(isUpdate: false);
    if (businessId != null && businessId.isNotEmpty) {
      payload['businessId'] = businessId;
    }

    final response = await _apiClient.post(
      ApiEndpoints.suppliers,
      data: payload,
    );

    final data = response.data as Map<String, dynamic>;
    final supplierData = (data['data'] as Map<String, dynamic>?) ?? data;

    return SupplierDto.fromJson(supplierData).toDomain();
  }

  /// Update existing supplier
  Future<Supplier> updateSupplier(Supplier supplier) async {
    final dto = SupplierDto.fromDomain(supplier);
    final payload = dto.toJson(isUpdate: true);

    final response = await _apiClient.put(
      '${ApiEndpoints.suppliers}/${supplier.id}',
      data: payload,
    );

    final data = response.data as Map<String, dynamic>;
    final supplierData = (data['data'] as Map<String, dynamic>?) ?? data;

    return SupplierDto.fromJson(supplierData).toDomain();
  }

  /// Delete or soft-delete supplier
  Future<Map<String, dynamic>> deleteSupplier(String id) async {
    final response = await _apiClient.delete(
      '${ApiEndpoints.suppliers}/$id',
    );

    return response.data as Map<String, dynamic>;
  }

  /// Fetch high-level supplier directory metrics
  Future<SupplierMetricsDto> getSupplierMetrics() async {
    final response = await _apiClient.get(
      '${ApiEndpoints.suppliers}/metrics/summary',
    );

    final data = response.data as Map<String, dynamic>;
    final metricsData = (data['data'] as Map<String, dynamic>?) ?? data;

    return SupplierMetricsDto.fromJson(metricsData);
  }
}
