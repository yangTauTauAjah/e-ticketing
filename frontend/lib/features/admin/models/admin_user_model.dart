class AdminUser {
  final String id;
  final String name;
  final String email;
  final String username;
  final String role;
  final bool isActive;
  final DateTime createdAt;

  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    email: json['email'] ?? '',
    username: json['username'] ?? '',
    role: json['role'] ?? 'user',
    isActive: json['is_active'] ?? true,
    createdAt: json['created_at'] != null
      ? DateTime.parse(json['created_at'])
      : DateTime.now(),
  );
}
