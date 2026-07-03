class ApiConstants {
  static const String baseUrl = "http://localhost:5000/api/v1"; // From .env
  static const String login = "$baseUrl/auth/login";
  static const String register = "$baseUrl/auth/register";
  static const String resetPassword = "$baseUrl/auth/reset-password";
  static const String tickets = "$baseUrl/tickets";
  static const String comments = "$baseUrl/comments";
  static const String helpdesks = "$baseUrl/users/helpdesks";
  static const String profile = "$baseUrl/users/profile";
  static const String ticketStats = "$baseUrl/tickets/stats";
  static const String usersAdmin = "$baseUrl/users";
  static const String notifications = "$baseUrl/notifications";
  static const String notificationsUnreadCount = "$baseUrl/notifications/unread-count";
  static const String notificationsReadAll = "$baseUrl/notifications/read-all";
}