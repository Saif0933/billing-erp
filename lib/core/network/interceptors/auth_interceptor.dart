import 'package:dio/dio.dart';
import '../../storage/secure_storage_service.dart';
import '../../storage/storage_service.dart';
import '../api_endpoints.dart';

/// Interceptor that attaches JWT Authorization Bearer token & active business ID,
/// and handles automatic 401 token refresh.
class AuthInterceptor extends QueuedInterceptor {
  final Dio dio;
  final SecureStorageService secureStorage;
  final StorageService storage;

  AuthInterceptor({
    required this.dio,
    required this.secureStorage,
    required this.storage,
  });

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 1. Attach Access Token if available
    final token = await secureStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // 2. Attach Active Business ID for multi-tenancy
    final activeBusinessId = storage.getActiveBusinessId();
    if (activeBusinessId != null && activeBusinessId.isNotEmpty) {
      options.headers['X-Business-ID'] = activeBusinessId;
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final isAuthError = response?.statusCode == 401;
    final requestPath = err.requestOptions.path;

    // Do not attempt refresh on auth endpoints themselves (login, register, refresh-token)
    final isExcludedAuthPath = requestPath.contains(ApiEndpoints.login) ||
        requestPath.contains(ApiEndpoints.register) ||
        requestPath.contains(ApiEndpoints.refreshToken);

    if (isAuthError && !isExcludedAuthPath) {
      final refreshToken = await secureStorage.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          // Attempt token refresh using a clean Dio instance to prevent infinite loops
          final refreshDio = Dio(
            BaseOptions(
              baseUrl: dio.options.baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: {'Content-Type': 'application/json'},
            ),
          );

          final refreshResponse = await refreshDio.post(
            ApiEndpoints.refreshToken,
            data: {'refreshToken': refreshToken},
          );

          if (refreshResponse.statusCode == 200 && refreshResponse.data != null) {
            final data = refreshResponse.data as Map<String, dynamic>;
            final innerData = data['data'] as Map<String, dynamic>?;
            final newAccessToken = innerData?['accessToken']?.toString() ??
                data['accessToken']?.toString();

            if (newAccessToken != null && newAccessToken.isNotEmpty) {
              await secureStorage.setAccessToken(newAccessToken);

              // Retry the original failed request with the new token
              final retryOptions = err.requestOptions;
              retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';

              final clonedResponse = await dio.fetch(retryOptions);
              return handler.resolve(clonedResponse);
            }
          }
        } catch (_) {
          // Token refresh failed, clear tokens
          await secureStorage.deleteAccessToken();
          await secureStorage.deleteRefreshToken();
        }
      }
    }

    return handler.next(err);
  }
}
