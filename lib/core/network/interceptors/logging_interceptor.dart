import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Interceptor that prints network requests and responses in debug mode
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('➡️ [DIO REQ] [${options.method}] ${options.baseUrl}${options.path}');
      if (options.queryParameters.isNotEmpty) {
        debugPrint('   Query: ${options.queryParameters}');
      }
      if (options.data != null) {
        debugPrint('   Body: ${options.data}');
      }
    }
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '⬅️ [DIO RES] [${response.statusCode}] ${response.requestOptions.path}',
      );
    }
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '❌ [DIO ERR] [${err.response?.statusCode ?? 'NO_STATUS'}] ${err.requestOptions.path}: ${err.message}',
      );
    }
    return handler.next(err);
  }
}
