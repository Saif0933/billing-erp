import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/models/login_request.dart';
import '../../data/models/register_request.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_provider.dart';

/// Provider for AuthRemoteDataSource
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRemoteDataSourceImpl(apiClient);
});

/// Provider for AuthRepository contract
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  final secureStorage = ref.watch(secureStorageServiceProvider);
  final storage = ref.watch(storageServiceProvider);

  return AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    secureStorage: secureStorage,
    storage: storage,
  );
});

/// Query: Fetch current authenticated user profile (/api/v1/auth/me)
final currentUserQueryProvider =
    FutureProvider.autoDispose<UserModel>((ref) async {
  final authRepo = ref.watch(authRepositoryProvider);
  return await authRepo.getCurrentUser();
});

/// Query: Check whether user is currently authenticated
final isAuthenticatedQueryProvider = FutureProvider<bool>((ref) async {
  final authRepo = ref.watch(authRepositoryProvider);
  return await authRepo.isAuthenticated();
});

/// Query: Reactive current user from auth state
final currentUserStateProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.user;
});

/// Query: Check if the logged in user is a platform admin
final isPlatformAdminQueryProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.isPlatformAdmin;
});

/// Mutation State for Async Actions
class AuthMutationState<T> {
  final bool isLoading;
  final T? data;
  final String? error;

  const AuthMutationState({
    this.isLoading = false,
    this.data,
    this.error,
  });

  bool get hasError => error != null;
  bool get isSuccess => !isLoading && error == null && data != null;
}

/// Mutation Notifier for Login
class LoginMutationNotifier
    extends StateNotifier<AsyncValue<UserModel?>> {
  final Ref _ref;

  LoginMutationNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<bool> mutate(LoginRequest request) async {
    state = const AsyncValue.loading();
    try {
      final success = await _ref.read(authProvider.notifier).login(
            request.email,
            request.password,
            isPlatformAdminPortal: request.isPlatformAdminPortal,
          );

      if (success) {
        final user = _ref.read(authProvider).user;
        state = AsyncValue.data(user);
        return true;
      } else {
        final err = _ref.read(authProvider).error ?? 'Login failed';
        state = AsyncValue.error(err, StackTrace.current);
        return false;
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

/// Provider for Login Mutation
final loginMutationProvider = StateNotifierProvider.autoDispose<
    LoginMutationNotifier, AsyncValue<UserModel?>>((ref) {
  return LoginMutationNotifier(ref);
});

/// Mutation Notifier for Registration
class RegisterMutationNotifier
    extends StateNotifier<AsyncValue<UserModel?>> {
  final Ref _ref;

  RegisterMutationNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<bool> mutate(RegisterRequest request) async {
    state = const AsyncValue.loading();
    try {
      final success = await _ref.read(authProvider.notifier).register(
            request.fullName,
            request.email,
            request.password,
            phone: request.phone,
            isPlatformAdmin: request.isPlatformAdmin,
          );

      if (success) {
        final user = _ref.read(authProvider).user;
        state = AsyncValue.data(user);
        return true;
      } else {
        final err = _ref.read(authProvider).error ?? 'Registration failed';
        state = AsyncValue.error(err, StackTrace.current);
        return false;
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

/// Provider for Register Mutation
final registerMutationProvider = StateNotifierProvider.autoDispose<
    RegisterMutationNotifier, AsyncValue<UserModel?>>((ref) {
  return RegisterMutationNotifier(ref);
});
