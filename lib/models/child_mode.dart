enum ChildCondition {
  normal(0, 'Normal'),
  autism(1, 'Autism'),
  adhd(2, 'ADHD');

  const ChildCondition(this.apiValue, this.displayLabel);

  final int apiValue;
  final String displayLabel;

  static ChildCondition? tryParse(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return fromApiValue(value);
    }

    if (value is num) {
      return fromApiValue(value.toInt());
    }

    if (value is String) {
      final normalizedValue = value.trim();
      if (normalizedValue.isEmpty) {
        return null;
      }

      final parsedValue = int.tryParse(normalizedValue);
      if (parsedValue != null) {
        return fromApiValue(parsedValue);
      }

      for (final condition in ChildCondition.values) {
        if (condition.displayLabel.toLowerCase() ==
            normalizedValue.toLowerCase()) {
          return condition;
        }
      }
    }

    return null;
  }

  static ChildCondition? fromApiValue(int value) {
    for (final condition in ChildCondition.values) {
      if (condition.apiValue == value) {
        return condition;
      }
    }

    return null;
  }
}

class ChildModel {
  final String id;
  final String name;
  final String birthDate;
  final int gender;
  final String deviceId;
  final ChildCondition? condition;

  ChildModel({
    required this.id,
    required this.name,
    required this.birthDate,
    required this.gender,
    required this.deviceId,
    this.condition,
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
      id: _requireString(json, const ['id', 'Id']),
      name: _requireString(json, const ['name', 'Name']),
      birthDate: _normalizeBirthDate(
          _readValue(json, const ['birthDate', 'BirthDate'])),
      gender: _requireGender(_readValue(json, const ['gender', 'Gender'])),
      deviceId: _requireOptionalString(
          _readValue(json, const ['deviceId', 'DeviceId'])),
      condition: ChildCondition.tryParse(
        _readValue(json, const ['condition', 'Condition']),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'birthDate': birthDate,
      'gender': gender,
      'deviceId': deviceId,
      if (condition != null) 'condition': condition!.apiValue,
    };
  }

  static String _requireString(Map<String, dynamic> json, List<String> keys) {
    final value = _readValue(json, keys);
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }

    throw FormatException('Invalid child field: ${keys.first}');
  }

  static dynamic _readValue(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      if (json.containsKey(key)) {
        return json[key];
      }
    }

    return null;
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

    if (value is String) {
      final normalizedValue = value.trim();
      final parsedValue = int.tryParse(normalizedValue);
      if (parsedValue != null) {
        return parsedValue;
      }

      switch (normalizedValue.toLowerCase()) {
        case 'male':
          return 0;
        case 'female':
          return 1;
      }
    }

    throw FormatException(
      'Invalid child field: gender (value: $value, type: ${value?.runtimeType})',
    );
  }

  static String _normalizeBirthDate(dynamic value) {
    if (value is! String || value.trim().isEmpty) {
      throw const FormatException('Invalid child field: birthDate');
    }

    return value.split('T').first;
  }
}
