import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/storage/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

final storageServiceProvider = Provider<StorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return StorageService(prefs);
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) => const FlutterSecureStorage());

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  final secure = ref.watch(secureStorageProvider);
  return SecureStorageService(secure);
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
  const AuthState.unauthenticated({String? error}) : this(status: AuthStatus.unauthenticated, error: error);
  const AuthState.authenticated(UserModel user) : this(status: AuthStatus.authenticated, user: user);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final SecureStorageService _secureStorage;
  final StorageService _storage;

  AuthNotifier(this._secureStorage, this._storage) : super(const AuthState.splash()) {
    initialize();
  }

  Future<void> initialize() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    try {
      final token = await _secureStorage.getAccessToken();
      if (token != null) {
        final email = _storage.getCachedUserEmail() ?? 'owner@taxbunny.com';
        state = AuthState.authenticated(
          UserModel(id: 'usr_01', email: email, name: 'Alex Bunny'),
        );
      } else {
        state = const AuthState.unauthenticated();
      }
    } catch (_) {
      state = const AuthState.unauthenticated();
    }
  }

  Future<bool> login(String email, String password) async {
    state = const AuthState.splash();
    await Future.delayed(const Duration(milliseconds: 600));

    if (email.contains('@') && password.length >= 6) {
      await _secureStorage.setAccessToken('mock_access_token');
      await _secureStorage.setRefreshToken('mock_refresh_token');
      await _storage.setCachedUserEmail(email);
      final user = UserModel(id: 'usr_01', email: email, name: 'Alex Bunny');
      state = AuthState.authenticated(user);
      return true;
    } else {
      state = const AuthState.unauthenticated(error: 'Invalid credentials. Password must be >= 6 characters.');
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    state = const AuthState.splash();
    await Future.delayed(const Duration(milliseconds: 600));

    if (name.isNotEmpty && email.contains('@') && password.length >= 6) {
      await _secureStorage.setAccessToken('mock_access_token');
      await _secureStorage.setRefreshToken('mock_refresh_token');
      await _storage.setCachedUserEmail(email);
      final user = UserModel(id: 'usr_01', email: email, name: name);
      state = AuthState.authenticated(user);
      return true;
    } else {
      state = const AuthState.unauthenticated(error: 'Registration failed. Fill all fields correctly.');
      return false;
    }
  }

  Future<void> logout() async {
    await _secureStorage.deleteAccessToken();
    await _secureStorage.deleteRefreshToken();
    await _storage.setActiveBusinessId(null);
    state = const AuthState.unauthenticated();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final secure = ref.watch(secureStorageServiceProvider);
  final storage = ref.watch(storageServiceProvider);
  return AuthNotifier(secure, storage);
});
