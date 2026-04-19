import 'package:flutter/material.dart';
import 'package:malaz_app/models/alert_setting_model.dart';
import 'package:malaz_app/models/child_mode.dart';

import '../constants/app_strings.dart';
import '../services/api_service.dart';

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
    required ChildCondition condition,
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
          'Condition': condition.apiValue,
        },
      );

      final newChild = _parseChildFromResponse(response);

      updateChild(newChild);
      return true;
    } on ApiException catch (error) {
      _debugLogChildMutationError('addChild', error);
      _errorMessage = _getChildMutationErrorMessage(error);
      return false;
    } catch (error, stackTrace) {
      _debugLogChildMutationError('addChild', error, stackTrace: stackTrace);
      _errorMessage = AppStrings.addChildError;
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
          .toList();
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

  Future<AlertSettingModel?> fetchAlertSetting(String childId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/Child/$childId/alert-setting');
      return _parseAlertSettingFromResponse(response);
    } on ApiException catch (error) {
      _errorMessage = _getApiErrorMessage(error);
      return null;
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء جلب إعدادات التنبيه';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ChildModel?> updateChildDetails({
    required String childId,
    required String name,
    required String birthDate,
    required int gender,
    required String deviceId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.put(
        '/Child/update/$childId',
        body: {
          'name': name,
          'birthDate': birthDate,
          'gender': gender,
          'deviceId': deviceId,
        },
      );

      final updatedChild = _parseChildFromResponse(response);
      updateChild(updatedChild);
      return updatedChild;
    } on ApiException catch (error) {
      _debugLogChildMutationError('updateChildDetails', error);
      _errorMessage = _getChildMutationErrorMessage(error);
      return null;
    } catch (error, stackTrace) {
      _debugLogChildMutationError(
        'updateChildDetails',
        error,
        stackTrace: stackTrace,
      );
      _errorMessage = 'حدث خطأ أثناء تحديث بيانات الطفل';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateAlertSetting(
    String childId,
    AlertSettingModel alertSetting,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.put(
        '/Child/$childId/alert-setting',
        body: alertSetting.toJson(),
      );
      return true;
    } on ApiException catch (error) {
      _errorMessage = _getApiErrorMessage(error);
      return false;
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء حفظ إعدادات التنبيه';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteChildFromServer(String childId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.delete('/Child/delete/$childId');
      removeChild(childId);
      return true;
    } on ApiException catch (error) {
      _errorMessage = _getApiErrorMessage(error);
      return false;
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء حذف الطفل';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateChild(ChildModel updatedChild) {
    final index = _children.indexWhere((c) => c.id == updatedChild.id);
    if (index != -1) {
      _children[index] = updatedChild;
    } else {
      _children.add(updatedChild);
    }
    notifyListeners();
  }

  ChildModel? getChildById(String childId) {
    try {
      return _children.firstWhere((child) => child.id == childId);
    } catch (e) {
      return null;
    }
  }

  void removeChild(String childId) {
    _children.removeWhere((child) => child.id == childId);
    notifyListeners();
  }

  void clearChildren() {
    _children.clear();
    notifyListeners();
  }

  ChildModel _parseChildFromResponse(ApiResponse response) {
    try {
      return ChildModel.fromJson(_requireMap(response.data));
    } on FormatException catch (error) {
      throw ApiException(
        'Unexpected response shape: ${error.message}',
        statusCode: response.statusCode,
        responseBody: response.rawBody,
        cause: error,
      );
    }
  }

  AlertSettingModel _parseAlertSettingFromResponse(ApiResponse response) {
    try {
      return AlertSettingModel.fromJson(_requireMap(response.data));
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
      return error.errorMessages.join('\n');
    }
    return error.message;
  }

  String _getChildMutationErrorMessage(ApiException error) {
    final technicalDetails = _buildTechnicalErrorDetails(error);
    final normalizedDetails = technicalDetails.toLowerCase();

    if (_isDuplicateDeviceError(normalizedDetails)) {
      return AppStrings.childDeviceAlreadyLinkedError;
    }

    if (_containsAny(normalizedDetails, const [
      'unexpected response shape',
      'invalid child field',
      'invalid child response map',
      'invalid child response list',
      'formatexception',
    ])) {
      return AppStrings.childResponseReadError;
    }

    if (_containsAny(normalizedDetails, const [
      'validation',
      'one or more validation errors',
      'invalid',
      'required',
      'must not be empty',
      'must not be null',
      'must be',
    ])) {
      return AppStrings.childValidationError;
    }

    if (_containsAny(normalizedDetails, const [
      'save',
      'saving',
      'dbupdate',
      'database',
      'sql',
      'entity changes',
    ])) {
      return AppStrings.childSaveFailedError;
    }

    final displayMessage = _getApiErrorMessage(error);
    if (_containsArabic(displayMessage)) {
      return displayMessage;
    }

    return AppStrings.addChildError;
  }

  String _buildTechnicalErrorDetails(ApiException error) {
    final parts = <String>[
      error.message,
      if (error.errorMessages.isNotEmpty) error.errorMessages.join('\n'),
      if (error.responseBody != null) error.responseBody.toString(),
      if (error.cause != null) error.cause.toString(),
    ];

    return parts.where((part) => part.trim().isNotEmpty).join('\n');
  }

  bool _isDuplicateDeviceError(String message) {
    const duplicateTerms = <String>[
      'duplicate',
      'already exists',
      'already assigned',
      'already linked',
      'in use',
      'used before',
      'unique',
    ];
    const deviceTerms = <String>[
      'device',
      'deviceid',
      'device id',
      'serial',
      'serial number',
    ];

    return (_containsAny(message, duplicateTerms) &&
            _containsAny(message, deviceTerms)) ||
        _containsAny(message, const [
          'serial number already exists',
          'deviceid already exists',
          'device already exists',
        ]);
  }

  bool _containsAny(String message, List<String> patterns) {
    for (final pattern in patterns) {
      if (message.contains(pattern)) {
        return true;
      }
    }

    return false;
  }

  bool _containsArabic(String message) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(message);
  }

  void _debugLogChildMutationError(
    String operation,
    Object error, {
    StackTrace? stackTrace,
  }) {
    assert(() {
      debugPrint('[$operation] child mutation error: $error');
      if (error is ApiException) {
        debugPrint('[$operation] statusCode: ${error.statusCode}');
        debugPrint('[$operation] errorMessages: ${error.errorMessages}');
        debugPrint('[$operation] responseBody: ${error.responseBody}');
        debugPrint('[$operation] cause: ${error.cause}');
      }
      if (stackTrace != null) {
        debugPrintStack(
          stackTrace: stackTrace,
          label: '[$operation] stackTrace',
        );
      }
      return true;
    }());
  }
}
