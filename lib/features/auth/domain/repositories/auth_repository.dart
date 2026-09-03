import '../../data/models/auth_response_model.dart';
import '../../data/models/login_request.dart';
import '../../data/models/register_request.dart';
import '../../data/models/user_model.dart';

abstract class AuthRepository {
  Future<AuthResponseModel> login(LoginRequest request);
  Future<AuthResponseModel> register(RegisterRequest request);
  Future<void> logout();
  Future<UserModel> getCurrentUser();
  Future<String?> getSavedAccessToken();
  Future<String?> getSavedRefreshToken();
  Future<bool> isAuthenticated();
}
