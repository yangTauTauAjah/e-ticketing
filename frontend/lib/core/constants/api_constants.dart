class ApiConstants {
  static const String baseUrl = "http://localhost:5000/api/v1"; // From .env
  static const String login = "$baseUrl/auth/login";
  static const String register = "$baseUrl/auth/register";
  static const String tickets = "$baseUrl/tickets";
  static const String comments = "$baseUrl/comments";
  static const String helpdesks = "$baseUrl/users/helpdesks";
}