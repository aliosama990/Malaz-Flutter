import 'package:flutter/foundation.dart';

import '../models/safe_zone_model.dart';
import '../services/api_service.dart';
import '../utils/user_error_messages.dart';

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
      _errorMessage = UserErrorMessages.dataLoadError;
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
      _errorMessage = UserErrorMessages.dataLoadError;
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
      final requestBody = <String, dynamic>{
        'childId': childId,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'radiusInMeters': radiusInMeters,
        'type': type,
      };
      final response = await _apiService.post(
        '/api/SafeZone/add',
        body: requestBody,
      );

      final zone = await _resolveAddedZone(
        response.data,
        childId: childId,
        name: name,
        latitude: latitude,
        longitude: longitude,
        radiusInMeters: radiusInMeters,
        type: type,
      );

      if (_activeChildId == childId &&
          !_zones.any((existingZone) => existingZone.id == zone.id)) {
        _zones = <SafeZoneModel>[..._zones, zone];
      }
      return zone;
    } on ApiException catch (error) {
      _errorMessage = _getErrorMessage(error);
      rethrow;
    } catch (error) {
      _errorMessage = UserErrorMessages.dataLoadError;
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
      _errorMessage = UserErrorMessages.dataLoadError;
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
    if (json is! Map) {
      throw ApiException('Unexpected response shape.');
    }

    try {
      return SafeZoneModel.fromJson(
        Map<String, dynamic>.from(json),
        childId: childId,
      );
    } on FormatException catch (error) {
      throw ApiException('Unexpected response shape.', cause: error);
    }
  }

  Future<SafeZoneModel> _resolveAddedZone(
    dynamic responseData, {
    required String childId,
    required String name,
    required double latitude,
    required double longitude,
    required int radiusInMeters,
    required int type,
  }) async {
    final parsedZone = _tryParseZone(responseData, childId: childId);
    if (parsedZone != null) {
      return parsedZone;
    }

    final responseZoneId = _readZoneId(responseData);
    if (responseZoneId != null) {
      try {
        return await fetchZone(responseZoneId);
      } on ApiException {
        // Some add responses only acknowledge creation; fall through to list refresh.
      }
    }

    final refreshedZones = await fetchZonesForChild(childId);
    final matchingZone = _findMatchingZone(
      refreshedZones,
      name: name,
      latitude: latitude,
      longitude: longitude,
      radiusInMeters: radiusInMeters,
      type: type,
    );

    if (matchingZone != null) {
      return matchingZone;
    }

    throw ApiException('Unexpected response shape.');
  }

  SafeZoneModel? _tryParseZone(dynamic json, {String? childId}) {
    try {
      return _parseZone(json, childId: childId);
    } on ApiException {
      return null;
    }
  }

  String? _readZoneId(dynamic responseData) {
    if (responseData is String && _looksLikeGuid(responseData)) {
      return responseData.trim();
    }

    if (responseData is! Map) {
      return null;
    }

    final json = Map<String, dynamic>.from(responseData);
    for (final key in const [
      'id',
      'Id',
      'zoneId',
      'ZoneId',
      'safeZoneId',
      'SafeZoneId'
    ]) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return null;
  }

  bool _looksLikeGuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value.trim());
  }

  SafeZoneModel? _findMatchingZone(
    List<SafeZoneModel> zones, {
    required String name,
    required double latitude,
    required double longitude,
    required int radiusInMeters,
    required int type,
  }) {
    for (final zone in zones) {
      if (zone.name.trim() == name.trim() &&
          zone.radiusInMeters == radiusInMeters &&
          zone.type == type &&
          _isCloseCoordinate(zone.latitude, latitude) &&
          _isCloseCoordinate(zone.longitude, longitude)) {
        return zone;
      }
    }

    return null;
  }

  bool _isCloseCoordinate(double first, double second) {
    return (first - second).abs() < 0.000001;
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
    return UserErrorMessages.fromApiException(
      error,
      fallback: UserErrorMessages.dataLoadError,
    );
  }
}
