import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _secureStorage;

  SecureStorageService(this._secureStorage);

  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';

  Future<void> setAccessToken(String token) async {
    try {
      await _secureStorage.write(key: _keyAccessToken, value: token);
    } catch (_) {}
  }

  Future<String?> getAccessToken() async {
    try {
      return await _secureStorage.read(key: _keyAccessToken);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteAccessToken() async {
    try {
      await _secureStorage.delete(key: _keyAccessToken);
    } catch (_) {}
  }

  Future<void> setRefreshToken(String token) async {
    try {
      await _secureStorage.write(key: _keyRefreshToken, value: token);
    } catch (_) {}
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.read(key: _keyRefreshToken);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteRefreshToken() async {
    try {
      await _secureStorage.delete(key: _keyRefreshToken);
    } catch (_) {}
  }

  Future<void> clearAllSecureData() async {
    try {
      await _secureStorage.deleteAll();
    } catch (_) {}
  }
}
