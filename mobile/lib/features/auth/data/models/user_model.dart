/// Модель ролі користувача.
class UserRoleModel {
  final String code;
  final String name;
  final String verificationStatus;

  const UserRoleModel({
    required this.code,
    required this.name,
    required this.verificationStatus,
  });

  factory UserRoleModel.fromJson(Map<String, dynamic> json) {
    return UserRoleModel(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      verificationStatus: json['verificationStatus'] as String? ?? '',
    );
  }
}

/// Модель користувача, яку повертає backend.
class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String status;
  final List<UserRoleModel> roles;
  final String createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.status,
    required this.roles,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rolesJson = json['roles'] as List<dynamic>? ?? [];

    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      phone: json['phone'] as String?,
      status: json['status'] as String? ?? '',
      roles: rolesJson
          .map((role) => UserRoleModel.fromJson(role as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}