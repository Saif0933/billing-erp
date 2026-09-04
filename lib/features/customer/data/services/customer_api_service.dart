import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/models/billing_models.dart';
import '../models/customer_dto.dart';

class CustomerApiService {
  final ApiClient _apiClient;

  CustomerApiService(this._apiClient);

  /// Fetch paginated and filtered customers list
  Future<CustomerListResponse> getCustomers({
    String? search,
    String? type,
    String? customerGroup,
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
    if (type != null && type != 'All' && type.trim().isNotEmpty) {
      queryParams['type'] = type.trim();
    }
    if (customerGroup != null && customerGroup != 'All' && customerGroup.trim().isNotEmpty) {
      queryParams['customerGroup'] = customerGroup.trim();
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
      ApiEndpoints.customers,
      queryParameters: queryParams,
    );

    final data = response.data as Map<String, dynamic>;
    final payload = (data['data'] as Map<String, dynamic>?) ?? data;

    return CustomerListResponse.fromJson(payload);
  }

  /// Get single customer by ID with full transaction history and statistics
  Future<CustomerDetailDto> getCustomerById(String id) async {
    final response = await _apiClient.get(
      '${ApiEndpoints.customers}/$id',
    );

    final data = response.data as Map<String, dynamic>;
    final payload = (data['data'] as Map<String, dynamic>?) ?? data;

    return CustomerDetailDto.fromJson(payload);
  }

  /// Create a new customer
  Future<Customer> createCustomer(Customer customer, {String? businessId}) async {
    final dto = CustomerDto.fromDomain(customer);
    final payload = dto.toJson(isUpdate: false);
    if (businessId != null && businessId.isNotEmpty) {
      payload['businessId'] = businessId;
    }

    final response = await _apiClient.post(
      ApiEndpoints.customers,
      data: payload,
    );

    final data = response.data as Map<String, dynamic>;
    final customerData = (data['data'] as Map<String, dynamic>?) ?? data;

    return CustomerDto.fromJson(customerData).toDomain();
  }

  /// Update existing customer
  Future<Customer> updateCustomer(Customer customer) async {
    final dto = CustomerDto.fromDomain(customer);
    final payload = dto.toJson(isUpdate: true);

    final response = await _apiClient.put(
      '${ApiEndpoints.customers}/${customer.id}',
      data: payload,
    );

    final data = response.data as Map<String, dynamic>;
    final customerData = (data['data'] as Map<String, dynamic>?) ?? data;

    return CustomerDto.fromJson(customerData).toDomain();
  }

  /// Delete or soft-delete customer
  Future<Map<String, dynamic>> deleteCustomer(String id) async {
    final response = await _apiClient.delete(
      '${ApiEndpoints.customers}/$id',
    );

    return response.data as Map<String, dynamic>;
  }

  /// Fetch high-level customer directory metrics
  Future<CustomerMetricsDto> getCustomerMetrics() async {
    final response = await _apiClient.get(
      '${ApiEndpoints.customers}/metrics/summary',
    );

    final data = response.data as Map<String, dynamic>;
    final metricsData = (data['data'] as Map<String, dynamic>?) ?? data;

    return CustomerMetricsDto.fromJson(metricsData);
  }
}
