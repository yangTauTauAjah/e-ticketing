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

class TicketStats {
  final int total;
  final int open;
  final int inProgress;
  final int onHold;
  final int closed;
  final int reopened;

  const TicketStats({
    required this.total,
    required this.open,
    required this.inProgress,
    required this.onHold,
    required this.closed,
    required this.reopened,
  });

  factory TicketStats.fromJson(Map<String, dynamic> json) => TicketStats(
    total: (json['total'] ?? 0) as int,
    open: (json['open'] ?? 0) as int,
    inProgress: (json['in_progress'] ?? 0) as int,
    onHold: (json['on_hold'] ?? 0) as int,
    closed: (json['closed'] ?? 0) as int,
    reopened: (json['reopened'] ?? 0) as int,
  );
}

final ticketStatsProvider = FutureProvider<TicketStats>((ref) async {
  final dio = ref.read(dioProvider).instance;
  final response = await dio.get(ApiConstants.ticketStats);
  return TicketStats.fromJson(response.data['data']);
});

final filteredTicketsProvider = FutureProvider.family<List<Ticket>, Map<String, String>>((ref, params) async {
  final dio = ref.read(dioProvider).instance;

  final queryParams = <String, dynamic>{
    'limit': params['limit'] ?? '50',
    'sortBy': 'created_at',
    'sortOrder': 'desc',
    ...params,
  };
  queryParams.remove('limit'); // re-add with int type
  queryParams['limit'] = int.tryParse(params['limit'] ?? '50') ?? 50;

  final response = await dio.get(ApiConstants.tickets, queryParameters: queryParams);
  if (response.data['success'] == true) {
    final List list = response.data['data']['tickets'];
    return list.map((json) => Ticket.fromJson(json)).toList();
  }
  return [];
});