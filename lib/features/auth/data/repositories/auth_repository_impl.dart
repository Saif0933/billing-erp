import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/storage/storage_service.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_response_model.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SecureStorageService secureStorage;
  final StorageService storage;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.secureStorage,
    required this.storage,
  });

  @override
  Future<AuthResponseModel> login(LoginRequest request) async {
    final response = await remoteDataSource.login(request);

    // Persist credentials locally
    await secureStorage.setAccessToken(response.accessToken);
    await secureStorage.setRefreshToken(response.refreshToken);
    await storage.setCachedUserEmail(response.user.email);

    // Auto-select first active business membership if available
    if (response.user.businessMemberships != null &&
        response.user.businessMemberships!.isNotEmpty) {
      final firstMembership = response.user.businessMemberships!.first;
      final businessId = firstMembership['businessId']?.toString();
      if (businessId != null) {
        await storage.setActiveBusinessId(businessId);
      }
    }

    return response;
  }

  @override
  Future<AuthResponseModel> register(RegisterRequest request) async {
    final response = await remoteDataSource.register(request);

    // Persist credentials locally
    await secureStorage.setAccessToken(response.accessToken);
    await secureStorage.setRefreshToken(response.refreshToken);
    await storage.setCachedUserEmail(response.user.email);

    return response;
  }

  @override
  Future<UserModel> getCurrentUser() async {
    return await remoteDataSource.getMe();
  }

  @override
  Future<void> logout() async {
    try {
      final refreshToken = await secureStorage.getRefreshToken();
      await remoteDataSource.logout(refreshToken: refreshToken);
    } catch (_) {
      // Proceed with clearing local storage even if remote logout fails
    }

    await secureStorage.deleteAccessToken();
    await secureStorage.deleteRefreshToken();
    await storage.setActiveBusinessId(null);
  }

  @override
  Future<String?> getSavedAccessToken() async {
    return await secureStorage.getAccessToken();
  }

  @override
  Future<String?> getSavedRefreshToken() async {
    return await secureStorage.getRefreshToken();
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await secureStorage.getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
