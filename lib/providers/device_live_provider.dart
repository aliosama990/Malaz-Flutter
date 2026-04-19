import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/device_live_models.dart';
import '../services/device_hub_service.dart';

class DeviceLiveProvider extends ChangeNotifier {
  static const Duration _staleReadingThreshold = Duration(minutes: 1);
  static const int _recentReadingLimit = 5;
  static const int _recentAlertLimit = 5;

  DeviceLiveProvider({DeviceHubService? deviceHubService})
      : _deviceHubService = deviceHubService ?? DeviceHubService();

  final DeviceHubService _deviceHubService;

  DeviceReading? _latestReading;
  DeviceAlert? _latestAlert;
  List<DeviceReading> _recentReadings = const <DeviceReading>[];
  List<DeviceAlert> _recentAlerts = const <DeviceAlert>[];
  DeviceHubConnectionStatus _connectionStatus =
      DeviceHubConnectionStatus.disconnected;
  String? _currentDeviceId;
  String? _errorMessage;
  bool _isReadingStale = false;
  bool _isDisposed = false;
  int _connectionRequestId = 0;
  Timer? _staleReadingTimer;

  DeviceReading? get latestReading => _latestReading;
  DeviceAlert? get latestAlert => _latestAlert;
  List<DeviceReading> get recentReadings => List<DeviceReading>.unmodifiable(
        _recentReadings,
      );
  List<DeviceAlert> get recentAlerts => List<DeviceAlert>.unmodifiable(
        _recentAlerts,
      );
  DeviceHubConnectionStatus get connectionStatus => _connectionStatus;
  String? get currentDeviceId => _currentDeviceId;
  String? get errorMessage => _errorMessage;
  bool get isReadingStale => _isReadingStale;
  DateTime? get lastReadingReceivedAt => _latestReading?.receivedAt;

  bool get isConnected =>
      _connectionStatus == DeviceHubConnectionStatus.connected;
  bool get isConnecting =>
      _connectionStatus == DeviceHubConnectionStatus.connecting ||
      _connectionStatus == DeviceHubConnectionStatus.reconnecting;

  Future<void> connectToDevice(String deviceId) async {
    final requestId = ++_connectionRequestId;
    final normalizedDeviceId = deviceId.trim();
    if (normalizedDeviceId.isEmpty) {
      _currentDeviceId = null;
      _clearLiveData();
      _errorMessage = 'لا يوجد جهاز مرتبط بهذا الطفل.';
      _connectionStatus = DeviceHubConnectionStatus.disconnected;
      await _deviceHubService.disconnect();
      if (_isCurrentRequest(requestId)) {
        _notifyListenersSafely();
      }
      return;
    }

    if (_currentDeviceId == normalizedDeviceId &&
        (_connectionStatus == DeviceHubConnectionStatus.connected ||
            _connectionStatus == DeviceHubConnectionStatus.connecting ||
            _connectionStatus == DeviceHubConnectionStatus.reconnecting)) {
      return;
    }

    final deviceChanged = _currentDeviceId != normalizedDeviceId;
    _currentDeviceId = normalizedDeviceId;
    if (deviceChanged) {
      _clearLiveData();
    }
    _errorMessage = null;
    _connectionStatus = DeviceHubConnectionStatus.connecting;
    _notifyListenersSafely();

    try {
      await _deviceHubService.connectAndSubscribe(
        deviceId: normalizedDeviceId,
        onReading: (reading) {
          if (!_isCurrentRequest(requestId)) {
            return;
          }

          _handleIncomingReading(reading);
        },
        onAlert: (alert) {
          if (!_isCurrentRequest(requestId)) {
            return;
          }

          _handleIncomingAlert(alert);
        },
        onConnectionStatusChanged: (status, {error}) {
          if (!_isCurrentRequest(requestId)) {
            return;
          }

          _handleConnectionStatusChanged(
            status,
            error: error,
          );
        },
      );
    } catch (_) {
      if (!_isCurrentRequest(requestId)) {
        return;
      }

      _errorMessage = 'تعذر الاتصال المباشر بالجهاز.';
      _connectionStatus = DeviceHubConnectionStatus.disconnected;
      _notifyListenersSafely();
    }
  }

  Future<void> disconnect() async {
    _connectionRequestId++;
    _currentDeviceId = null;
    _clearLiveData();
    _connectionStatus = DeviceHubConnectionStatus.disconnected;
    _errorMessage = null;
    await _deviceHubService.disconnect();
    _notifyListenersSafely();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _connectionRequestId++;
    _staleReadingTimer?.cancel();
    _deviceHubService.clearCallbacks();
    unawaited(_deviceHubService.dispose());
    super.dispose();
  }

  void _handleIncomingReading(DeviceReading reading) {
    final currentDeviceId = _currentDeviceId;
    final incomingDeviceId = reading.deviceId?.trim();
    if (currentDeviceId != null &&
        incomingDeviceId != null &&
        incomingDeviceId.isNotEmpty &&
        incomingDeviceId != currentDeviceId) {
      return;
    }

    _latestReading = reading;
    _recentReadings = _pushHistoryItem(
      _recentReadings,
      reading,
      _recentReadingLimit,
    );
    _isReadingStale = false;
    _scheduleStaleReadingTimer(reading.receivedAt);
    _errorMessage = null;
    _notifyListenersSafely();
  }

  void _handleIncomingAlert(DeviceAlert alert) {
    final currentDeviceId = _currentDeviceId;
    final incomingDeviceId = alert.deviceId?.trim();
    if (currentDeviceId != null &&
        incomingDeviceId != null &&
        incomingDeviceId.isNotEmpty &&
        incomingDeviceId != currentDeviceId) {
      return;
    }

    _latestAlert = alert;
    _recentAlerts = _pushHistoryItem(
      _recentAlerts,
      alert,
      _recentAlertLimit,
    );
    _notifyListenersSafely();
  }

  void _handleConnectionStatusChanged(
    DeviceHubConnectionStatus status, {
    Object? error,
  }) {
    _connectionStatus = status;
    if (status == DeviceHubConnectionStatus.connected) {
      _errorMessage = null;
    } else if (error != null && _currentDeviceId != null) {
      _errorMessage = 'تعذر الاتصال المباشر بالجهاز.';
    }

    _notifyListenersSafely();
  }

  void _clearLiveData() {
    _latestReading = null;
    _latestAlert = null;
    _recentReadings = const <DeviceReading>[];
    _recentAlerts = const <DeviceAlert>[];
    _isReadingStale = false;
    _staleReadingTimer?.cancel();
    _staleReadingTimer = null;
  }

  void _scheduleStaleReadingTimer(DateTime receivedAt) {
    _staleReadingTimer?.cancel();
    _staleReadingTimer = Timer(_staleReadingThreshold, () {
      if (_isDisposed) {
        return;
      }

      final latestReading = _latestReading;
      if (latestReading == null || latestReading.receivedAt != receivedAt) {
        return;
      }

      _isReadingStale = true;
      _notifyListenersSafely();
    });
  }

  bool _isCurrentRequest(int requestId) {
    return !_isDisposed && _connectionRequestId == requestId;
  }

  List<T> _pushHistoryItem<T>(List<T> currentItems, T newItem, int maxItems) {
    final nextItems = <T>[newItem, ...currentItems];
    if (nextItems.length > maxItems) {
      return nextItems.sublist(0, maxItems);
    }

    return nextItems;
  }

  void _notifyListenersSafely() {
    if (_isDisposed) {
      return;
    }

    notifyListeners();
  }
}
