class SafeZoneModel {
  SafeZoneModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusInMeters,
    required this.type,
    required this.typeDisplayName,
    required this.createdAt,
    this.childId,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final int radiusInMeters;
  final int type;
  final String typeDisplayName;
  final String createdAt;
  final String? childId;

  factory SafeZoneModel.fromJson(
    Map<String, dynamic> json, {
    String? childId,
  }) {
    final type = _requireType(_readValue(json, const ['type', 'Type']));

    return SafeZoneModel(
      id: _requireString(_readValue(json, const ['id', 'Id']), 'id'),
      name: _requireString(_readValue(json, const ['name', 'Name']), 'name'),
      latitude: _requireDouble(
        _readValue(json, const ['latitude', 'Latitude']),
        'latitude',
      ),
      longitude: _requireDouble(
        _readValue(json, const ['longitude', 'Longitude']),
        'longitude',
      ),
      radiusInMeters: _requireInt(
        _readValue(json, const ['radiusInMeters', 'RadiusInMeters']),
        'radiusInMeters',
      ),
      type: type,
      typeDisplayName: _optionalString(
        _readValue(json, const ['typeDisplayName', 'TypeDisplayName']),
      ).ifEmpty(_typeDisplayNameFromType(type)),
      createdAt: _optionalString(
        _readValue(json, const ['createdAt', 'CreatedAt']),
      ),
      childId: childId,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radiusInMeters': radiusInMeters,
      'type': type,
      'typeDisplayName': typeDisplayName,
      'createdAt': createdAt,
    };

    if (childId != null && childId!.trim().isNotEmpty) {
      json['childId'] = childId;
    }

    return json;
  }

  static dynamic _readValue(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      if (json.containsKey(key)) {
        return json[key];
      }
    }

    return null;
  }

  static String _requireString(dynamic value, String fieldName) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }

    throw FormatException('SafeZone field "$fieldName" is missing or invalid.');
  }

  static double _requireDouble(dynamic value, String fieldName) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      final parsedValue = double.tryParse(value.trim());
      if (parsedValue != null) {
        return parsedValue;
      }
    }

    throw FormatException('SafeZone field "$fieldName" is missing or invalid.');
  }

  static int _requireInt(dynamic value, String fieldName) {
    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      final parsedValue = int.tryParse(value.trim());
      if (parsedValue != null) {
        return parsedValue;
      }
    }

    throw FormatException('SafeZone field "$fieldName" is missing or invalid.');
  }

  static int _requireType(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      final normalizedValue = value.trim();
      final parsedValue = int.tryParse(normalizedValue);
      if (parsedValue != null) {
        return parsedValue;
      }

      switch (normalizedValue.toLowerCase()) {
        case 'school':
        case 'المدرسة':
          return 0;
        case 'home':
        case 'البيت':
        case 'المنزل':
          return 1;
      }
    }

    throw const FormatException('SafeZone field "type" is missing or invalid.');
  }

  static String _optionalString(dynamic value) {
    if (value == null) {
      return '';
    }

    if (value is String) {
      return value;
    }

    return value.toString();
  }

  static String _typeDisplayNameFromType(int type) {
    switch (type) {
      case 0:
        return 'School';
      case 1:
        return 'Home';
      default:
        return '';
    }
  }
}

extension on String {
  String ifEmpty(String fallback) {
    return trim().isEmpty ? fallback : this;
  }
}
