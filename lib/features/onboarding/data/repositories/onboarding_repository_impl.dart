import '../../domain/models/onboarding_models.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../datasources/onboarding_remote_datasource.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  final OnboardingRemoteDataSource _remoteDataSource;

  OnboardingRepositoryImpl(this._remoteDataSource);

  @override
  Future<OnboardingResponseModel> onboardOrganization(
    OnboardOrganizationRequest request,
  ) {
    return _remoteDataSource.onboardOrganization(request);
  }

  @override
  Future<GstinValidationResult> validateGstin(String gstin) {
    return _remoteDataSource.validateGstin(gstin);
  }

  @override
  Future<NameAvailabilityResult> checkNameAvailability(String name) {
    return _remoteDataSource.checkNameAvailability(name);
  }

  @override
  Future<List<dynamic>> getPlans() {
    return _remoteDataSource.getPlans();
  }
}
