import 'package:e_ticketing/core/constants/api_constants.dart';
import 'package:e_ticketing/core/network/dio_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_ticketing/features/tickets/models/ticket_model.dart';

final ticketsProvider = FutureProvider<List<Ticket>>((ref) async {
  final dio = ref.read(dioProvider).instance;
  
  final response = await dio.get(ApiConstants.tickets, queryParameters: {
    'limit': 10,
    'sortBy': 'created_at',
    'sortOrder': 'desc',
  });

  if (response.data['success']) {
    final List list = response.data['data']['tickets'];
    return list.map((json) => Ticket.fromJson(json)).toList();
  }
  return [];
});