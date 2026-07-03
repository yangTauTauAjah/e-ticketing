import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_ticketing/core/constants/api_constants.dart';
import 'package:e_ticketing/core/network/dio_client.dart';
import 'package:e_ticketing/features/admin/models/admin_user_model.dart';

final adminUsersProvider = FutureProvider<List<AdminUser>>((ref) async {
  try {
    final dio = ref.read(dioProvider).instance;
    final response = await dio.get(ApiConstants.usersAdmin, queryParameters: {'limit': 100});
    final List data = response.data['data']['users'];
    return data.map((json) => AdminUser.fromJson(json)).toList();
  } catch (e) {
    throw Exception('Failed to load users: $e');
  }
});
