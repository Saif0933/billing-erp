import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../errors/error_handler.dart';
import '../storage/secure_storage_service.dart';
import '../storage/storage_service.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

class ApiClient {
  final Dio _dio;
  final SecureStorageService _secureStorage;
  final StorageService _storage;
  bool _isDetectingUrl = false;

  ApiClient(this._secureStorage, this._storage, {Dio? dio})
    : _dio = dio ?? Dio() {
    final baseUrl = _resolveBaseUrl();

    _dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    // Register modular interceptors
    _dio.interceptors.addAll([
      AuthInterceptor(
        dio: _dio,
        secureStorage: _secureStorage,
        storage: _storage,
      ),
      LoggingInterceptor(),
      ErrorInterceptor(),
    ]);
  }

  /// Ordered list of candidate backend URLs to test
  static List<String> get candidateBaseUrls {
    if (kIsWeb) {
      final envUrl = dotenv.isInitialized ? dotenv.maybeGet('API_BASE_URL') : null;
      return [
        if (envUrl != null && envUrl.isNotEmpty) envUrl,
        'http://localhost:5000',
      ];
    }

    final envUrl = dotenv.isInitialized ? dotenv.maybeGet('API_BASE_URL') : null;
    return {
      if (envUrl != null && envUrl.isNotEmpty && !envUrl.contains('taxbunny.com')) envUrl,
      'http://127.0.0.1:5000',      // USB with adb reverse
      'http://192.168.31.106:5000',  // Wi-Fi LAN
      'http://10.0.2.2:5000',        // Android Emulator
      'http://localhost:5000',
    }.toList();
  }

  static String _resolveBaseUrl() {
    if (kIsWeb) {
      try {
        if (dotenv.isInitialized) {
          final url = dotenv.maybeGet('API_BASE_URL');
          if (url != null && url.isNotEmpty) return url;
        }
      } catch (_) {}
      return 'http://localhost:5000';
    }

    try {
      if (dotenv.isInitialized) {
        final url = dotenv.maybeGet('API_BASE_URL');
        if (url != null && url.isNotEmpty && !url.contains('taxbunny.com')) {
          if (!url.contains('localhost') && !url.contains('127.0.0.1')) {
            return url;
          }
        }
      }
    } catch (_) {}

    // Default to USB adb reverse for mobile devices
    return 'http://127.0.0.1:5000';
  }

  /// Automatically tests candidate server URLs and locks onto the first active one
  Future<String> detectWorkingBaseUrl() async {
    if (_isDetectingUrl) return _dio.options.baseUrl;
    _isDetectingUrl = true;

    try {
      final candidates = candidateBaseUrls;
      if (candidates.length <= 1) return _dio.options.baseUrl;

      // Ping candidates in parallel with 1500ms timeout
      final pingFutures = candidates.map((url) async {
        try {
          final pingDio = Dio(
            BaseOptions(
              baseUrl: url,
              connectTimeout: const Duration(milliseconds: 1500),
              receiveTimeout: const Duration(milliseconds: 1500),
            ),
          );
          final res = await pingDio.get('/');
          if (res.statusCode == 200) {
            return url;
          }
        } catch (_) {}
        return null;
      }).toList();

      for (final future in pingFutures) {
        final working = await future;
        if (working != null) {
          if (_dio.options.baseUrl != working) {
            debugPrint('🌐 [ApiClient] Detected active backend: $working (was ${_dio.options.baseUrl})');
            _dio.options.baseUrl = working;
          }
          return working;
        }
      }
    } finally {
      _isDetectingUrl = false;
    }

    return _dio.options.baseUrl;
  }

  bool _isConnectionError(DioException e) {
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout;
  }

  Dio get dio => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (!kIsWeb && _isConnectionError(e)) {
        final oldUrl = _dio.options.baseUrl;
        final newUrl = await detectWorkingBaseUrl();
        if (newUrl != oldUrl) {
          try {
            return await _dio.get<T>(
              path,
              queryParameters: queryParameters,
              options: options,
              cancelToken: cancelToken,
            );
          } catch (retryErr) {
            throw ErrorHandler.handle(retryErr);
          }
        }
      }
      throw ErrorHandler.handle(e);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (!kIsWeb && _isConnectionError(e)) {
        final oldUrl = _dio.options.baseUrl;
        final newUrl = await detectWorkingBaseUrl();
        if (newUrl != oldUrl) {
          try {
            return await _dio.post<T>(
              path,
              data: data,
              queryParameters: queryParameters,
              options: options,
              cancelToken: cancelToken,
            );
          } catch (retryErr) {
            throw ErrorHandler.handle(retryErr);
          }
        }
      }
      throw ErrorHandler.handle(e);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (!kIsWeb && _isConnectionError(e)) {
        final oldUrl = _dio.options.baseUrl;
        final newUrl = await detectWorkingBaseUrl();
        if (newUrl != oldUrl) {
          try {
            return await _dio.put<T>(
              path,
              data: data,
              queryParameters: queryParameters,
              options: options,
              cancelToken: cancelToken,
            );
          } catch (retryErr) {
            throw ErrorHandler.handle(retryErr);
          }
        }
      }
      throw ErrorHandler.handle(e);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (!kIsWeb && _isConnectionError(e)) {
        final oldUrl = _dio.options.baseUrl;
        final newUrl = await detectWorkingBaseUrl();
        if (newUrl != oldUrl) {
          try {
            return await _dio.patch<T>(
              path,
              data: data,
              queryParameters: queryParameters,
              options: options,
              cancelToken: cancelToken,
            );
          } catch (retryErr) {
            throw ErrorHandler.handle(retryErr);
          }
        }
      }
      throw ErrorHandler.handle(e);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (!kIsWeb && _isConnectionError(e)) {
        final oldUrl = _dio.options.baseUrl;
        final newUrl = await detectWorkingBaseUrl();
        if (newUrl != oldUrl) {
          try {
            return await _dio.delete<T>(
              path,
              data: data,
              queryParameters: queryParameters,
              options: options,
              cancelToken: cancelToken,
            );
          } catch (retryErr) {
            throw ErrorHandler.handle(retryErr);
          }
        }
      }
      throw ErrorHandler.handle(e);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
