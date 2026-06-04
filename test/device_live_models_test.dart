import 'package:flutter_test/flutter_test.dart';
import 'package:malaz_app/models/device_live_models.dart';

void main() {
  group('DeviceReading.tryParse', () {
    test('parses the existing flat payload shape', () {
      final reading = DeviceReading.tryParse(<dynamic>[
        <String, dynamic>{
          'DeviceId': 'watch123',
          'Latitude': 30.1,
          'Longitude': 31.2,
          'HeartRateBPM': 92,
        },
      ]);

      expect(reading, isNotNull);
      expect(reading!.deviceId, 'watch123');
      expect(reading.latitude, 30.1);
      expect(reading.longitude, 31.2);
      expect(reading.heartRateBPM, 92);
    });

    test('parses a wrapped Reading payload', () {
      final reading = DeviceReading.tryParse(<dynamic>[
        <String, dynamic>{
          'Reading': <String, dynamic>{
            'DeviceId': 'watchABC',
            'Latitude': 29.9,
            'Longitude': 31.1,
            'HeartRateBPM': 87,
          },
          'Analysis': <String, dynamic>{
            'riskLevel': 'low',
          },
        },
      ]);

      expect(reading, isNotNull);
      expect(reading!.deviceId, 'watchABC');
      expect(reading.latitude, 29.9);
      expect(reading.longitude, 31.1);
      expect(reading.heartRateBPM, 87);
    });

    test('parses a wrapped lowercase reading payload', () {
      final reading = DeviceReading.tryParse(<dynamic>[
        <String, dynamic>{
          'reading': <String, dynamic>{
            'deviceId': 'watchXYZ',
            'latitude': 30.5,
            'longitude': 31.5,
            'heartRateBPM': 80,
          },
        },
      ]);

      expect(reading, isNotNull);
      expect(reading!.deviceId, 'watchXYZ');
      expect(reading.latitude, 30.5);
      expect(reading.longitude, 31.5);
      expect(reading.heartRateBPM, 80);
    });

    test('parses inside safe-zone status from a flat payload', () {
      final reading = DeviceReading.tryParse(<dynamic>[
        <String, dynamic>{
          'DeviceId': 'watch123',
          'Latitude': 30.1,
          'Longitude': 31.2,
          'IsInsideSafeZone': true,
          'SafeZoneName': 'المدرسة',
        },
      ]);

      expect(reading, isNotNull);
      expect(reading!.isInsideSafeZone, isTrue);
      expect(reading.safeZoneName, 'المدرسة');
    });

    test('parses outside safe-zone status from wrapped analysis payload', () {
      final reading = DeviceReading.tryParse(<dynamic>[
        <String, dynamic>{
          'Reading': <String, dynamic>{
            'DeviceId': 'watchABC',
            'Latitude': 29.9,
            'Longitude': 31.1,
          },
          'Analysis': <String, dynamic>{
            'SafeZoneStatus': 'outside',
          },
        },
      ]);

      expect(reading, isNotNull);
      expect(reading!.isInsideSafeZone, isFalse);
    });
  });
}
