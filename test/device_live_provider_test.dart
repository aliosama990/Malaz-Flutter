import 'package:flutter_test/flutter_test.dart';
import 'package:malaz_app/models/device_live_models.dart';
import 'package:malaz_app/providers/device_live_provider.dart';
import 'package:malaz_app/services/device_hub_service.dart';

void main() {
  group('DeviceLiveProvider.connectToDevice', () {
    test(
      'keeps active callbacks when the same device is requested again',
      () async {
        final fakeHubService = _FakeDeviceHubService();
        final provider = DeviceLiveProvider(deviceHubService: fakeHubService);

        await provider.connectToDevice('watch123');
        expect(provider.connectionStatus, DeviceHubConnectionStatus.connected);
        expect(fakeHubService.connectCalls, 1);
        expect(fakeHubService.hasAlertListener, isTrue);

        await provider.connectToDevice('watch123');
        expect(fakeHubService.connectCalls, 1);

        fakeHubService.emitReading(
          DeviceReading(
            receivedAt: DateTime(2026, 4, 19, 12),
            deviceId: 'watch123',
            heartRateBPM: 96,
          ),
        );

        expect(provider.latestReading, isNotNull);
        expect(provider.latestReading!.deviceId, 'watch123');
        expect(provider.latestReading!.heartRateBPM, 96);
      },
    );
  });
}

class _FakeDeviceHubService extends DeviceHubService {
  int connectCalls = 0;
  DeviceReadingCallback? _onReading;
  DeviceAlertCallback? _onAlert;
  DeviceConnectionStatusCallback? _onConnectionStatusChanged;

  bool get hasAlertListener => _onAlert != null;

  @override
  Future<void> connectAndSubscribe({
    required String deviceId,
    required DeviceReadingCallback onReading,
    required DeviceAlertCallback onAlert,
    EmergencyAudioAlertCallback? onEmergencyAudio,
    required DeviceConnectionStatusCallback onConnectionStatusChanged,
  }) async {
    connectCalls++;
    _onReading = onReading;
    _onAlert = onAlert;
    _onConnectionStatusChanged = onConnectionStatusChanged;
    _onConnectionStatusChanged?.call(DeviceHubConnectionStatus.connected);
  }

  void emitReading(DeviceReading reading) {
    _onReading?.call(reading);
  }

  @override
  void clearCallbacks() {
    _onReading = null;
    _onAlert = null;
    _onConnectionStatusChanged = null;
  }

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> dispose() async {
    clearCallbacks();
  }
}
