import 'dart:convert';

class EmergencyAudioAlert {
  const EmergencyAudioAlert({
    required this.childName,
    required this.deviceId,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.isSOSPressed,
    required this.audioUrl,
    required this.audioFileName,
  });

  static const String _baseUrl = 'https://malaz.runasp.net';

  final String childName;
  final String deviceId;
  final DateTime? timestamp;
  final double? latitude;
  final double? longitude;
  final String locationName;
  final bool isSOSPressed;
  final String audioUrl;
  final String audioFileName;

  String get resolvedAudioUrl {
    if (audioUrl.startsWith('/')) {
      return '$_baseUrl$audioUrl';
    }

    return audioUrl;
  }

  factory EmergencyAudioAlert.fromJson(Map<String, dynamic> json) {
    final payload = _readMap(json, const ['data', 'Data']) ?? json;

    return EmergencyAudioAlert(
      childName: _readString(payload, const ['childName', 'ChildName']),
      deviceId: _readString(payload, const ['deviceId', 'DeviceId']),
      timestamp: _readDateTime(payload, const ['timestamp', 'Timestamp']),
      latitude: _readDouble(payload, const ['latitude', 'Latitude']),
      longitude: _readDouble(payload, const ['longitude', 'Longitude']),
      locationName:
          _readString(payload, const ['locationName', 'LocationName']),
      isSOSPressed:
          _readBool(payload, const ['isSOSPressed', 'IsSOSPressed']) ?? false,
      audioUrl: _readString(payload, const ['audioUrl', 'AudioUrl']),
      audioFileName:
          _readString(payload, const ['audioFileName', 'AudioFileName']),
    );
  }

  static EmergencyAudioAlert? tryParse(List<dynamic>? arguments) {
    final payload = _extractPayload(arguments);
    final json = _tryParseMap(payload);
    if (json == null) {
      return null;
    }

    final resolvedJson = _readMap(json, const ['data', 'Data']) ?? json;
    if (!_hasEmergencyAudioPayload(resolvedJson)) {
      return null;
    }

    try {
      return EmergencyAudioAlert.fromJson(resolvedJson);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'childName': childName,
      'deviceId': deviceId,
      'timestamp': timestamp?.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'isSOSPressed': isSOSPressed,
      'audioUrl': audioUrl,
      'audioFileName': audioFileName,
    };
  }

  static Map<String, dynamic>? _readMap(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is Map) {
        return value.map(
          (key, item) => MapEntry(key.toString(), item),
        );
      }
    }

    return null;
  }

  static dynamic _extractPayload(List<dynamic>? arguments) {
    if (arguments == null || arguments.isEmpty) {
      return null;
    }

    return arguments.first;
  }

  static Map<String, dynamic>? _tryParseMap(dynamic value) {
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

  static bool _hasEmergencyAudioPayload(Map<String, dynamic> json) {
    return _containsAnyKey(json, const [
      'childName',
      'ChildName',
      'deviceId',
      'DeviceId',
      'timestamp',
      'Timestamp',
      'latitude',
      'Latitude',
      'longitude',
      'Longitude',
      'locationName',
      'LocationName',
      'isSOSPressed',
      'IsSOSPressed',
      'audioUrl',
      'AudioUrl',
      'audioFileName',
      'AudioFileName',
    ]);
  }

  static bool _containsAnyKey(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      if (json.containsKey(key)) {
        return true;
      }
    }

    return false;
  }

  static String _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String) {
        return value.trim();
      }

      if (value != null) {
        return value.toString().trim();
      }
    }

    return '';
  }

  static DateTime? _readDateTime(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    final value = _readString(json, keys);
    if (value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  static double? _readDouble(Map<String, dynamic> json, List<String> keys) {
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

  static bool? _readBool(Map<String, dynamic> json, List<String> keys) {
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
}
