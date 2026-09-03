import 'package:dio/dio.dart';
import '../../errors/error_handler.dart';

/// Interceptor that converts raw Dio exceptions into typed domain AppExceptions
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Map the error through ErrorHandler
    final appException = ErrorHandler.handle(err);
    
    // Pass along the original exception with mapped message
    return handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: appException,
        message: appException.message,
      ),
    );
  }
}
