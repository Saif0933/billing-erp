import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/storage/storage_service.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_api_service.dart';

final sharedPreferencesProvider =
    Provider<SharedPreferences>((ref) => throw UnimplementedError());

final storageServiceProvider = Provider<StorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return StorageService(prefs);
});

final secureStorageProvider =
    Provider<FlutterSecureStorage>((ref) => const FlutterSecureStorage());

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  final secure = ref.watch(secureStorageProvider);
  return SecureStorageService(secure);
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final secure = ref.watch(secureStorageServiceProvider);
  final storage = ref.watch(storageServiceProvider);
  return ApiClient(secure, storage);
});

final authApiServiceProvider = Provider<AuthApiService>((ref) {
  final client = ref.watch(apiClientProvider);
  return AuthApiService(client);
});

enum AuthStatus { splash, unauthenticated, authenticated }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;

  const AuthState({
    required this.status,
    this.user,
    this.error,
  });

  const AuthState.splash() : this(status: AuthStatus.splash);
  const AuthState.unauthenticated({String? error})
      : this(status: AuthStatus.unauthenticated, error: error);
  const AuthState.authenticated(UserModel user)
      : this(status: AuthStatus.authenticated, user: user);

  bool get isPlatformAdmin => user?.isPlatformAdmin ?? false;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthApiService _apiService;
  final SecureStorageService _secureStorage;
  final StorageService _storage;

  AuthNotifier(this._apiService, this._secureStorage, this._storage)
      : super(const AuthState.splash()) {
    initialize();
  }

  Future<void> initialize() async {
    try {
      final token = await _secureStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        try {
          final user = await _apiService.getMe();
          state = AuthState.authenticated(user);
          return;
        } catch (_) {
          // Fallback to local cache if network/token verification fails temporarily
          final email = _storage.getCachedUserEmail();
          if (email != null && email.isNotEmpty) {
            state = AuthState.authenticated(
              UserModel(
                id: 'usr_cached',
                fullName: email.split('@').first,
                email: email,
                isPlatformAdmin: email.contains('admin'),
              ),
            );
            return;
          }
        }
      }
      state = const AuthState.unauthenticated();
    } catch (_) {
      state = const AuthState.unauthenticated();
    }
  }

  Future<bool> login(
    String email,
    String password, {
    bool isPlatformAdminPortal = false,
  }) async {
    try {
      final response = await _apiService.login(
        email: email.trim(),
        password: password,
        isPlatformAdminPortal: isPlatformAdminPortal,
      );

      await _secureStorage.setAccessToken(response.accessToken);
      await _secureStorage.setRefreshToken(response.refreshToken);
      await _storage.setCachedUserEmail(response.user.email);

      // Set active business if available in memberships
      if (response.user.businessMemberships != null &&
          response.user.businessMemberships!.isNotEmpty) {
        final firstMembership = response.user.businessMemberships!.first;
        final businessId = firstMembership['businessId']?.toString();
        if (businessId != null) {
          await _storage.setActiveBusinessId(businessId);
        }
      }

      state = AuthState.authenticated(response.user);
      return true;
    } on AppException catch (e) {
      state = AuthState.unauthenticated(error: e.message);
      return false;
    } catch (e) {
      state = AuthState.unauthenticated(
        error: e.toString().replaceAll('Exception:', '').trim(),
      );
      return false;
    }
  }

  Future<bool> register(
    String name,
    String email,
    String password, {
    String? phone,
    bool isPlatformAdmin = false,
  }) async {
    try {
      final response = await _apiService.register(
        fullName: name.trim(),
        email: email.trim(),
        password: password,
        phone: phone?.trim(),
        isPlatformAdmin: isPlatformAdmin,
      );

      await _secureStorage.setAccessToken(response.accessToken);
      await _secureStorage.setRefreshToken(response.refreshToken);
      await _storage.setCachedUserEmail(response.user.email);

      state = AuthState.authenticated(response.user);
      return true;
    } on AppException catch (e) {
      state = AuthState.unauthenticated(error: e.message);
      return false;
    } catch (e) {
      state = AuthState.unauthenticated(
        error: e.toString().replaceAll('Exception:', '').trim(),
      );
      return false;
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      await _apiService.logout(refreshToken: refreshToken);
    } catch (_) {}

    await _secureStorage.deleteAccessToken();
    await _secureStorage.deleteRefreshToken();
    await _storage.setActiveBusinessId(null);
    state = const AuthState.unauthenticated();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiService = ref.watch(authApiServiceProvider);
  final secure = ref.watch(secureStorageServiceProvider);
  final storage = ref.watch(storageServiceProvider);
  return AuthNotifier(apiService, secure, storage);
});
