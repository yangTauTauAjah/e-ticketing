import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_ticketing/core/constants/api_constants.dart';
import 'package:e_ticketing/core/network/dio_client.dart';
import 'package:e_ticketing/features/notifications/models/notification_model.dart';

final notificationsProvider = FutureProvider<List<AppNotification>>((ref) async {
  final dio = ref.read(dioProvider).instance;
  final response = await dio.get(ApiConstants.notifications, queryParameters: {'limit': 50});
  final List list = response.data['data']['notifications'];
  return list.map((json) => AppNotification.fromJson(json)).toList();
});

final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  final dio = ref.read(dioProvider).instance;
  final response = await dio.get(ApiConstants.notificationsUnreadCount);
  return (response.data['data']['count'] ?? 0) as int;
});
