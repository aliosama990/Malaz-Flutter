import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/shared_prefs.dart';
import '../models/user_model.dart';
import '../screens/login_screen.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  AuthProvider() {
    ApiService.onUnauthorized = _handleUnauthorized;
  }

  final ApiService _apiService = ApiService();

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = SharedPrefs.isLoggedIn;

      if (isLoggedIn) {
        final userId = SharedPrefs.userId ?? prefs.getString('userId');
        final name = prefs.getString('userName');
        final email = prefs.getString('userEmail');
        final phone = prefs.getString('userPhone');
        final token = SharedPrefs.authToken;
        final roles = prefs.getStringList('userRoles') ?? const <String>[];

        if (userId != null &&
            name != null &&
            email != null &&
            token != null &&
            token.trim().isNotEmpty) {
          _user = UserModel(
            id: userId,
            name: name,
            email: email,
            phone: phone,
            token: token,
            roles: roles,
          );
          notifyListeners();
          return true;
        }
      }
      await logout();
      return false;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  Future<bool> validateStoredToken() async {
    final hasValidStoredSession = await checkLoginStatus();
    if (!hasValidStoredSession) {
      return false;
    }

    try {
      await _apiService.get(
        '/Child/mychildren',
        handleUnauthorized: false,
      );
      return true;
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await logout();
        return false;
      }

      _errorMessage = _getApiErrorMessage(error);
      notifyListeners();
      rethrow;
    }
  }

  // ✅ Register - التسجيل
  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
  }) async {
    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _errorMessage = 'جميع الحقول مطلوبة';
      notifyListeners();
      return false;
    }

    if (!_isValidEmail(email)) {
      _errorMessage = 'البريد الإلكتروني غير صحيح';
      notifyListeners();
      return false;
    }

    if (password.length < 6) {
      _errorMessage = 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
      notifyListeners();
      return false;
    }

    if (password != confirmPassword) {
      _errorMessage = 'كلمة المرور غير متطابقة';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _registerRequest(
        userName: name,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      );

      final user = await _loginRequest(email: email, password: password);

      _user = user;
      await _saveUserData(user);

      return true;
    } on ApiException catch (e) {
      _errorMessage = _getApiErrorMessage(e);
      return false;
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء التسجيل، حاول مرة أخرى';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ Login - تسجيل الدخول
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    // Validation
    if (email.isEmpty || password.isEmpty) {
      _errorMessage = 'جميع الحقول مطلوبة';
      notifyListeners();
      return false;
    }

    if (!_isValidEmail(email)) {
      _errorMessage = 'البريد الإلكتروني غير صحيح';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _loginRequest(email: email, password: password);

      _user = user;
      await _saveUserData(user);

      return true;
    } on ApiException catch (e) {
      _errorMessage = _getApiErrorMessage(e);
      return false;
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء تسجيل الدخول، حاول مرة أخرى';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await SharedPrefs.logout();
      await prefs.remove('isLoggedIn');
      await prefs.remove('userId');
      await prefs.remove('userName');
      await prefs.remove('userEmail');
      await prefs.remove('userPhone');
      await prefs.remove('authToken');
      await prefs.remove('userRoles');

      _user = null;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  Future<void> _registerRequest({
    required String userName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final response = await _apiService.post(
      '/Auth/register',
      body: {
        'userName': userName,
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
      },
    );

    final responseBody = _requireMap(response.rawBody);
    if (!responseBody.containsKey('success')) {
      throw ApiException(
        'Unexpected response shape.',
        statusCode: response.statusCode,
        responseBody: responseBody,
      );
    }
  }

  Future<UserModel> _loginRequest({
    required String email,
    required String password,
  }) async {
    final response = await _apiService.post(
      '/Auth/login',
      body: {
        'email': email,
        'password': password,
      },
    );

    final responseBody = _requireMap(response.rawBody);
    final userJson = _requireMap(responseBody['user']);
    final token = _requireString(responseBody, 'token');
    final roles = _requireStringList(responseBody['roles']);

    return UserModel(
      id: _requireString(userJson, 'id'),
      name: _requireString(userJson, 'name'),
      email: _requireString(userJson, 'email'),
      token: token,
      roles: roles,
    );
  }

  Future<void> _saveUserData(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();

    await SharedPrefs.setHasRegistered(true);
    await SharedPrefs.setLoggedIn(true);
    await SharedPrefs.setUserId(user.id);
    await SharedPrefs.setAuthToken(user.token ?? '');

    await prefs.setString('userId', user.id);
    await prefs.setString('userName', user.name);
    await prefs.setString('userEmail', user.email);
    if (user.phone != null && user.phone!.trim().isNotEmpty) {
      await prefs.setString('userPhone', user.phone!);
    } else {
      await prefs.remove('userPhone');
    }
    if (user.token != null && user.token!.trim().isNotEmpty) {
      await prefs.setString('authToken', user.token!);
    } else {
      await prefs.remove('authToken');
    }
    if (user.roles.isNotEmpty) {
      await prefs.setStringList('userRoles', user.roles);
    } else {
      await prefs.remove('userRoles');
    }
  }

  Map<String, dynamic> _requireMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    throw ApiException(
      'Unexpected response shape.',
      responseBody: value,
    );
  }

  String _requireString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }

    throw ApiException(
      'Unexpected response shape.',
      responseBody: json,
    );
  }

  List<String> _requireStringList(dynamic value) {
    if (value == null) {
      return const <String>[];
    }

    if (value is List) {
      return value.map((item) => item.toString()).toList(growable: false);
    }

    throw ApiException(
      'Unexpected response shape.',
      responseBody: value,
    );
  }

  String _getApiErrorMessage(ApiException error) {
    if (error.errorMessages.isNotEmpty) {
      return error.errorMessages.join('\n');
    }
    return error.message;
  }

  Future<void> _handleUnauthorized(ApiException error) async {
    final errorMessage = _getApiErrorMessage(error);

    await logout();

    _errorMessage = errorMessage;
    notifyListeners();

    ApiService.scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    ApiService.scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(errorMessage)),
    );

    final navigatorState = ApiService.navigatorKey.currentState;
    if (navigatorState == null) {
      return;
    }

    navigatorState.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
