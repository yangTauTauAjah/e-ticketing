import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_ticketing/core/constants/api_constants.dart';
import 'package:e_ticketing/core/network/dio_client.dart';
import 'package:e_ticketing/features/tickets/models/ticket_history_model.dart';

final ticketHistoryProvider = FutureProvider.family<List<TicketHistoryEvent>, String>((ref, ticketId) async {
  try {
    final dio = ref.read(dioProvider).instance;
    final response = await dio.get('${ApiConstants.tickets}/$ticketId/history');
    final data = response.data['data'];
    if (data == null || data is! List) return [];
    return data.map((json) => TicketHistoryEvent.fromJson(json)).toList();
  } catch (e) {
    throw Exception('Failed to load ticket history: $e');
  }
});
