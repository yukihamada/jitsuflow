class UserModel {
  final String id;
  final String email;
  final String? name;
  final String? avatarUrl;
  final String? role; // 'user', 'dojo_owner', 'instructor', 'admin'

  const UserModel({
    required this.id,
    required this.email,
    this.name,
    this.avatarUrl,
    this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] ?? '',
        email: json['email'] ?? '',
        name: json['name'],
        avatarUrl: json['avatar_url'],
        role: json['role'],
      );
}
