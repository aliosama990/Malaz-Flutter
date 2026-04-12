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
    return SafeZoneModel(
      id: _requireString(json['id'], 'id'),
      name: _requireString(json['name'], 'name'),
      latitude: _requireDouble(json['latitude'], 'latitude'),
      longitude: _requireDouble(json['longitude'], 'longitude'),
      radiusInMeters: _requireInt(json['radiusInMeters'], 'radiusInMeters'),
      type: _requireInt(json['type'], 'type'),
      typeDisplayName:
          _requireString(json['typeDisplayName'], 'typeDisplayName'),
      createdAt: _requireString(json['createdAt'], 'createdAt'),
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

    throw FormatException('SafeZone field "$fieldName" is missing or invalid.');
  }

  static int _requireInt(dynamic value, String fieldName) {
    if (value is num) {
      return value.toInt();
    }

    throw FormatException('SafeZone field "$fieldName" is missing or invalid.');
  }
}
