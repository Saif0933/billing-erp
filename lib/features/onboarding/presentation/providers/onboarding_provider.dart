import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class OnboardingNotifier extends StateNotifier<bool> {
  final StorageService _storage;

  OnboardingNotifier(this._storage) : super(false) {
    _loadState();
  }

  void _loadState() {
    state = _storage.getOnboardingCompleted();
  }

  Future<void> completeOnboarding() async {
    await _storage.setOnboardingCompleted(true);
    state = true;
  }

  Future<void> resetOnboarding() async {
    await _storage.setOnboardingCompleted(false);
    state = false;
  }
}

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return OnboardingNotifier(storage);
});
