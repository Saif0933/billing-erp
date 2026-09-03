import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/onboarding_remote_datasource.dart';
import '../../data/repositories/onboarding_repository_impl.dart';
import '../../domain/models/onboarding_models.dart';
import '../../domain/repositories/onboarding_repository.dart';

// Providers
final onboardingRemoteDataSourceProvider = Provider<OnboardingRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OnboardingRemoteDataSource(apiClient);
});

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  final remote = ref.watch(onboardingRemoteDataSourceProvider);
  return OnboardingRepositoryImpl(remote);
});

class OnboardingState {
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final bool isGstinValidating;
  final GstinValidationResult? gstinResult;
  final String? gstinError;
  final bool isNameChecking;
  final NameAvailabilityResult? nameResult;
  final OnboardingResponseModel? onboardedData;

  const OnboardingState({
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.isGstinValidating = false,
    this.gstinResult,
    this.gstinError,
    this.isNameChecking = false,
    this.nameResult,
    this.onboardedData,
  });

  OnboardingState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    bool? isGstinValidating,
    GstinValidationResult? gstinResult,
    String? gstinError,
    bool? isNameChecking,
    NameAvailabilityResult? nameResult,
    OnboardingResponseModel? onboardedData,
    bool clearError = false,
    bool clearGstinError = false,
  }) {
    return OnboardingState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage: successMessage ?? this.successMessage,
      isGstinValidating: isGstinValidating ?? this.isGstinValidating,
      gstinResult: gstinResult ?? this.gstinResult,
      gstinError: clearGstinError ? null : (gstinError ?? this.gstinError),
      isNameChecking: isNameChecking ?? this.isNameChecking,
      nameResult: nameResult ?? this.nameResult,
      onboardedData: onboardedData ?? this.onboardedData,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final OnboardingRepository _repository;

  OnboardingNotifier(this._repository) : super(const OnboardingState());

  /// Submit the full 7-step onboarding payload to the backend
  Future<OnboardingResponseModel?> submitOnboarding(
    OnboardOrganizationRequest request,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true, successMessage: null);

    try {
      final result = await _repository.onboardOrganization(request);
      state = state.copyWith(
        isLoading: false,
        onboardedData: result,
        successMessage: 'Organization "${result.businessName}" provisioned successfully!',
      );
      return result;
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(
        isLoading: false,
        error: errorMsg,
      );
      return null;
    }
  }

  /// Validate GSTIN in real-time
  Future<GstinValidationResult?> validateGstin(String gstin) async {
    if (gstin.trim().isEmpty) return null;

    state = state.copyWith(isGstinValidating: true, clearGstinError: true);

    try {
      final result = await _repository.validateGstin(gstin);
      state = state.copyWith(
        isGstinValidating: false,
        gstinResult: result,
      );
      return result;
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(
        isGstinValidating: false,
        gstinError: errorMsg,
      );
      return null;
    }
  }

  /// Check Name & Domain Availability
  Future<NameAvailabilityResult?> checkNameAvailability(String name) async {
    if (name.trim().isEmpty) return null;

    state = state.copyWith(isNameChecking: true);

    try {
      final result = await _repository.checkNameAvailability(name);
      state = state.copyWith(
        isNameChecking: false,
        nameResult: result,
      );
      return result;
    } catch (e) {
      state = state.copyWith(isNameChecking: false);
      return null;
    }
  }

  void resetState() {
    state = const OnboardingState();
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  final repository = ref.watch(onboardingRepositoryProvider);
  return OnboardingNotifier(repository);
});
