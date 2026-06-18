import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_ticketing/core/constants/api_constants.dart';
import 'package:e_ticketing/core/network/dio_client.dart';
import 'package:e_ticketing/features/tickets/models/helpdesk_user_model.dart';

final helpdesksProvider = FutureProvider<List<HelpdeskUser>>((ref) async {
  try {
    final dio = ref.read(dioProvider).instance;
    final response = await dio.get(ApiConstants.helpdesks);
    final data = response.data['data'];
    if (data == null || data is! List) return [];
    return data.map((json) => HelpdeskUser.fromJson(json)).toList();
  } catch (e) {
    throw Exception('Failed to load helpdesk users: $e');
  }
});
