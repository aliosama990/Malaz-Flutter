import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../helpers/shared_prefs.dart';

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
      final details = <String>[
        'SocketException',
        'osError: ${error.osError}',
        'address: ${error.address}',
        'port: ${error.port}',
        'exception: $error',
      ].join('\n');

      throw ApiException(
        'تعذر الاتصال بالإنترنت. تفاصيل الاتصال:\n$details',
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

  String _defaultStatusMessage(int statusCode) {
    if (statusCode == 401) {
      return 'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى.';
    }

    return 'فشل الطلب برمز الحالة $statusCode.';
  }

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

  void dispose() {
    _client.close();
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
    return errorMessages.join('\n');
  }

  factory ApiResponse.fromHttpResponse(http.Response response) {
    final parsedBody = _parseBody(response);
    final envelope = parsedBody is Map<String, dynamic>
        ? _tryReadEnvelope(parsedBody)
        : null;

    if (parsedBody is Map<String, dynamic> && envelope != null) {
      return ApiResponse(
        statusCode: response.statusCode,
        success: envelope.success,
        hasEnvelope: true,
        errorMessages: envelope.errorMessages,
        data: envelope.data,
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

  static _EnvelopeData? _tryReadEnvelope(Map<String, dynamic> json) {
    const successKeys = <String>['success', 'Success'];
    const errorMessageKeys = <String>['errorMessages', 'ErrorMessages'];
    const dataKeys = <String>['data', 'Data'];
    final hasEnvelope = successKeys.any(json.containsKey) ||
        errorMessageKeys.any(json.containsKey) ||
        dataKeys.any(json.containsKey);

    if (!hasEnvelope) {
      return null;
    }

    return _EnvelopeData(
      success: _readFirstValue(json, successKeys) == true,
      errorMessages:
          _normalizeErrorMessages(_readFirstValue(json, errorMessageKeys)),
      data: _readFirstValue(json, dataKeys),
    );
  }

  static dynamic _readFirstValue(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      if (json.containsKey(key)) {
        return json[key];
      }
    }

    return null;
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

  @override
  String toString() {
    return 'ApiException(message: $message, statusCode: $statusCode, errorMessages: $errorMessages)';
  }
}

class _EnvelopeData {
  const _EnvelopeData({
    required this.success,
    required this.errorMessages,
    required this.data,
  });

  final bool success;
  final List<String> errorMessages;
  final dynamic data;
}
