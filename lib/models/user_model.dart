class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? token;
  final List<String> roles;
  final String? parentGender;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.token,
    this.roles = const [],
    this.parentGender,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'token': token,
      'roles': roles,
      'parentGender': parentGender,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      token: json['token'] as String?,
      roles: (json['roles'] as List<dynamic>?)
              ?.map((role) => role.toString())
              .toList() ??
          const [],
      parentGender:
          json['parentGender'] as String? ?? json['guardianGender'] as String?,
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? token,
    List<String>? roles,
    String? parentGender,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      token: token ?? this.token,
      roles: roles ?? this.roles,
      parentGender: parentGender ?? this.parentGender,
    );
  }
}
