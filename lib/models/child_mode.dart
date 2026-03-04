class ChildModel {
  final String id;
  final String name;
  final String birthDate;
  final String gender;
  final String deviceId;
  final String userId;

  ChildModel({
    required this.id,
    required this.name,
    required this.birthDate,
    required this.gender,
    required this.deviceId,
    required this.userId,
  });

  // حساب العمر من تاريخ الميلاد
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

  // 🔄 TODO: لما الـ API يجهز
  factory ChildModel.fromJson(Map<String, dynamic> json) {
    return ChildModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      birthDate: json['birth_date'] ?? '',
      gender: json['gender'] ?? '',
      deviceId: json['device_id'] ?? '',
      userId: json['user_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'birth_date': birthDate,
      'gender': gender,
      'device_id': deviceId,
      'user_id': userId,
    };
  }
}
