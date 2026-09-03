import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/onboarding_models.dart';

class OnboardingRemoteDataSource {
  final ApiClient _apiClient;

  OnboardingRemoteDataSource(this._apiClient);

  /// POST /api/v1/onboarding/organization
  Future<OnboardingResponseModel> onboardOrganization(
    OnboardOrganizationRequest request,
  ) async {
    final response = await _apiClient.post(
      ApiEndpoints.onboardOrganization,
      data: request.toJson(),
    );

    final json = response.data as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>? ?? json;

    return OnboardingResponseModel.fromJson(data);
  }

  /// POST /api/v1/onboarding/validate-gstin
  Future<GstinValidationResult> validateGstin(String gstin) async {
    final response = await _apiClient.post(
      ApiEndpoints.validateGstin,
      data: {'gstin': gstin.trim().toUpperCase()},
    );

    final json = response.data as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>? ?? json;

    return GstinValidationResult.fromJson(data);
  }

  /// GET /api/v1/onboarding/check-name
  Future<NameAvailabilityResult> checkNameAvailability(String name) async {
    final response = await _apiClient.get(
      ApiEndpoints.checkNameAvailability,
      queryParameters: {'name': name.trim()},
    );

    final json = response.data as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>? ?? json;

    return NameAvailabilityResult.fromJson(data);
  }

  /// GET /api/v1/onboarding/plans
  Future<List<dynamic>> getPlans() async {
    final response = await _apiClient.get(ApiEndpoints.onboardingPlans);
    final json = response.data as Map<String, dynamic>;
    final data = json['data'] as List<dynamic>? ?? [];
    return data;
  }
}
