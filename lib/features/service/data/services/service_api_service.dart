import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/models/billing_models.dart';
import '../models/service_dto.dart';

class ServiceApiService {
  final ApiClient _apiClient;

  ServiceApiService(this._apiClient);

  /// Fetch paginated and filtered services list
  Future<ServiceListResponse> getServices({
    String? search,
    String? unit,
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
    if (unit != null && unit != 'All' && unit.trim().isNotEmpty) {
      queryParams['unit'] = unit.trim();
    }
    if (isActive != null) {
      queryParams['isActive'] = isActive;
    }

    final response = await _apiClient.get(
      ApiEndpoints.services,
      queryParameters: queryParams,
    );

    final data = response.data as Map<String, dynamic>;
    final payload = (data['data'] as Map<String, dynamic>?) ?? data;

    return ServiceListResponse.fromJson(payload);
  }

  /// Get single service by ID
  Future<Service> getServiceById(String id) async {
    final response = await _apiClient.get(
      '${ApiEndpoints.services}/$id',
    );

    final data = response.data as Map<String, dynamic>;
    final payload = (data['data'] as Map<String, dynamic>?) ?? data;

    return ServiceDto.fromJson(payload).toDomain();
  }

  /// Create a new service
  Future<Service> createService(Service service, {String? businessId}) async {
    final dto = ServiceDto.fromDomain(service);
    final payload = dto.toJson(isUpdate: false);
    if (businessId != null && businessId.isNotEmpty) {
      payload['businessId'] = businessId;
    }

    final response = await _apiClient.post(
      ApiEndpoints.services,
      data: payload,
    );

    final data = response.data as Map<String, dynamic>;
    final serviceData = (data['data'] as Map<String, dynamic>?) ?? data;

    return ServiceDto.fromJson(serviceData).toDomain();
  }

  /// Update existing service
  Future<Service> updateService(Service service) async {
    final dto = ServiceDto.fromDomain(service);
    final payload = dto.toJson(isUpdate: true);

    final response = await _apiClient.put(
      '${ApiEndpoints.services}/${service.id}',
      data: payload,
    );

    final data = response.data as Map<String, dynamic>;
    final serviceData = (data['data'] as Map<String, dynamic>?) ?? data;

    return ServiceDto.fromJson(serviceData).toDomain();
  }

  /// Delete or soft-delete service
  Future<Map<String, dynamic>> deleteService(String id) async {
    final response = await _apiClient.delete(
      '${ApiEndpoints.services}/$id',
    );

    return response.data as Map<String, dynamic>;
  }

  /// Fetch high-level service directory metrics
  Future<ServiceMetricsDto> getServiceMetrics() async {
    final response = await _apiClient.get(
      '${ApiEndpoints.services}/metrics/summary',
    );

    final data = response.data as Map<String, dynamic>;
    final metricsData = (data['data'] as Map<String, dynamic>?) ?? data;

    return ServiceMetricsDto.fromJson(metricsData);
  }
}
