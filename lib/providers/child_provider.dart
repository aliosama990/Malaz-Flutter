import 'package:flutter/material.dart';
import 'package:malaz_app/models/alert_setting_model.dart';
import 'package:malaz_app/models/child_mode.dart';

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
      _errorMessage = _getApiErrorMessage(error);
      return null;
    } catch (e) {
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
    } on FormatException {
      throw ApiException(
        'Unexpected response shape.',
        statusCode: response.statusCode,
        responseBody: response.rawBody,
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
}
