import 'user_model.dart';

class AuthResponseModel {
  final UserModel user;
  final String accessToken;
  final String refreshToken;
  final String message;

  const AuthResponseModel({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.message,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final userJson = data['user'] as Map<String, dynamic>? ?? {};
    final accessToken = data['accessToken']?.toString() ?? '';
    final refreshToken = data['refreshToken']?.toString() ?? '';

    return AuthResponseModel(
      user: UserModel.fromJson(
        userJson,
        accessToken: accessToken,
        refreshToken: refreshToken,
      ),
      accessToken: accessToken,
      refreshToken: refreshToken,
      message: json['message']?.toString() ?? 'Success',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'data': {
        'user': user.toJson(),
        'accessToken': accessToken,
        'refreshToken': refreshToken,
      },
    };
  }
}
