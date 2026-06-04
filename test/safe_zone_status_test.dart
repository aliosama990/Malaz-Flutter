import 'package:flutter_test/flutter_test.dart';
import 'package:malaz_app/models/device_live_models.dart';
import 'package:malaz_app/models/safe_zone_status.dart';

void main() {
  group('TemporarySafeZoneStatusSource', () {
    test('uses mock status when provided', () {
      const source = TemporarySafeZoneStatusSource(
        mockStatus: SafeZoneStatus(
          isInside: false,
          zoneName: 'خارج المنطقة الآمنة',
        ),
      );

      final status = source.resolve(
        DeviceReading(
          receivedAt: DateTime(2026),
          isInsideSafeZone: true,
          safeZoneName: 'المدرسة',
        ),
      );

      expect(status.isInside, isFalse);
      expect(status.zoneName, 'خارج المنطقة الآمنة');
    });

    test('passes through backend-like reading status when present', () {
      const source = TemporarySafeZoneStatusSource();

      final status = source.resolve(
        DeviceReading(
          receivedAt: DateTime(2026),
          isInsideSafeZone: true,
          safeZoneName: 'المدرسة',
        ),
      );

      expect(status.isInside, isTrue);
      expect(status.zoneName, 'المدرسة');
    });

    test('returns unknown when no temporary or backend-like status exists', () {
      const source = TemporarySafeZoneStatusSource();

      final status = source.resolve(
        DeviceReading(receivedAt: DateTime(2026)),
      );

      expect(status.isInside, isNull);
      expect(status.zoneName, isNull);
    });
  });
}
