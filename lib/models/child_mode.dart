class ChildModel {
  final String id;
  final String name;
  final String birthDate;
  final int gender;
  final String deviceId;

  ChildModel({
    required this.id,
    required this.name,
    required this.birthDate,
    required this.gender,
    required this.deviceId,
  });

  int get age {
    final birthDateTime = DateTime.parse(birthDate);
    final today = DateTime.now();
    int age = today.year - birthDateTime.year;
    if (today.month < birthDateTime.month ||
        (today.month == birthDateTime.month && today.day < birthDateTime.day)) {
      age--;
    }
    return age;
  }

  factory ChildModel.fromJson(Map<String, dynamic> json) {
    return ChildModel(
      id: _requireString(json, 'id'),
      name: _requireString(json, 'name'),
      birthDate: _normalizeBirthDate(json['birthDate']),
      gender: _requireGender(json['gender']),
      deviceId: _requireOptionalString(json['deviceId']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'birthDate': birthDate,
      'gender': gender,
      'deviceId': deviceId,
    };
  }

  static String _requireString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }

    throw FormatException('Invalid child field: $key');
  }

  static String _requireOptionalString(dynamic value) {
    if (value == null) {
      return '';
    }

    if (value is String) {
      return value;
    }

    throw const FormatException('Invalid child field: deviceId');
  }

  static int _requireGender(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    throw const FormatException('Invalid child field: gender');
  }

  static String _normalizeBirthDate(dynamic value) {
    if (value is! String || value.trim().isEmpty) {
      throw const FormatException('Invalid child field: birthDate');
    }

    return value.split('T').first;
  }
}
