import 'dart:async';

import 'package:signalr_core/signalr_core.dart';

import '../models/device_live_models.dart';

enum DeviceHubConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

typedef DeviceReadingCallback = void Function(DeviceReading reading);
typedef DeviceAlertCallback = void Function(DeviceAlert alert);
typedef DeviceConnectionStatusCallback = void Function(
  DeviceHubConnectionStatus status, {
  Object? error,
});

class DeviceHubService {
  static const String _hubUrl = 'https://malaz.runasp.net/hubs/device';

  HubConnection? _connection;
  int _connectionGeneration = 0;
  String? _subscribedDeviceId;
  DeviceReadingCallback? _onReading;
  DeviceAlertCallback? _onAlert;
  DeviceConnectionStatusCallback? _onConnectionStatusChanged;

  Future<void> connectAndSubscribe({
    required String deviceId,
    required DeviceReadingCallback onReading,
    required DeviceAlertCallback onAlert,
    required DeviceConnectionStatusCallback onConnectionStatusChanged,
  }) async {
    final normalizedDeviceId = deviceId.trim();
    if (normalizedDeviceId.isEmpty) {
      return;
    }

    _onReading = onReading;
    _onAlert = onAlert;
    _onConnectionStatusChanged = onConnectionStatusChanged;

    final existingConnection = _connection;
    if (existingConnection != null &&
        _subscribedDeviceId == normalizedDeviceId &&
        existingConnection.state == HubConnectionState.connected) {
      _emitStatus(DeviceHubConnectionStatus.connected);
      return;
    }

    final generation = ++_connectionGeneration;
    _subscribedDeviceId = normalizedDeviceId;
    await _stopConnection(
      clearDeviceId: false,
      emitDisconnected: false,
    );

    final connection = HubConnectionBuilder()
        .withUrl(_hubUrl)
        .withAutomaticReconnect()
        .build();

    _connection = connection;
    _registerHandlers(connection, generation);
    _emitStatus(DeviceHubConnectionStatus.connecting);

    try {
      final startFuture = connection.start();
      if (startFuture != null) {
        await startFuture;
      }
      await _subscribeToCurrentDevice(
        connection: connection,
        generation: generation,
      );
      if (_isActiveConnection(connection, generation)) {
        _emitStatus(DeviceHubConnectionStatus.connected);
      }
    } catch (error) {
      if (_isActiveConnection(connection, generation)) {
        _emitStatus(DeviceHubConnectionStatus.disconnected, error: error);
      }
      await _stopConnection(
        clearDeviceId: false,
        emitDisconnected: false,
      );
      rethrow;
    }
  }

  void clearCallbacks() {
    _onReading = null;
    _onAlert = null;
    _onConnectionStatusChanged = null;
  }

  Future<void> disconnect() {
    _connectionGeneration++;
    return _stopConnection(
      clearDeviceId: true,
      emitDisconnected: true,
    );
  }

  Future<void> dispose() {
    clearCallbacks();
    return disconnect();
  }

  void _registerHandlers(HubConnection connection, int generation) {
    connection.on('ReceiveDeviceReading', (arguments) {
      if (!_isActiveConnection(connection, generation)) {
        return;
      }

      _handleReceiveDeviceReading(arguments);
    });

    connection.on('ReceiveAlert', (arguments) {
      if (!_isActiveConnection(connection, generation)) {
        return;
      }

      _handleReceiveAlert(arguments);
    });

    connection.onclose((error) {
      if (!_isActiveConnection(connection, generation)) {
        return;
      }

      _emitStatus(DeviceHubConnectionStatus.disconnected, error: error);
    });

    connection.onreconnecting((error) {
      if (!_isActiveConnection(connection, generation)) {
        return;
      }

      _emitStatus(DeviceHubConnectionStatus.reconnecting, error: error);
    });

    connection.onreconnected((connectionId) {
      if (!_isActiveConnection(connection, generation)) {
        return;
      }

      unawaited(_handleReconnected(connection, generation));
    });
  }

  Future<void> _handleReconnected(
    HubConnection connection,
    int generation,
  ) async {
    try {
      await _subscribeToCurrentDevice(
        connection: connection,
        generation: generation,
      );
      if (_isActiveConnection(connection, generation)) {
        _emitStatus(DeviceHubConnectionStatus.connected);
      }
    } catch (error) {
      if (_isActiveConnection(connection, generation)) {
        _emitStatus(DeviceHubConnectionStatus.disconnected, error: error);
      }
    }
  }

  Future<void> _subscribeToCurrentDevice({
    required HubConnection connection,
    required int generation,
  }) async {
    final deviceId = _subscribedDeviceId;
    if (!_isActiveConnection(connection, generation) ||
        deviceId == null ||
        deviceId.isEmpty) {
      return;
    }

    await connection.invoke(
      'SubscribeToDevice',
      args: <Object>[deviceId],
    );
  }

  void _handleReceiveDeviceReading(List<dynamic>? arguments) {
    final reading = DeviceReading.tryParse(arguments);
    if (reading == null) {
      return;
    }

    _onReading?.call(reading);
  }

  void _handleReceiveAlert(List<dynamic>? arguments) {
    final alert = DeviceAlert.tryParse(arguments);
    if (alert == null) {
      return;
    }

    _onAlert?.call(alert);
  }

  void _emitStatus(
    DeviceHubConnectionStatus status, {
    Object? error,
  }) {
    _onConnectionStatusChanged?.call(status, error: error);
  }

  Future<void> _stopConnection({
    required bool clearDeviceId,
    required bool emitDisconnected,
  }) async {
    final connection = _connection;
    _connection = null;

    if (connection != null) {
      try {
        connection.off('ReceiveDeviceReading');
        connection.off('ReceiveAlert');
      } catch (_) {
        // Best-effort cleanup for hub handlers.
      }

      try {
        await connection.stop();
      } catch (_) {
        // Ignore connection shutdown failures during cleanup.
      }
    }

    if (clearDeviceId) {
      _subscribedDeviceId = null;
    }

    if (emitDisconnected) {
      _emitStatus(DeviceHubConnectionStatus.disconnected);
    }
  }

  bool _isActiveConnection(HubConnection connection, int generation) {
    return identical(_connection, connection) &&
        _connectionGeneration == generation;
  }
}
