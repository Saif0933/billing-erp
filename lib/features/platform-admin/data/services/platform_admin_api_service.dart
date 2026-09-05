import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/platform_admin_models.dart';
import '../models/platform_admin_dto.dart';

class PlatformAdminApiService {
  final ApiClient _apiClient;

  PlatformAdminApiService(this._apiClient);

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

  /// Get paginated and filtered tenant organizations
  /// GET /api/v1/platform-admin/organizations
  Future<OrganizationListResponseDto> getOrganizations({
    String? search,
    String? status,
    String? plan,
    int limit = 50,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };

    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (status != null && status != 'All' && status.trim().isNotEmpty) {
      queryParams['status'] = status.trim();
    }
    if (plan != null && plan != 'All' && plan.trim().isNotEmpty) {
      queryParams['plan'] = plan.trim();
    }

    final response = await _apiClient.get(
      ApiEndpoints.platformAdminOrganizations,
      queryParameters: queryParams,
    );

    final data = _extractData(response.data);
    if (data is Map<String, dynamic>) {
      return OrganizationListResponseDto.fromJson(data);
    }
    throw Exception('Invalid Platform Admin Organizations response envelope');
  }

  /// Get platform organization KPIs
  /// GET /api/v1/platform-admin/organizations/kpis
  Future<PlatformKPIs> getKPIs() async {
    final response = await _apiClient.get(
      ApiEndpoints.platformAdminKPIs,
    );

    final data = _extractData(response.data);
    if (data is Map<String, dynamic>) {
      return PlatformKPIsDto.fromJson(data).toDomain();
    }
    throw Exception('Invalid Platform KPIs response structure');
  }

  /// Get single tenant organization by ID
  /// GET /api/v1/platform-admin/organizations/:id
  Future<OrganizationTenant> getOrganizationById(String id) async {
    final response = await _apiClient.get(
      '${ApiEndpoints.platformAdminOrganizations}/$id',
    );

    final data = _extractData(response.data);
    if (data is Map<String, dynamic>) {
      return OrganizationTenantDto.fromJson(data).toDomain();
    }
    throw Exception('Invalid Organization response structure');
  }

  /// Provision a new organization tenant
  /// POST /api/v1/platform-admin/organizations
  Future<OrganizationTenant> createOrganization(
    OrganizationTenant tenant, {
    String? password,
  }) async {
    final dto = OrganizationTenantDto.fromDomain(tenant);
    final payload = dto.toJson(isUpdate: false, password: password);

    final response = await _apiClient.post(
      ApiEndpoints.platformAdminOrganizations,
      data: payload,
    );

    final data = _extractData(response.data);
    if (data is Map<String, dynamic>) {
      return OrganizationTenantDto.fromJson(data).toDomain();
    }
    throw Exception('Invalid Organization creation response structure');
  }

  /// Update an existing organization tenant
  /// PUT /api/v1/platform-admin/organizations/:id
  Future<OrganizationTenant> updateOrganization(OrganizationTenant tenant) async {
    final dto = OrganizationTenantDto.fromDomain(tenant);
    final payload = dto.toJson(isUpdate: true);

    final response = await _apiClient.put(
      '${ApiEndpoints.platformAdminOrganizations}/${tenant.id}',
      data: payload,
    );

    final data = _extractData(response.data);
    if (data is Map<String, dynamic>) {
      return OrganizationTenantDto.fromJson(data).toDomain();
    }
    throw Exception('Invalid Organization update response structure');
  }

  /// Toggle tenant status (Active, Trial, Suspended)
  /// PATCH /api/v1/platform-admin/organizations/:id/status
  Future<OrganizationTenant> toggleStatus(String id, TenantStatus status) async {
    final statusStr = OrganizationTenantDto.formatStatus(status);

    final response = await _apiClient.patch(
      '${ApiEndpoints.platformAdminOrganizations}/$id/status',
      data: {'status': statusStr},
    );

    final data = _extractData(response.data);
    if (data is Map<String, dynamic>) {
      return OrganizationTenantDto.fromJson(data).toDomain();
    }
    throw Exception('Invalid Organization status update response structure');
  }

  /// Suspend / Remove tenant organization
  /// DELETE /api/v1/platform-admin/organizations/:id
  Future<Map<String, dynamic>> deleteOrganization(String id) async {
    final response = await _apiClient.delete(
      '${ApiEndpoints.platformAdminOrganizations}/$id',
    );

    final data = _extractData(response.data);
    if (data is Map<String, dynamic>) {
      return data;
    }
    return {'success': true};
  }

  /// Generate impersonation session token for organization owner
  /// POST /api/v1/platform-admin/organizations/:id/impersonate
  Future<Map<String, dynamic>> impersonateTenant(String id) async {
    final response = await _apiClient.post(
      '${ApiEndpoints.platformAdminOrganizations}/$id/impersonate',
    );

    final data = _extractData(response.data);
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw Exception('Invalid Impersonation response structure');
  }

  /// Get all active SaaS subscription plans
  /// GET /api/v1/platform-admin/plans
  Future<List<PlatformPlan>> getPlans() async {
    final response = await _apiClient.get(ApiEndpoints.platformAdminPlans);
    final data = _extractData(response.data);

    if (data is List) {
      return data
          .map((item) =>
              PlatformPlanDto.fromJson(item as Map<String, dynamic>).toDomain())
          .toList();
    }
    return [];
  }

  /// Create a new SaaS subscription plan
  /// POST /api/v1/platform-admin/plans
  Future<PlatformPlan> createPlan(PlatformPlan plan) async {
    final dto = PlatformPlanDto.fromDomain(plan);
    final response = await _apiClient.post(
      ApiEndpoints.platformAdminPlans,
      data: dto.toJson(isUpdate: false),
    );

    final data = _extractData(response.data);
    if (data is Map<String, dynamic>) {
      return PlatformPlanDto.fromJson(data).toDomain();
    }
    throw Exception('Invalid Plan creation response structure');
  }

  /// Update an existing SaaS subscription plan
  /// PUT /api/v1/platform-admin/plans/:id
  Future<PlatformPlan> updatePlan(PlatformPlan plan) async {
    final dto = PlatformPlanDto.fromDomain(plan);
    final response = await _apiClient.put(
      '${ApiEndpoints.platformAdminPlans}/${plan.id}',
      data: dto.toJson(isUpdate: true),
    );

    final data = _extractData(response.data);
    if (data is Map<String, dynamic>) {
      return PlatformPlanDto.fromJson(data).toDomain();
    }
    throw Exception('Invalid Plan update response structure');
  }

  /// Delete a SaaS subscription plan
  /// DELETE /api/v1/platform-admin/plans/:id
  Future<Map<String, dynamic>> deletePlan(String id) async {
    final response = await _apiClient.delete(
      '${ApiEndpoints.platformAdminPlans}/$id',
    );

    final data = _extractData(response.data);
    if (data is Map<String, dynamic>) {
      return data;
    }
    return {'success': true};
  }
}
