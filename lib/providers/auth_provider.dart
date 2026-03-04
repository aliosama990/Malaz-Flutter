import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> checkLoginStatus() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      if (isLoggedIn) {
        String? userId = prefs.getString('userId');
        String? name = prefs.getString('userName');
        String? email = prefs.getString('userEmail');
        String? phone = prefs.getString('userPhone');
        String? token = prefs.getString('authToken');

        if (userId != null && name != null && email != null) {
          _user = UserModel(
            id: userId,
            name: name,
            email: email,
            phone: phone,
            token: token,
          );
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
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
    // Validation
    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
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
      // ✅ هنا هنستبدل ده بـ API Call لما الـ Backend يبقى جاهز
      // final response = await ApiService.register(name, email, phone, password);

      await Future.delayed(const Duration(seconds: 2)); // محاكاة API Call

      // ✅ محاكاة استجابة ناجحة من الـ Backend
      String userId = DateTime.now().millisecondsSinceEpoch.toString();
      String token = 'fake_token_${DateTime.now().millisecondsSinceEpoch}';

      _user = UserModel(
        id: userId,
        name: name,
        email: email,
        phone: phone,
        token: token,
      );

      // ✅ حفظ البيانات في SharedPreferences
      await _saveUserData(
        userId: userId,
        name: name,
        email: email,
        phone: phone,
        token: token,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'حدث خطأ أثناء التسجيل، حاول مرة أخرى';
      notifyListeners();
      return false;
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
      // ✅ هنا هنستبدل ده بـ API Call لما الـ Backend يبقى جاهز
      // final response = await ApiService.login(email, password);

      await Future.delayed(const Duration(seconds: 2));

      String userId = DateTime.now().millisecondsSinceEpoch.toString();
      String token = 'fake_token_${DateTime.now().millisecondsSinceEpoch}';

      _user = UserModel(
        id: userId,
        name: 'محمد أحمد', // هيجي من الـ API
        email: email,
        phone: '01234567890', // هيجي من الـ API
        token: token,
      );

      await _saveUserData(
        userId: userId,
        name: _user!.name,
        email: email,
        phone: _user!.phone,
        token: token,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      await prefs.remove('isLoggedIn');
      await prefs.remove('userId');
      await prefs.remove('userName');
      await prefs.remove('userEmail');
      await prefs.remove('userPhone');
      await prefs.remove('authToken');

      _user = null;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  // ✅ حفظ بيانات المستخدم في SharedPreferences
  Future<void> _saveUserData({
    required String userId,
    required String name,
    required String email,
    required String? phone,
    required String token,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userId', userId);
    await prefs.setString('userName', name);
    await prefs.setString('userEmail', email);
    if (phone != null) {
      await prefs.setString('userPhone', phone);
    }
    await prefs.setString('authToken', token);
  }

  // ✅ التحقق من صحة البريد الإلكتروني
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // ✅ مسح رسالة الخطأ
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
