import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/auth_response_model.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../models/user_model.dart';

typedef AuthResponse = AuthResponseModel;

class AuthApiService {
  final ApiClient _apiClient;

  AuthApiService(this._apiClient);

  /// Register User or Platform Admin
  Future<AuthResponseModel> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    bool isPlatformAdmin = false,
    String platform = 'WEB',
  }) async {
    final request = RegisterRequest(
      fullName: fullName,
      email: email,
      password: password,
      phone: phone,
      isPlatformAdmin: isPlatformAdmin,
      platform: platform,
    );

    final response = await _apiClient.post(
      ApiEndpoints.register,
      data: request.toJson(),
    );

    return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Login User or Platform Admin
  Future<AuthResponseModel> login({
    required String email,
    required String password,
    bool isPlatformAdminPortal = false,
    String platform = 'WEB',
    String? deviceInfo,
  }) async {
    final request = LoginRequest(
      email: email,
      password: password,
      isPlatformAdminPortal: isPlatformAdminPortal,
      platform: platform,
      deviceInfo: deviceInfo,
    );

    final response = await _apiClient.post(
      ApiEndpoints.login,
      data: request.toJson(),
    );

    return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Refresh Token
  Future<String> refreshToken(String refreshToken) async {
    final response = await _apiClient.post(
      ApiEndpoints.refreshToken,
      data: {
        'refreshToken': refreshToken,
      },
    );

    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
    return data?['accessToken']?.toString() ?? '';
  }

  /// Logout
  Future<void> logout({String? refreshToken}) async {
    final Map<String, dynamic> data = {};
    if (refreshToken != null && refreshToken.isNotEmpty) {
      data['refreshToken'] = refreshToken;
    }
    await _apiClient.post(
      ApiEndpoints.logout,
      data: data,
    );
  }

  /// Get Current Authenticated Profile
  Future<UserModel> getMe() async {
    final response = await _apiClient.get(ApiEndpoints.getMe);
    final json = response.data as Map<String, dynamic>;
    final data = (json['data'] as Map<String, dynamic>?) ?? json;
    return UserModel.fromJson(data);
  }
}
