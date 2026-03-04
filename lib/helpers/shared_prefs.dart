import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefs {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Keys
  static const String _hasRegisteredKey = 'hasRegistered';
  static const String _isLoggedInKey = 'isLoggedIn';
  static const String _authTokenKey = 'authToken';
  static const String _userIdKey = 'userId';

  static bool get hasRegistered => _prefs?.getBool(_hasRegisteredKey) ?? false;
  static Future<void> setHasRegistered(bool value) async {
    await _prefs?.setBool(_hasRegisteredKey, value);
  }

  static bool get isLoggedIn => _prefs?.getBool(_isLoggedInKey) ?? false;
  static Future<void> setLoggedIn(bool value) async {
    await _prefs?.setBool(_isLoggedInKey, value);
  }

  static String? get authToken => _prefs?.getString(_authTokenKey);
  static Future<void> setAuthToken(String token) async {
    await _prefs?.setString(_authTokenKey, token);
  }

  static String? get userId => _prefs?.getString(_userIdKey);
  static Future<void> setUserId(String id) async {
    await _prefs?.setString(_userIdKey, id);
  }

  static Future<void> logout() async {
    await _prefs?.setBool(_isLoggedInKey, false);
    await _prefs?.remove(_authTokenKey);
  }

  static Future<void> clearAll() async {
    await _prefs?.clear();
  }
}
