import '../models/onboarding_models.dart';

abstract class OnboardingRepository {
  /// Submit complete 7-step Organization Onboarding
  Future<OnboardingResponseModel> onboardOrganization(
    OnboardOrganizationRequest request,
  );

  /// Validate GSTIN & decode state/entity metadata
  Future<GstinValidationResult> validateGstin(String gstin);

  /// Check business name & subdomain availability
  Future<NameAvailabilityResult> checkNameAvailability(String name);

  /// Get active SaaS plans
  Future<List<dynamic>> getPlans();
}
