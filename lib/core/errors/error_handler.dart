import 'package:dio/dio.dart';
import 'exceptions.dart';

class ErrorHandler {
  ErrorHandler._();

  static AppException handle(dynamic error) {
    if (error is AppException) {
      return error;
    }

    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return TimeoutException();
        case DioExceptionType.connectionError:
          return NetworkException();
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final dynamic data = error.response?.data;
          final message = data is Map ? data['message'] ?? data['error'] : null;

          if (statusCode == 401) {
            return AuthenticationException(message?.toString() ?? 'Invalid credentials or expired session.');
          } else if (statusCode == 403) {
            return AuthorizationException(message?.toString() ?? 'You are not authorized to access this resource.');
          } else if (statusCode == 400 || statusCode == 422) {
            final errorsMap = <String, List<String>>{};
            if (data is Map && data['errors'] is Map) {
              (data['errors'] as Map).forEach((key, value) {
                if (value is List) {
                  errorsMap[key.toString()] = value.map((e) => e.toString()).toList();
                } else {
                  errorsMap[key.toString()] = [value.toString()];
                }
              });
            }
            return ValidationException(
              message?.toString() ?? 'Validation failed. Please check the entered fields.',
              errors: errorsMap,
            );
          } else if (statusCode == 409) {
            return ValidationException(
              message?.toString() ?? 'A record with these details already exists.',
            );
          } else if (statusCode != null && statusCode >= 500) {
            return ServerException(message?.toString() ?? 'Server encountered an issue.');
          }
          return UnknownException(message?.toString() ?? 'Something went wrong. Status: $statusCode');
        default:
          return UnknownException();
      }
    }

    return UnknownException(error?.toString() ?? 'An unknown error occurred.');
  }
}
