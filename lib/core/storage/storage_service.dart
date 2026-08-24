import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static const String _keyThemeMode = 'theme_mode';
  static const String _keyActiveBusinessId = 'active_business_id';
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyCachedUserEmail = 'cached_user_email';

  Future<void> setThemeMode(String themeMode) async {
    await _prefs.setString(_keyThemeMode, themeMode);
  }

  String? getThemeMode() {
    return _prefs.getString(_keyThemeMode);
  }

  Future<void> setActiveBusinessId(String? businessId) async {
    if (businessId == null) {
      await _prefs.remove(_keyActiveBusinessId);
    } else {
      await _prefs.setString(_keyActiveBusinessId, businessId);
    }
  }

  String? getActiveBusinessId() {
    return _prefs.getString(_keyActiveBusinessId);
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    await _prefs.setBool(_keyOnboardingCompleted, completed);
  }

  bool getOnboardingCompleted() {
    return _prefs.getBool(_keyOnboardingCompleted) ?? false;
  }

  Future<void> setCachedUserEmail(String email) async {
    await _prefs.setString(_keyCachedUserEmail, email);
  }

  String? getCachedUserEmail() {
    return _prefs.getString(_keyCachedUserEmail);
  }

  Future<void> clear() async {
    await _prefs.clear();
  }
}
