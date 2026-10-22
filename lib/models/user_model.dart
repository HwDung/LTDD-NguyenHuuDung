
class UserModel {
  final String? id;
  final String? username;
  final String? email;
  final String? role;

  const UserModel({
    this.id,
    this.username,
    this.email,
    this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? json['userId'])?.toString(),
      username: json['username']?.toString(),
      email: json['email']?.toString(),
      role: json['role']?.toString(),
    );
  }
}
