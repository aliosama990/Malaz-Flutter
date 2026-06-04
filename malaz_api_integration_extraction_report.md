# 1) High-Level Integration Inventory

| Area | Status | Main files involved | Backend endpoint(s) | Postman contract match |
|---|---|---|---|---|
| TG0: Shared API service layer | Fully implemented | [api_service.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/services/api_service.dart), [shared_prefs.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/helpers/shared_prefs.dart), [main.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/main.dart) | Supports all grounded endpoints | Yes |
| TG1: Auth login/register | Fully implemented | [auth_provider.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/providers/auth_provider.dart), [user_model.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/models/user_model.dart), [login_screen.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/login_screen.dart), [register_screen.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/register_screen.dart), [shared_prefs.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/helpers/shared_prefs.dart) | `POST /Auth/login`, `POST /Auth/register` | Mostly; `roles[]` is not modeled and register response fields are not fully modeled |
| TG2: Child APIs | Fully implemented | [child_provider.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/providers/child_provider.dart), [child_mode.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/models/child_mode.dart), [add_child_screen.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/add_child_screen.dart), [home_screen.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/home_screen.dart), [child_details_screen.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/child_details_screen.dart) | `POST /Child/addchild`, `GET /Child/mychildren`, `GET /Child/{id}` | Yes |
| TG3: SafeZone APIs | Fully implemented | [safezone_provider.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/providers/safezone_provider.dart), [safe_zone_model.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/models/safe_zone_model.dart), [safezone_screen.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/safezone_screen.dart), [newsafezone_screen.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/newsafezone_screen.dart), [google_map.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/google_map.dart), [main.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/main.dart) | `POST /api/SafeZone/add`, `GET /api/SafeZone/child/{id}`, `GET /api/SafeZone/{id}`, `PUT /api/SafeZone/{id}`, `DELETE /api/SafeZone/{id}` | Yes |
| TG4: Hardening | Fully implemented | [api_service.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/services/api_service.dart), [auth_provider.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/providers/auth_provider.dart), [splash_screen.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/splash_screen.dart), [main.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/main.dart) | Grounded validation uses `GET /Child/mychildren` | Mostly; full `errorMessages[]` surfacing is not consistent outside auth/splash |

# 2) Extracted Code By File

## [shared_prefs.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/helpers/shared_prefs.dart)
Why this file matters: shared session persistence for JWT, login state, and launch-state restore. Relevant lines: 3-43.

This block initializes and persists auth/session keys.

```dart
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
```

## [api_service.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/services/api_service.dart)
Why this file matters: base URL, HTTP verbs, Bearer token injection, common envelope parsing, network error handling, and global 401 handling. Relevant lines: 10-252, 263-388.

This block defines the shared service config and public HTTP verbs.

```dart
typedef UnauthorizedHandler = Future<void> Function(ApiException exception);

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  static const String baseUrl = 'https://malaz.runasp.net';
  static const Duration _requestTimeout = Duration(seconds: 30);
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  static UnauthorizedHandler? onUnauthorized;
  static bool _isHandlingUnauthorized = false;

  final http.Client _client;

  Future<ApiResponse> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool handleUnauthorized = true,
  }) {
    return _send(
      method: 'GET',
      path: path,
      queryParameters: queryParameters,
      headers: headers,
      handleUnauthorized: handleUnauthorized,
    );
  }

  Future<ApiResponse> post(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool handleUnauthorized = true,
  }) {
    return _send(
      method: 'POST',
      path: path,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
      handleUnauthorized: handleUnauthorized,
    );
  }

  Future<ApiResponse> put(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool handleUnauthorized = true,
  }) {
    return _send(
      method: 'PUT',
      path: path,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
      handleUnauthorized: handleUnauthorized,
    );
  }

  Future<ApiResponse> delete(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool handleUnauthorized = true,
  }) {
    return _send(
      method: 'DELETE',
      path: path,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
      handleUnauthorized: handleUnauthorized,
    );
  }
```

This block sends requests, encodes JSON bodies, and triggers global unauthorized handling.

```dart
  Future<ApiResponse> _send({
    required String method,
    required String path,
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    required bool handleUnauthorized,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final requestHeaders = await _buildHeaders(headers: headers);
    final encodedBody = body == null ? null : jsonEncode(body);

    try {
      late final http.Response response;

      switch (method) {
        case 'GET':
          response = await _client
              .get(uri, headers: requestHeaders)
              .timeout(_requestTimeout);
          break;
        case 'POST':
          response = await _client
              .post(uri, headers: requestHeaders, body: encodedBody)
              .timeout(_requestTimeout);
          break;
        case 'PUT':
          response = await _client
              .put(uri, headers: requestHeaders, body: encodedBody)
              .timeout(_requestTimeout);
          break;
        case 'DELETE':
          response = await _client
              .delete(uri, headers: requestHeaders, body: encodedBody)
              .timeout(_requestTimeout);
          break;
        default:
          throw ApiException('Unsupported HTTP method: $method');
      }

      final apiResponse = ApiResponse.fromHttpResponse(response);

      if (!_isSuccessStatusCode(response.statusCode)) {
        final exception = ApiException(
          apiResponse.primaryErrorMessage ??
              _defaultStatusMessage(response.statusCode),
          statusCode: response.statusCode,
          errorMessages: apiResponse.errorMessages,
          responseBody: apiResponse.rawBody,
        );
        if (response.statusCode == 401 && handleUnauthorized) {
          await _handleUnauthorized(exception);
        }
        throw exception;
      }

      if (apiResponse.hasEnvelope && !apiResponse.success) {
        final exception = ApiException(
          apiResponse.primaryErrorMessage ?? 'الخادم أعاد استجابة فاشلة.',
          statusCode: response.statusCode,
          errorMessages: apiResponse.errorMessages,
          responseBody: apiResponse.rawBody,
        );
        if (response.statusCode == 401 && handleUnauthorized) {
          await _handleUnauthorized(exception);
        }
        throw exception;
      }

      return apiResponse;
    } on ApiException {
      rethrow;
    } on SocketException catch (error) {
      throw ApiException(
        'تعذر الاتصال بالإنترنت. تحقق من الشبكة وحاول مرة أخرى.',
        cause: error,
      );
    } on TimeoutException catch (error) {
      throw ApiException(
        'انتهت مهلة الاتصال بالخادم. حاول مرة أخرى.',
        cause: error,
      );
    } on http.ClientException catch (error) {
      throw ApiException(
        'تعذر إتمام الاتصال بالخادم. حاول مرة أخرى.',
        cause: error,
      );
    } catch (error) {
      throw ApiException(
        'حدث خطأ غير متوقع أثناء الاتصال بالخادم.',
        cause: error,
      );
    }
  }

  static Future<void> _handleUnauthorized(ApiException exception) async {
    if (_isHandlingUnauthorized) {
      return;
    }

    _isHandlingUnauthorized = true;
    try {
      if (onUnauthorized != null) {
        await onUnauthorized!(exception);
      } else {
        await SharedPrefs.logout();
      }
    } finally {
      _isHandlingUnauthorized = false;
    }
  }
```

This block builds URLs, headers, injects the Bearer token, and parses the common response envelope.

```dart
  Uri _buildUri(String path, Map<String, dynamic>? queryParameters) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$baseUrl$normalizedPath');

    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }

    final normalizedQueryParameters = <String, String>{};
    for (final entry in queryParameters.entries) {
      if (entry.value != null) {
        normalizedQueryParameters[entry.key] = entry.value.toString();
      }
    }

    if (normalizedQueryParameters.isEmpty) {
      return uri;
    }

    return uri.replace(queryParameters: normalizedQueryParameters);
  }

  Future<Map<String, String>> _buildHeaders({
    Map<String, String>? headers,
  }) async {
    final requestHeaders = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final token = SharedPrefs.authToken;
    if (token != null && token.trim().isNotEmpty) {
      requestHeaders['Authorization'] = 'Bearer $token';
    }

    if (headers != null && headers.isNotEmpty) {
      requestHeaders.addAll(headers);
    }

    return requestHeaders;
  }

  bool _isSuccessStatusCode(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }
}

class ApiResponse {
  ApiResponse({
    required this.statusCode,
    required this.success,
    required this.hasEnvelope,
    required this.errorMessages,
    required this.data,
    required this.rawBody,
    required this.headers,
  });

  final int statusCode;
  final bool success;
  final bool hasEnvelope;
  final List<String> errorMessages;
  final dynamic data;
  final dynamic rawBody;
  final Map<String, String> headers;

  String? get primaryErrorMessage {
    if (errorMessages.isEmpty) {
      return null;
    }
    return errorMessages.first;
  }

  factory ApiResponse.fromHttpResponse(http.Response response) {
    final parsedBody = _parseBody(response);

    if (parsedBody is Map<String, dynamic> && _looksLikeEnvelope(parsedBody)) {
      return ApiResponse(
        statusCode: response.statusCode,
        success: parsedBody['success'] == true,
        hasEnvelope: true,
        errorMessages: _normalizeErrorMessages(parsedBody['errorMessages']),
        data: parsedBody['data'],
        rawBody: parsedBody,
        headers: response.headers,
      );
    }

    return ApiResponse(
      statusCode: response.statusCode,
      success: response.statusCode >= 200 && response.statusCode < 300,
      hasEnvelope: false,
      errorMessages: const [],
      data: parsedBody,
      rawBody: parsedBody,
      headers: response.headers,
    );
  }

  static dynamic _parseBody(http.Response response) {
    final body = response.body.trim();
    if (body.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(body);

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      if (decoded is List) {
        return List<dynamic>.from(decoded);
      }

      return decoded;
    } on FormatException {
      throw ApiException(
        'Unexpected response shape.',
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    }
  }

  static bool _looksLikeEnvelope(Map<String, dynamic> json) {
    return json.containsKey('success') ||
        json.containsKey('errorMessages') ||
        json.containsKey('data');
  }

  static List<String> _normalizeErrorMessages(dynamic value) {
    if (value == null) {
      return const [];
    }

    if (value is String && value.trim().isNotEmpty) {
      return <String>[value];
    }

    if (value is List) {
      return value
          .where((item) => item != null)
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList(growable: false);
    }

    return <String>[value.toString()];
  }
}

class ApiException implements Exception {
  ApiException(
    this.message, {
    this.statusCode,
    this.errorMessages = const [],
    this.responseBody,
    this.cause,
  });

  final String message;
  final int? statusCode;
  final List<String> errorMessages;
  final dynamic responseBody;
  final Object? cause;
}
```

## [user_model.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/models/user_model.dart)
Why this file matters: auth response model used by `AuthProvider`. Relevant lines: 1-34.

This block defines the current user API model and parser.

```dart
class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? token;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.token,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'token': token,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      token: json['token'] as String?,
    );
  }
}
```

## [auth_provider.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/providers/auth_provider.dart)
Why this file matters: real auth integration, token/session persistence, restore, token validation, and global unauthorized handling. Relevant lines: 24-335.

This block restores persisted login state and validates a stored token through a grounded authenticated request.

```dart
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
```

This block implements real register and login flows.

```dart
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

Future<bool> login({
  required String email,
  required String password,
}) async {
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
```

This block builds auth requests, parses the login response, and persists the real JWT/session state.

```dart
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

  return UserModel(
    id: _requireString(userJson, 'id'),
    name: _requireString(userJson, 'name'),
    email: _requireString(userJson, 'email'),
    token: token,
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
}
```

This block handles response-shape validation, error message surfacing, and global logout/redirect on `401`.

```dart
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
```

## [login_screen.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/login_screen.dart)
Why this file matters: UI trigger for real login. Relevant lines: 89-120.

This block triggers `AuthProvider.login()` and shows the provider error message.

```dart
Future<void> _handleLogin() async {
  if (_formKey.currentState!.validate()) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ?? 'حدث خطأ أثناء تسجيل الدخول',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}
```

## [register_screen.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/register_screen.dart)
Why this file matters: UI trigger for real register + auto-login flow. Relevant lines: 96-130.

This block triggers `AuthProvider.register()` and advances to the child flow on success.

```dart
Future<void> _handleRegister() async {
  if (_formKey.currentState!.validate()) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AddChildScreen()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ?? 'حدث خطأ أثناء التسجيل',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}
```

## [child_mode.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/models/child_mode.dart)
Why this file matters: grounded child model/parser with `gender` as `int` and camelCase field parsing. Relevant lines: 1-87.

This block defines the child API model and parser.

```dart
class ChildModel {
  final String id;
  final String name;
  final String birthDate;
  final int gender;
  final String deviceId;

  ChildModel({
    required this.id,
    required this.name,
    required this.birthDate,
    required this.gender,
    required this.deviceId,
  });

  int get age {
    final birthDateTime = DateTime.parse(birthDate);
    final today = DateTime.now();
    int age = today.year - birthDateTime.year;
    if (today.month < birthDateTime.month ||
        (today.month == birthDateTime.month && today.day < birthDateTime.day)) {
      age--;
    }
    return age;
  }

  factory ChildModel.fromJson(Map<String, dynamic> json) {
    return ChildModel(
      id: _requireString(json, 'id'),
      name: _requireString(json, 'name'),
      birthDate: _normalizeBirthDate(json['birthDate']),
      gender: _requireGender(json['gender']),
      deviceId: _requireOptionalString(json['deviceId']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'birthDate': birthDate,
      'gender': gender,
      'deviceId': deviceId,
    };
  }

  static String _requireString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }

    throw FormatException('Invalid child field: $key');
  }

  static String _requireOptionalString(dynamic value) {
    if (value == null) {
      return '';
    }

    if (value is String) {
      return value;
    }

    throw const FormatException('Invalid child field: deviceId');
  }

  static int _requireGender(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    throw const FormatException('Invalid child field: gender');
  }

  static String _normalizeBirthDate(dynamic value) {
    if (value is! String || value.trim().isEmpty) {
      throw const FormatException('Invalid child field: birthDate');
    }

    return value.split('T').first;
  }
}
```

## [child_provider.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/providers/child_provider.dart)
Why this file matters: real child add/list/detail integration. Relevant lines: 6-167.

This block implements child add/list/detail calls and response parsing.

```dart
class ChildProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<ChildModel> _children = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ChildModel> get children => _children;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get childrenCount => _children.length;

  Future<bool> addChild({
    required String name,
    required String birthDate,
    required int gender,
    required String deviceId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        '/Child/addchild',
        body: {
          'name': name,
          'birthDate': birthDate,
          'gender': gender,
          'deviceId': deviceId,
        },
      );

      final newChild = _parseChildFromResponse(response);
      updateChild(newChild);
      return true;
    } on ApiException catch (error) {
      _errorMessage = _getApiErrorMessage(error);
      return false;
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء إضافة الطفل';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> fetchMyChildren() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/Child/mychildren');
      final responseData = _requireList(response.data);

      _children = responseData
          .map((item) => ChildModel.fromJson(_requireMap(item)))
          .toList(growable: false);
      return true;
    } on ApiException catch (error) {
      _errorMessage = _getApiErrorMessage(error);
      return false;
    } on FormatException {
      _errorMessage = 'Unexpected response shape.';
      return false;
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء جلب الأطفال';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ChildModel?> fetchChildById(String childId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/Child/$childId');
      final child = _parseChildFromResponse(response);
      updateChild(child);
      return child;
    } on ApiException catch (error) {
      _errorMessage = _getApiErrorMessage(error);
      return null;
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء جلب بيانات الطفل';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  ChildModel _parseChildFromResponse(ApiResponse response) {
    try {
      return ChildModel.fromJson(_requireMap(response.data));
    } on FormatException {
      throw ApiException(
        'Unexpected response shape.',
        statusCode: response.statusCode,
        responseBody: response.rawBody,
      );
    }
  }

  Map<String, dynamic> _requireMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    throw const FormatException('Invalid child response map.');
  }

  List<dynamic> _requireList(dynamic value) {
    if (value is List) {
      return List<dynamic>.from(value);
    }

    throw const FormatException('Invalid child response list.');
  }

  String _getApiErrorMessage(ApiException error) {
    if (error.errorMessages.isNotEmpty) {
      return error.errorMessages.first;
    }
    return error.message;
  }
}
```

## [add_child_screen.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/add_child_screen.dart)
Why this file matters: UI trigger for `POST /Child/addchild`, including `birthDate` formatting and `gender` mapping. Relevant lines: 104-156.

This block builds the grounded request values and calls `ChildProvider.addChild()`.

```dart
String? _getBirthDate() {
  if (_selectedYear != null &&
      _selectedMonth != null &&
      _selectedDay != null) {
    return '$_selectedYear-${_selectedMonth!.padLeft(2, '0')}-${_selectedDay!.padLeft(2, '0')}';
  }
  return null;
}

int _getGenderValue() {
  return _selectedGender == AppStrings.addChildGenderFemale ? 1 : 0;
}

Future<void> _handleAddChild() async {
  if (_formKey.currentState!.validate()) {
    final birthDate = _getBirthDate();
    if (birthDate == null) {
      setState(() {
        _showBirthDateError = true;
      });
      return;
    }

    setState(() {
      _showBirthDateError = false;
    });

    final childProvider = Provider.of<ChildProvider>(context, listen: false);

    final success = await childProvider.addChild(
      name: _nameController.text.trim(),
      birthDate: birthDate,
      gender: _getGenderValue(),
      deviceId: _deviceIdController.text.trim(),
    );

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            childProvider.errorMessage ?? AppStrings.addChildError,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}
```

## [home_screen.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/home_screen.dart)
Why this file matters: loads the authenticated user's child list and displays loading/error state. Relevant lines: 49-56, 73-100, 159-170.

This block triggers `GET /Child/mychildren` after screen mount.

```dart
_headerController.forward();
Future.delayed(const Duration(milliseconds: 100), () {
  _fadeController.forward();
});

WidgetsBinding.instance.addPostFrameCallback((_) {
  Provider.of<ChildProvider>(context, listen: false).fetchMyChildren();
});
```

This block consumes auth + child provider state and exposes logout.

```dart
child: Consumer2<AuthProvider, ChildProvider>(
  builder: (context, authProvider, childProvider, _) {
    final userName = authProvider.user?.name ?? 'مروه عبد الرحمن';
    final children = childProvider.children;

    return Column(
      children: [
        SlideTransition(
          position: _headerSlideAnimation,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 22),
            color: AppColors.registerTitle,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.logout,
                      color: Colors.white, size: 26),
                  onPressed: () {
                    Provider.of<AuthProvider>(context, listen: false)
                        .logout();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                    );
                  },
                ),
```

This block renders child loading/error state from the API-backed provider.

```dart
child: children.isEmpty
    ? Center(
        child: childProvider.isLoading
            ? const CircularProgressIndicator(
                color: Colors.white,
              )
            : Text(
                childProvider.errorMessage ??
                    AppStrings.noChildrenYet,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: Colors.white60,
                ),
              ),
      )
```

## [child_details_screen.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/child_details_screen.dart)
Why this file matters: UI trigger for `GET /Child/{id}`. Relevant lines: 24-44.

This block fetches the real child detail on screen load and feeds it into a `FutureBuilder`.

```dart
class _ChildDetailsScreenState extends State<ChildDetailsScreen> {
  late Future<ChildModel?> _childFuture;

  @override
  void initState() {
    super.initState();
    _childFuture = Provider.of<ChildProvider>(
      context,
      listen: false,
    ).fetchChildById(widget.child.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ChildModel?>(
      future: _childFuture,
      initialData: widget.child,
      builder: (context, snapshot) {
        final child = snapshot.data ?? widget.child;
```

## [safe_zone_model.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/models/safe_zone_model.dart)
Why this file matters: grounded SafeZone request/response model. Relevant lines: 1-84.

This block defines the SafeZone API model and contract-grounded parser.

```dart
class SafeZoneModel {
  SafeZoneModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusInMeters,
    required this.type,
    required this.typeDisplayName,
    required this.createdAt,
    this.childId,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final int radiusInMeters;
  final int type;
  final String typeDisplayName;
  final String createdAt;
  final String? childId;

  factory SafeZoneModel.fromJson(
    Map<String, dynamic> json, {
    String? childId,
  }) {
    return SafeZoneModel(
      id: _requireString(json['id'], 'id'),
      name: _requireString(json['name'], 'name'),
      latitude: _requireDouble(json['latitude'], 'latitude'),
      longitude: _requireDouble(json['longitude'], 'longitude'),
      radiusInMeters: _requireInt(json['radiusInMeters'], 'radiusInMeters'),
      type: _requireInt(json['type'], 'type'),
      typeDisplayName:
          _requireString(json['typeDisplayName'], 'typeDisplayName'),
      createdAt: _requireString(json['createdAt'], 'createdAt'),
      childId: childId,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radiusInMeters': radiusInMeters,
      'type': type,
      'typeDisplayName': typeDisplayName,
      'createdAt': createdAt,
    };

    if (childId != null && childId!.trim().isNotEmpty) {
      json['childId'] = childId;
    }

    return json;
  }

  static String _requireString(dynamic value, String fieldName) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }

    throw FormatException('SafeZone field "$fieldName" is missing or invalid.');
  }

  static double _requireDouble(dynamic value, String fieldName) {
    if (value is num) {
      return value.toDouble();
    }

    throw FormatException('SafeZone field "$fieldName" is missing or invalid.');
  }

  static int _requireInt(dynamic value, String fieldName) {
    if (value is num) {
      return value.toInt();
    }

    throw FormatException('SafeZone field "$fieldName" is missing or invalid.');
  }
}
```

## [safezone_provider.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/providers/safezone_provider.dart)
Why this file matters: real SafeZone CRUD integration. Relevant lines: 6-201.

This block implements SafeZone list/get/add/update/delete over the grounded `/api/SafeZone/...` endpoints.

```dart
class SafeZoneProvider extends ChangeNotifier {
  SafeZoneProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  List<SafeZoneModel> _zones = const [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _activeChildId;

  List<SafeZoneModel> get zones => _zones;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  Future<List<SafeZoneModel>> fetchZonesForChild(String childId) async {
    _activeChildId = childId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/api/SafeZone/child/$childId');
      final data = response.data;

      if (data is! List) {
        throw ApiException('Unexpected response shape.');
      }

      _zones = data
          .map((item) => _parseZone(item, childId: childId))
          .toList(growable: false);
      return _zones;
    } on ApiException catch (error) {
      _errorMessage = _getErrorMessage(error);
      rethrow;
    } catch (error) {
      _errorMessage = 'Unexpected response shape.';
      throw ApiException('Unexpected response shape.', cause: error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<SafeZoneModel> fetchZone(String zoneId) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/api/SafeZone/$zoneId');
      final zone = _parseZone(response.data, childId: _activeChildId);
      _replaceZone(zone);
      return zone;
    } on ApiException catch (error) {
      _errorMessage = _getErrorMessage(error);
      notifyListeners();
      rethrow;
    } catch (error) {
      _errorMessage = 'Unexpected response shape.';
      notifyListeners();
      throw ApiException('Unexpected response shape.', cause: error);
    }
  }

  Future<SafeZoneModel> addZone({
    required String childId,
    required String name,
    required double latitude,
    required double longitude,
    required int radiusInMeters,
    required int type,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        '/api/SafeZone/add',
        body: <String, dynamic>{
          'childId': childId,
          'name': name,
          'latitude': latitude,
          'longitude': longitude,
          'radiusInMeters': radiusInMeters,
          'type': type,
        },
      );

      final zone = _parseZone(response.data, childId: childId);
      if (_activeChildId == childId) {
        _zones = <SafeZoneModel>[..._zones, zone];
      }
      return zone;
    } on ApiException catch (error) {
      _errorMessage = _getErrorMessage(error);
      rethrow;
    } catch (error) {
      _errorMessage = 'Unexpected response shape.';
      throw ApiException('Unexpected response shape.', cause: error);
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<SafeZoneModel> updateZone(
    String zoneId, {
    required String name,
    required double latitude,
    required double longitude,
    required int radiusInMeters,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.put(
        '/api/SafeZone/$zoneId',
        body: <String, dynamic>{
          'Name': name,
          'Latitude': latitude,
          'Longitude': longitude,
          'RadiusInMeters': radiusInMeters,
        },
      );

      final zone = _parseZone(response.data, childId: _activeChildId);
      _replaceZone(zone);
      return zone;
    } on ApiException catch (error) {
      _errorMessage = _getErrorMessage(error);
      rethrow;
    } catch (error) {
      _errorMessage = 'Unexpected response shape.';
      throw ApiException('Unexpected response shape.', cause: error);
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> deleteZone(String zoneId) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.delete('/api/SafeZone/$zoneId');
      _zones =
          _zones.where((zone) => zone.id != zoneId).toList(growable: false);
    } on ApiException catch (error) {
      _errorMessage = _getErrorMessage(error);
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  SafeZoneModel _parseZone(dynamic json, {String? childId}) {
    if (json is! Map<String, dynamic>) {
      throw ApiException('Unexpected response shape.');
    }

    try {
      return SafeZoneModel.fromJson(json, childId: childId);
    } on FormatException catch (error) {
      throw ApiException('Unexpected response shape.', cause: error);
    }
  }

  void _replaceZone(SafeZoneModel zone) {
    final index = _zones.indexWhere((item) => item.id == zone.id);
    if (index == -1) {
      return;
    }

    final updatedZones = List<SafeZoneModel>.from(_zones);
    updatedZones[index] = zone;
    _zones = updatedZones;
    notifyListeners();
  }

  String _getErrorMessage(ApiException error) {
    if (error.errorMessages.isNotEmpty) {
      return error.errorMessages.first;
    }

    return error.message;
  }
}
```

## [safezone_screen.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/safezone_screen.dart)
Why this file matters: loads SafeZone list from API and routes to add/edit flows. Relevant lines: 24-38, 74-92, 154-172, 231-247.

This block loads zones for the selected child.

```dart
class _SafeZonesScreenState extends State<SafeZonesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadZones();
    });
  }

  Future<void> _loadZones() async {
    try {
      await context
          .read<SafeZoneProvider>()
          .fetchZonesForChild(widget.child.id);
    } catch (_) {
      if (!mounted) {
        return;
      }
    }
  }
```

This block renders SafeZone loading and error state from the provider.

```dart
Widget _buildBody(SafeZoneProvider provider) {
  if (provider.isLoading) {
    return const Center(child: CircularProgressIndicator());
  }

  if (provider.errorMessage != null && provider.zones.isEmpty) {
    return Center(
      child: Text(
        provider.errorMessage!,
        style: GoogleFonts.cairo(
          fontSize: 14,
          color: AppColors.registerTitle,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  if (provider.zones.isEmpty) {
```

This block opens edit mode for an existing zone and refreshes after return.

```dart
Widget _buildZoneCard(SafeZoneModel zone) {
  return GestureDetector(
    onTap: () async {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NewSafeZoneScreen(
            child: widget.child,
            existingZone: zone,
          ),
        ),
      );

      if (!mounted) {
        return;
      }

      await _loadZones();
    },
```

This block opens add mode and refreshes the API-backed list after return.

```dart
Widget _buildAddButton(BuildContext context) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewSafeZoneScreen(child: widget.child),
          ),
        );

        if (!mounted) {
          return;
        }

        await _loadZones();
      },
```

## [newsafezone_screen.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/newsafezone_screen.dart)
Why this file matters: UI trigger for SafeZone add/update/delete and map selection wiring. Relevant lines: 12-20, 38-56, 70-170, 182-191.

This block makes the screen reusable for both add and edit.

```dart
class NewSafeZoneScreen extends StatefulWidget {
  const NewSafeZoneScreen({
    Key? key,
    required this.child,
    this.existingZone,
  }) : super(key: key);

  final ChildModel child;
  final SafeZoneModel? existingZone;
```

This block preloads existing zone values for edit mode.

```dart
bool get _isEditing => widget.existingZone != null;

@override
void initState() {
  super.initState();

  final zone = widget.existingZone;
  if (zone == null) {
    return;
  }

  _nameController.text = zone.name;
  _radiusController.text = zone.radiusInMeters.toString();
  _selectedType = zone.type;
  _selectedLocation = MapSelectionResult(
    latitude: zone.latitude,
    longitude: zone.longitude,
    label:
        '${zone.latitude.toStringAsFixed(5)}, ${zone.longitude.toStringAsFixed(5)}',
  );
}
```

This block reuses `GoogleMapScreen`, then calls add or update on `SafeZoneProvider`.

```dart
Future<void> _openMap() async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => GoogleMapScreen(child: widget.child),
    ),
  );

  if (result != null && result is MapSelectionResult) {
    setState(() {
      _selectedLocation = result;
      _locationError = false;
    });
  }
}

Future<void> _submitSafeZone() async {
  final name = _nameController.text.trim();
  final radiusText = _radiusController.text.trim();
  final radiusInMeters = int.tryParse(radiusText);

  setState(() {
    _nameError = name.isEmpty;
    _locationError = _selectedLocation == null;
    _radiusError = radiusInMeters == null || radiusInMeters <= 0;
    _typeError = !_isEditing && _selectedType == null;
  });

  if (_nameError || _locationError || _radiusError || _typeError) {
    return;
  }

  try {
    if (_isEditing) {
      await context.read<SafeZoneProvider>().updateZone(
            widget.existingZone!.id,
            name: name,
            latitude: _selectedLocation!.latitude,
            longitude: _selectedLocation!.longitude,
            radiusInMeters: radiusInMeters!,
          );
    } else {
      await context.read<SafeZoneProvider>().addZone(
            childId: widget.child.id,
            name: name,
            latitude: _selectedLocation!.latitude,
            longitude: _selectedLocation!.longitude,
            radiusInMeters: radiusInMeters!,
            type: _selectedType!,
          );
    }

    if (!mounted) {
      return;
    }

    Navigator.pop(context);
  } on ApiException catch (error) {
    _showError(error);
  }
}
```

This block confirms and performs SafeZone delete.

```dart
Future<void> _deleteSafeZone() async {
  final zone = widget.existingZone;
  if (zone == null) {
    return;
  }

  final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('حذف منطقة الامان'),
            content: const Text('هل تريد حذف منطقة الامان هذه؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('حذف'),
              ),
            ],
          );
        },
      ) ??
      false;

  if (!confirmed) {
    return;
  }

  if (!mounted) {
    return;
  }

  try {
    await context.read<SafeZoneProvider>().deleteZone(zone.id);

    if (!mounted) {
      return;
    }

    Navigator.pop(context);
  } on ApiException catch (error) {
    _showError(error);
  }
}
```

This block surfaces backend/API errors from add/update/delete.

```dart
void _showError(ApiException error) {
  if (!mounted) {
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        error.errorMessages.isNotEmpty
            ? error.errorMessages.first
            : error.message,
      ),
    ),
  );
}
```

## [google_map.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/google_map.dart)
Why this file matters: returns the selected coordinates used in SafeZone add/edit payloads. Relevant lines: 11-21, 233-248.

This block defines the map-selection result used by `newsafezone_screen.dart`.

```dart
class MapSelectionResult {
  const MapSelectionResult({
    required this.latitude,
    required this.longitude,
    required this.label,
  });

  final double latitude;
  final double longitude;
  final String label;
}
```

This block returns the selected coordinates to the SafeZone form.

```dart
onPressed: () {
  final selectedPosition = _selectedPosition;
  final selectedAddress = _selectedAddress;
  if (selectedPosition == null ||
      selectedAddress == null) {
    return;
  }

  Navigator.pop(
    context,
    MapSelectionResult(
      latitude: selectedPosition.latitude,
      longitude: selectedPosition.longitude,
      label: selectedAddress,
    ),
  );
},
```

## [splash_screen.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/splash_screen.dart)
Why this file matters: startup session restore, launch-state routing, and token validation. Relevant lines: 61-129.

This block restores launch state and validates the stored token before authenticated navigation.

```dart
Future<void> _checkAndNavigate() async {
  if (_isCheckingSession) {
    return;
  }

  setState(() {
    _isCheckingSession = true;
    _statusMessage = null;
    _canRetry = false;
  });

  await SharedPrefs.init();
  final splashDelay = Future<void>.delayed(_minimumSplashDuration);

  try {
    final hasRegistered = SharedPrefs.hasRegistered;
    final isLoggedIn = SharedPrefs.isLoggedIn;

    Widget nextScreen;

    if (!hasRegistered) {
      nextScreen = const OnboardingScreen1();
    } else if (!isLoggedIn) {
      nextScreen = const LoginScreen();
    } else {
      if (!mounted) {
        return;
      }

      final authProvider = context.read<AuthProvider>();
      final isTokenValid = await authProvider.validateStoredToken();

      if (!isTokenValid) {
        nextScreen = const LoginScreen();
      } else {
        nextScreen = const HomeScreen();
      }
    }

    await splashDelay;

    if (!mounted) {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  } on ApiException catch (error) {
    await splashDelay;

    if (!mounted) {
      return;
    }

    setState(() {
      _statusMessage = error.errorMessages.isNotEmpty
          ? error.errorMessages.join('\n')
          : error.message;
      _canRetry = true;
    });
  } finally {
    if (mounted) {
      setState(() {
        _isCheckingSession = false;
      });
    }
  }
}
```

## [main.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/main.dart)
Why this file matters: startup initialization, provider registration, and root navigator/scaffold keys for global 401 handling. Relevant lines: 13-48.

This block initializes shared prefs before app startup and registers the auth/child/safezone providers.

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPrefs.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChildProvider()),
        ChangeNotifierProvider(create: (_) => SafeZoneProvider()),
        // ✅ إضافة NotificationsProvider
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
        ChangeNotifierProvider(create: (_) => ChatbotProvider()),
      ],
      child: const MyApp(),
    ),
  );
}
```

This block attaches the root keys used by global unauthorized handling and starts on `SplashScreen`.

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: ApiService.navigatorKey,
      scaffoldMessengerKey: ApiService.scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'Malaz App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.cairoTextTheme(),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
```

# 3) Endpoint-to-Code Mapping Table

| Endpoint | Implemented in which file(s) | Method/function name | Request model/body source | Response model/parser source | UI trigger source | Status | Notes |
|---|---|---|---|---|---|---|---|
| `POST /Auth/login` | [auth_provider.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/providers/auth_provider.dart), [login_screen.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/login_screen.dart) | `_loginRequest`, `login`, `_handleLogin` | Inline body in `_loginRequest` | `_requireMap`, `_requireString`, `UserModel(...)` | `_handleLogin()` | Implemented | Parses top-level `user` and `token` |
| `POST /Auth/register` | [auth_provider.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/providers/auth_provider.dart), [register_screen.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/register_screen.dart) | `_registerRequest`, `register`, `_handleRegister` | Inline body in `_registerRequest` | `_requireMap(response.rawBody)` + success check | `_handleRegister()` | Implemented | On success it immediately calls `_loginRequest()` for JWT |
| `POST /Child/addchild` | [child_provider.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/providers/child_provider.dart), [add_child_screen.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/add_child_screen.dart) | `addChild`, `_handleAddChild` | Inline body in `ChildProvider.addChild` | `_parseChildFromResponse` + `ChildModel.fromJson` | `_handleAddChild()` | Implemented | QA shows Flutter request is correct; backend save currently fails |
| `GET /Child/mychildren` | [child_provider.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/providers/child_provider.dart), [home_screen.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/home_screen.dart), [auth_provider.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/providers/auth_provider.dart), [splash_screen.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/splash_screen.dart) | `fetchMyChildren`, `validateStoredToken` | No body | `_requireList` + `ChildModel.fromJson` | `HomeScreen.initState`, `SplashScreen._checkAndNavigate` | Implemented | Also reused as grounded token-validation call |
| `GET /Child/{id}` | [child_provider.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/providers/child_provider.dart), [child_details_screen.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/child_details_screen.dart) | `fetchChildById` | Path param | `_parseChildFromResponse` + `ChildModel.fromJson` | `ChildDetailsScreen.initState` | Implemented | Uses cached `initialData` until fetch completes |
| `POST /api/SafeZone/add` | [safezone_provider.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/providers/safezone_provider.dart), [newsafezone_screen.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/newsafezone_screen.dart), [google_map.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/google_map.dart) | `addZone`, `_submitSafeZone` | Inline body in `SafeZoneProvider.addZone` | `_parseZone` + `SafeZoneModel.fromJson` | `_submitSafeZone()` add branch | Implemented | Coordinates come from `MapSelectionResult` |
| `GET /api/SafeZone/child/{id}` | [safezone_provider.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/providers/safezone_provider.dart), [safezone_screen.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/safezone_screen.dart) | `fetchZonesForChild`, `_loadZones` | No body | `_parseZone` + `SafeZoneModel.fromJson` | `SafeZonesScreen.initState`, refresh after add/edit/delete | Implemented | Refreshes after navigation returns |
| `GET /api/SafeZone/{id}` | [safezone_provider.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/providers/safezone_provider.dart) | `fetchZone` | Path param | `_parseZone` + `SafeZoneModel.fromJson` | No current screen caller | Implemented | Provider-level implementation exists; no dedicated UI caller |
| `PUT /api/SafeZone/{id}` | [safezone_provider.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/providers/safezone_provider.dart), [newsafezone_screen.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/newsafezone_screen.dart) | `updateZone`, `_submitSafeZone` | Inline body in `SafeZoneProvider.updateZone` | `_parseZone` + `SafeZoneModel.fromJson` | `_submitSafeZone()` edit branch | Implemented | Uses exact capitalized request keys |
| `DELETE /api/SafeZone/{id}` | [safezone_provider.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/providers/safezone_provider.dart), [newsafezone_screen.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/newsafezone_screen.dart) | `deleteZone`, `_deleteSafeZone` | No body | No body parser needed | `_deleteSafeZone()` | Implemented | Includes confirmation dialog |

# 4) Contract Match Check

- `Base URL`: Pass. Code uses `https://malaz.runasp.net` in [api_service.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/services/api_service.dart).
- `Auth and Child endpoints without /api prefix`: Pass. Code uses `/Auth/...` and `/Child/...` exactly.
- `SafeZone endpoints with /api prefix`: Pass. Code uses `/api/SafeZone/...` exactly.

- `POST /Auth/login`
  - URL path: Pass
  - Method: Pass
  - Auth requirement: Pass, unauthenticated
  - Request keys: Pass, `{email, password}`
  - Response parsing: Partial
  - Code correctly reads top-level `user` and top-level `token`
  - Code does not rely on ungrounded nested `user.success` or `user.errorMessages`
  - `roles[]` from the contract is not modeled or stored

- `POST /Auth/register`
  - URL path: Pass
  - Method: Pass
  - Auth requirement: Pass, unauthenticated
  - Request keys: Pass, `{userName, email, password, confirmPassword}`
  - `phone` excluded from request: Pass
  - Does not assume returned token: Pass
  - Auto-login after register: Pass
  - Response parsing: Partial
  - Code verifies `success` but does not model returned `id`, `name`, `email`

- `POST /Child/addchild`
  - URL path: Pass
  - Method: Pass
  - Auth requirement: Pass, Bearer attached by `ApiService`
  - Request keys: Pass, `{name, birthDate, gender, deviceId}`
  - `userId` omitted: Pass
  - `gender` as `int`: Pass
  - `birthDate` / `deviceId` camelCase: Pass
  - Response parsing: Pass, parses grounded child fields from `data`

- `GET /Child/mychildren`
  - URL path: Pass
  - Method: Pass
  - Auth requirement: Pass
  - Response parsing: Pass, parses envelope `data[]` into `ChildModel`
  - `birthDate` normalization from ISO datetime to `YYYY-MM-DD`: Pass

- `GET /Child/{id}`
  - URL path: Pass
  - Method: Pass
  - Auth requirement: Pass
  - Response parsing: Pass

- `POST /api/SafeZone/add`
  - URL path: Pass
  - Method: Pass
  - Auth requirement: Pass
  - Request keys: Pass, `{childId, name, latitude, longitude, radiusInMeters, type}`
  - `type` as `int`: Pass
  - Response parsing: Pass, grounded fields only

- `GET /api/SafeZone/child/{id}`
  - URL path: Pass
  - Method: Pass
  - Auth requirement: Pass
  - Response parsing: Pass, grounded list item fields only

- `GET /api/SafeZone/{id}`
  - URL path: Pass
  - Method: Pass
  - Auth requirement: Pass
  - Response parsing: Pass

- `PUT /api/SafeZone/{id}`
  - URL path: Pass
  - Method: Pass
  - Auth requirement: Pass
  - Request keys: Pass, exact `{Name, Latitude, Longitude, RadiusInMeters}`
  - Response parsing: Pass

- `DELETE /api/SafeZone/{id}`
  - URL path: Pass
  - Method: Pass
  - Auth requirement: Pass
  - Response parsing: Pass, no body parsing required

# 5) Known Gaps / Mismatches

- [user_model.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/models/user_model.dart)
  - `roles[]` from the login contract is still not modeled.
  - `fromJson()` still expects `phone` and `token` keys that are not part of the nested login `user` object.

- [child_provider.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/providers/child_provider.dart), [safezone_provider.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/providers/safezone_provider.dart), [newsafezone_screen.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/newsafezone_screen.dart)
  - Some flows still surface only `errorMessages.first` instead of the full backend `errorMessages[]` array.

- `POST /Child/addchild`
  - Flutter-side wiring appears correct.
  - Current QA result shows a backend failure envelope:
    - `success: false`
    - `"An error occurred while saving the entity changes..."`
  - This is a backend-blocked issue, not a Flutter request-contract issue.

- `GET /api/SafeZone/{id}`
  - Implemented in [safezone_provider.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/providers/safezone_provider.dart)
  - No current screen calls `fetchZone(zoneId)` directly
  - Provider implementation exists; current UI relies on list item data for edit flow

- No remaining mock networking was found in the integration service/providers:
  - no `Future.delayed()` mock request paths
  - no fake JWT generation
  - no fake child/safezone provider data paths in the integration files

# 6) Final “Bring This To ChatGPT” Section

## BRING THIS TO CHATGPT

### A) Final status summary in plain English
Flutter-side API integration is implemented across TG0-TG4 using the grounded Postman contracts and the repo’s scoped files. Auth, Child, SafeZone CRUD, token persistence, splash/session restore, and global unauthorized handling all exist in code. The main remaining code-level non-blockers are missing `roles[]` modeling and partial `errorMessages[]` surfacing outside auth/splash. `POST /Child/addchild` is currently backend-blocked in QA despite a correct Flutter request.

### B) The exact list of files that contain the integration code
- [shared_prefs.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/helpers/shared_prefs.dart)
- [api_service.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/services/api_service.dart)
- [user_model.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/models/user_model.dart)
- [child_mode.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/models/child_mode.dart)
- [safe_zone_model.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/models/safe_zone_model.dart)
- [auth_provider.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/providers/auth_provider.dart)
- [child_provider.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/providers/child_provider.dart)
- [safezone_provider.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/providers/safezone_provider.dart)
- [login_screen.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/login_screen.dart)
- [register_screen.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/register_screen.dart)
- [add_child_screen.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/add_child_screen.dart)
- [home_screen.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/home_screen.dart)
- [child_details_screen.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/child_details_screen.dart)
- [safezone_screen.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/safezone_screen.dart)
- [newsafezone_screen.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/newsafezone_screen.dart)
- [google_map.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/google_map.dart)
- [splash_screen.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/splash_screen.dart)
- [main.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/main.dart)

### C) The exact extracted code blocks, grouped by file
Use the grouped exact code blocks in Section 2 for these files:
- [shared_prefs.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/helpers/shared_prefs.dart)
- [api_service.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/services/api_service.dart)
- [user_model.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/models/user_model.dart)
- [auth_provider.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/providers/auth_provider.dart)
- [login_screen.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/login_screen.dart)
- [register_screen.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/register_screen.dart)
- [child_mode.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/models/child_mode.dart)
- [child_provider.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/providers/child_provider.dart)
- [add_child_screen.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/add_child_screen.dart)
- [home_screen.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/home_screen.dart)
- [child_details_screen.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/child_details_screen.dart)
- [safe_zone_model.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/models/safe_zone_model.dart)
- [safezone_provider.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/providers/safezone_provider.dart)
- [safezone_screen.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/safezone_screen.dart)
- [newsafezone_screen.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/newsafezone_screen.dart)
- [google_map.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/google_map.dart)
- [splash_screen.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/screens/splash_screen.dart)
- [main.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/main.dart)

### D) The top remaining blockers
- Backend save/persistence failure on `POST /Child/addchild` despite correct Flutter request and valid Bearer token

### E) The top remaining non-blocker cleanup items
- Add `roles[]` support to [user_model.dart](C:/Users/Alios/OneDrive/Desktop/My%20Grad..%20project/Malaz-Flutter/lib/models/user_model.dart)
- Standardize Child/SafeZone error surfacing to show full backend `errorMessages[]` instead of only the first item