import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/auth_response_model.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login(LoginRequest request);
  Future<AuthResponseModel> register(RegisterRequest request);
  Future<String> refreshToken(String refreshToken);
  Future<void> logout({String? refreshToken});
  Future<UserModel> getMe();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSourceImpl(this._apiClient);

  @override
  Future<AuthResponseModel> login(LoginRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.login,
      data: request.toJson(),
    );
    return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<AuthResponseModel> register(RegisterRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.register,
      data: request.toJson(),
    );
    return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<String> refreshToken(String refreshToken) async {
    final response = await _apiClient.post(
      ApiEndpoints.refreshToken,
      data: {'refreshToken': refreshToken},
    );
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
    return data?['accessToken']?.toString() ?? '';
  }

  @override
  Future<void> logout({String? refreshToken}) async {
    final data = <String, dynamic>{};
    if (refreshToken != null && refreshToken.isNotEmpty) {
      data['refreshToken'] = refreshToken;
    }
    await _apiClient.post(
      ApiEndpoints.logout,
      data: data,
    );
  }

  @override
  Future<UserModel> getMe() async {
    final response = await _apiClient.get(ApiEndpoints.getMe);
    final json = response.data as Map<String, dynamic>;
    final data = (json['data'] as Map<String, dynamic>?) ?? json;
    return UserModel.fromJson(data);
  }
}
