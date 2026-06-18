class HelpdeskUser {
  final String id;
  final String name;
  final String email;
  final String username;

  const HelpdeskUser({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
  });

  factory HelpdeskUser.fromJson(Map<String, dynamic> json) {
    try {
      return HelpdeskUser(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        username: json['username'] ?? '',
      );
    } catch (e) {
      throw Exception('Failed to parse helpdesk user: $e');
    }
  }
}
