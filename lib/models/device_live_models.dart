import 'dart:convert';

class DeviceReading {
  DeviceReading({
    required this.receivedAt,
    this.deviceId,
    this.latitude,
    this.longitude,
    this.speed,
    this.heartRateBPM,
    this.oxygenLevel,
    this.accelX,
    this.accelY,
    this.accelZ,
    this.fallDetected = false,
    this.batteryLevel,
    this.isSOSPressed = false,
    this.isInsideSafeZone,
    this.safeZoneName,
    this.rawData,
  });

  final DateTime receivedAt;
  final String? deviceId;
  final double? latitude;
  final double? longitude;
  final double? speed;
  final int? heartRateBPM;
  final int? oxygenLevel;
  final double? accelX;
  final double? accelY;
  final double? accelZ;
  final bool fallDetected;
  final int? batteryLevel;
  final bool isSOSPressed;
  final bool? isInsideSafeZone;
  final String? safeZoneName;
  final Map<String, dynamic>? rawData;

  static DeviceReading? tryParse(List<dynamic>? arguments) {
    final payload = _extractPayload(arguments);
    final json = _resolveReadingJson(payload);
    if (json == null) {
      return null;
    }

    return DeviceReading(
      receivedAt: DateTime.now(),
      deviceId: _readString(json, const ['deviceId', 'DeviceId']),
      latitude: _readDouble(json, const ['latitude', 'Latitude']),
      longitude: _readDouble(json, const ['longitude', 'Longitude']),
      speed: _readDouble(json, const ['speed', 'Speed']),
      heartRateBPM:
          _readInt(json, const ['heartRateBPM', 'HeartRateBPM', 'heartRate']),
      oxygenLevel:
          _readInt(json, const ['oxygenLevel', 'OxygenLevel', 'oxygen']),
      accelX: _readDouble(json, const ['accelX', 'AccelX']),
      accelY: _readDouble(json, const ['accelY', 'AccelY']),
      accelZ: _readDouble(json, const ['accelZ', 'AccelZ']),
      fallDetected:
          _readBool(json, const ['fallDetected', 'FallDetected']) ?? false,
      batteryLevel: _readInt(json, const ['batteryLevel', 'BatteryLevel']),
      isSOSPressed:
          _readBool(json, const ['isSOSPressed', 'IsSOSPressed']) ?? false,
      isInsideSafeZone: _readSafeZoneStatus(json),
      safeZoneName: _readStringFromReadingContainers(
        json,
        const [
          'safeZoneName',
          'SafeZoneName',
          'zoneName',
          'ZoneName',
          'areaName',
          'AreaName',
        ],
      ),
      rawData: json,
    );
  }
}

class DeviceAlert {
  DeviceAlert({
    required this.message,
    required this.receivedAt,
    this.deviceId,
    this.type,
    this.rawData,
  });

  final String message;
  final DateTime receivedAt;
  final String? deviceId;
  final String? type;
  final Map<String, dynamic>? rawData;

  static DeviceAlert? tryParse(List<dynamic>? arguments) {
    if (arguments == null || arguments.isEmpty) {
      return null;
    }

    final payload = _extractPayload(arguments);
    final json = _tryParseMap(payload);
    if (json != null) {
      final message = _readString(
        json,
        const [
          'message',
          'Message',
          'alertMessage',
          'AlertMessage',
          'description',
          'Description',
          'title',
          'Title',
        ],
      );

      if (message != null && message.isNotEmpty) {
        return DeviceAlert(
          message: message,
          receivedAt: DateTime.now(),
          deviceId: _readString(json, const ['deviceId', 'DeviceId']),
          type:
              _readString(json, const ['type', 'Type', 'severity', 'Severity']),
          rawData: json,
        );
      }
    }

    final text = arguments
        .map(_stringifyValue)
        .where((value) => value.trim().isNotEmpty)
        .join(' - ')
        .trim();

    if (text.isEmpty) {
      return null;
    }

    return DeviceAlert(
      message: text,
      receivedAt: DateTime.now(),
    );
  }
}

bool _hasSupportedReadingPayload(Map<String, dynamic> json) {
  return _containsAnyKey(json, const [
    'latitude',
    'Latitude',
    'longitude',
    'Longitude',
    'speed',
    'Speed',
    'heartRateBPM',
    'HeartRateBPM',
    'heartRate',
    'oxygenLevel',
    'OxygenLevel',
    'oxygen',
    'accelX',
    'AccelX',
    'accelY',
    'AccelY',
    'accelZ',
    'AccelZ',
    'fallDetected',
    'FallDetected',
    'batteryLevel',
    'BatteryLevel',
    'isSOSPressed',
    'IsSOSPressed',
    'isInsideSafeZone',
    'IsInsideSafeZone',
    'insideSafeZone',
    'InsideSafeZone',
    'inSafeZone',
    'InSafeZone',
    'isInSafeZone',
    'IsInSafeZone',
    'withinSafeZone',
    'WithinSafeZone',
    'isOutsideSafeZone',
    'IsOutsideSafeZone',
    'outsideSafeZone',
    'OutsideSafeZone',
    'outOfSafeZone',
    'OutOfSafeZone',
    'isOutOfSafeZone',
    'IsOutOfSafeZone',
    'safeZoneStatus',
    'SafeZoneStatus',
    'zoneStatus',
    'ZoneStatus',
    'locationStatus',
    'LocationStatus',
  ]);
}

Map<String, dynamic>? _resolveReadingJson(dynamic payload) {
  final json = _tryParseMap(payload);
  if (json == null) {
    return null;
  }

  final nestedReadingPayload = _readFirstValue(
    json,
    const ['Reading', 'reading'],
  );
  final nestedReadingJson = _tryParseMap(nestedReadingPayload);
  if (nestedReadingJson != null &&
      _hasSupportedReadingPayload(nestedReadingJson)) {
    return <String, dynamic>{
      ...json,
      ...nestedReadingJson,
    };
  }

  if (_hasSupportedReadingPayload(json)) {
    return json;
  }

  return null;
}

bool? _readSafeZoneStatus(Map<String, dynamic> json) {
  final insideSafeZone = _readBoolFromReadingContainers(
    json,
    const [
      'isInsideSafeZone',
      'IsInsideSafeZone',
      'insideSafeZone',
      'InsideSafeZone',
      'inSafeZone',
      'InSafeZone',
      'isInSafeZone',
      'IsInSafeZone',
      'withinSafeZone',
      'WithinSafeZone',
    ],
  );
  if (insideSafeZone != null) {
    return insideSafeZone;
  }

  final outsideSafeZone = _readBoolFromReadingContainers(
    json,
    const [
      'isOutsideSafeZone',
      'IsOutsideSafeZone',
      'outsideSafeZone',
      'OutsideSafeZone',
      'outOfSafeZone',
      'OutOfSafeZone',
      'isOutOfSafeZone',
      'IsOutOfSafeZone',
    ],
  );
  if (outsideSafeZone != null) {
    return !outsideSafeZone;
  }

  final statusText = _readStringFromReadingContainers(
    json,
    const [
      'safeZoneStatus',
      'SafeZoneStatus',
      'zoneStatus',
      'ZoneStatus',
      'locationStatus',
      'LocationStatus',
    ],
  );

  return _parseSafeZoneStatusText(statusText);
}

bool? _parseSafeZoneStatusText(String? value) {
  if (value == null) {
    return null;
  }

  final normalizedValue =
      value.trim().toLowerCase().replaceAll(RegExp(r'[\s_\-]+'), '');
  if (normalizedValue.isEmpty) {
    return null;
  }

  if (normalizedValue.contains('outside') ||
      normalizedValue.contains('outof') ||
      normalizedValue.contains('unsafe') ||
      normalizedValue.contains('danger') ||
      normalizedValue.contains('notsafe') ||
      normalizedValue.contains('خارج')) {
    return false;
  }

  if (normalizedValue.contains('inside') ||
      normalizedValue.contains('within') ||
      normalizedValue.contains('insafezone') ||
      normalizedValue.contains('safe') ||
      normalizedValue.contains('داخل') ||
      normalizedValue.contains('آمن') ||
      normalizedValue.contains('امن')) {
    return true;
  }

  return null;
}

bool? _readBoolFromReadingContainers(
  Map<String, dynamic> json,
  List<String> keys,
) {
  final value = _readBool(json, keys);
  if (value != null) {
    return value;
  }

  for (final nestedJson in _readingStatusContainers(json)) {
    final nestedValue = _readBool(nestedJson, keys);
    if (nestedValue != null) {
      return nestedValue;
    }
  }

  return null;
}

String? _readStringFromReadingContainers(
  Map<String, dynamic> json,
  List<String> keys,
) {
  final value = _readString(json, keys);
  if (value != null) {
    return value;
  }

  for (final nestedJson in _readingStatusContainers(json)) {
    final nestedValue = _readString(nestedJson, keys);
    if (nestedValue != null) {
      return nestedValue;
    }
  }

  return null;
}

List<Map<String, dynamic>> _readingStatusContainers(
  Map<String, dynamic> json,
) {
  const containerKeys = <String>[
    'analysis',
    'Analysis',
    'safeZone',
    'SafeZone',
    'zone',
    'Zone',
    'location',
    'Location',
  ];

  final containers = <Map<String, dynamic>>[];
  for (final key in containerKeys) {
    final nestedJson = _tryParseMap(json[key]);
    if (nestedJson != null) {
      containers.add(nestedJson);
    }
  }

  return containers;
}

dynamic _extractPayload(List<dynamic>? arguments) {
  if (arguments == null || arguments.isEmpty) {
    return null;
  }

  if (arguments.length == 1) {
    return arguments.first;
  }

  return arguments;
}

Map<String, dynamic>? _tryParseMap(dynamic value) {
  if (value is Map) {
    return value.map(
      (key, item) => MapEntry(key.toString(), item),
    );
  }

  if (value is String) {
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(trimmedValue);
      if (decoded is Map) {
        return decoded.map(
          (key, item) => MapEntry(key.toString(), item),
        );
      }
    } on FormatException {
      return null;
    }
  }

  return null;
}

bool _containsAnyKey(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key)) {
      return true;
    }
  }

  return false;
}

dynamic _readFirstValue(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key)) {
      return json[key];
    }
  }

  return null;
}

String? _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    if (value != null && value is! String) {
      final text = value.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
  }

  return null;
}

int? _readInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      final parsedValue = int.tryParse(value.trim());
      if (parsedValue != null) {
        return parsedValue;
      }
    }
  }

  return null;
}

double? _readDouble(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      final parsedValue = double.tryParse(value.trim());
      if (parsedValue != null) {
        return parsedValue;
      }
    }
  }

  return null;
}

bool? _readBool(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    if (value is String) {
      final normalizedValue = value.trim().toLowerCase();
      if (normalizedValue == 'true' || normalizedValue == '1') {
        return true;
      }

      if (normalizedValue == 'false' || normalizedValue == '0') {
        return false;
      }
    }
  }

  return null;
}

String _stringifyValue(dynamic value) {
  if (value == null) {
    return '';
  }

  if (value is String) {
    return value.trim();
  }

  final json = _tryParseMap(value);
  if (json != null) {
    final message = _readString(
      json,
      const [
        'message',
        'Message',
        'alertMessage',
        'AlertMessage',
        'description',
        'Description',
        'title',
        'Title',
      ],
    );
    if (message != null) {
      return message;
    }

    return jsonEncode(json);
  }

  if (value is List) {
    return value.map(_stringifyValue).join(' - ').trim();
  }

  return value.toString().trim();
}
