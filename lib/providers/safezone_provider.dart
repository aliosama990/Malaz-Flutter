import 'package:flutter/foundation.dart';

import '../models/safe_zone_model.dart';
import '../services/api_service.dart';

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
      return error.errorMessages.join('\n');
    }

    return error.message;
  }
}
