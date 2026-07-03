import 'package:dio/dio.dart';

/// Extracts a user-facing message from an error thrown by a Dio request.
/// Prefers Joi validation field messages (`error.details`) so the user knows
/// exactly what to fix, falling back to the backend's top-level `message`.
String extractErrorMessage(Object error, {String fallback = 'Something went wrong. Please try again.'}) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final details = data['error'] is Map ? data['error']['details'] : null;
      if (details is List && details.isNotEmpty) {
        final messages = details
            .map((d) => d is Map ? d['message']?.toString() : null)
            .whereType<String>()
            .toList();
        if (messages.isNotEmpty) return messages.join('\n');
      }

      final message = data['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    return fallback;
  }
  return fallback;
}
