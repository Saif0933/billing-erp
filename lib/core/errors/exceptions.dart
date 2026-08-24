abstract class AppException implements Exception {
  final String message;
  final String? code;

  AppException(this.message, [this.code]);

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException([String message = 'Unable to connect to the server. Please check your internet connection and try again.'])
      : super(message, 'NETWORK_ERROR');
}

class AuthenticationException extends AppException {
  AuthenticationException([String message = 'Session expired or authentication failed. Please login again.'])
      : super(message, 'UNAUTHENTICATED');
}

class AuthorizationException extends AppException {
  AuthorizationException([String message = 'You do not have permission to perform this action.'])
      : super(message, 'UNAUTHORIZED');
}

class ValidationException extends AppException {
  final Map<String, List<String>> errors;
  ValidationException(String message, {this.errors = const {}}) : super(message, 'VALIDATION_ERROR');
}

class ServerException extends AppException {
  ServerException([String message = 'An unexpected server error occurred. Please try again later.'])
      : super(message, 'SERVER_ERROR');
}

class TimeoutException extends AppException {
  TimeoutException([String message = 'Request timed out. Please try again.'])
      : super(message, 'TIMEOUT_ERROR');
}

class SubscriptionException extends AppException {
  SubscriptionException([String message = 'This feature requires a premium plan. Upgrade to unlock.'])
      : super(message, 'SUBSCRIPTION_LOCKED');
}

class UnknownException extends AppException {
  UnknownException([String message = 'An unexpected error occurred. Please try again.'])
      : super(message, 'UNKNOWN_ERROR');
}
