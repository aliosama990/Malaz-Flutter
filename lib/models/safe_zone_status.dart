import 'device_live_models.dart';

class SafeZoneStatus {
  const SafeZoneStatus({
    required this.isInside,
    this.zoneName,
  });

  const SafeZoneStatus.unknown()
      : isInside = null,
        zoneName = null;

  final bool? isInside;
  final String? zoneName;
}

class TemporarySafeZoneStatusSource {
  const TemporarySafeZoneStatusSource({
    this.mockStatus,
  });

  final SafeZoneStatus? mockStatus;

  SafeZoneStatus resolve(DeviceReading? reading) {
    final override = mockStatus;
    if (override != null) {
      return override;
    }

    // Temporary bridge: once the backend condition endpoint/field is ready,
    // replace this pass-through with that backend source.
    final backendStatus = reading?.isInsideSafeZone;
    if (backendStatus != null) {
      return SafeZoneStatus(
        isInside: backendStatus,
        zoneName: reading?.safeZoneName,
      );
    }

    return const SafeZoneStatus.unknown();
  }
}
