import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:e_ticketing/features/tickets/providers/ticket_history_provider.dart';

class TicketHistoryScreen extends ConsumerWidget {
  final String ticketId;
  const TicketHistoryScreen({super.key, required this.ticketId});

  IconData _iconFor(String fieldName) {
    switch (fieldName) {
      case 'status':
        return LucideIcons.activity;
      case 'priority':
        return LucideIcons.flag;
      case 'category':
        return LucideIcons.tag;
      case 'assignedToId':
        return LucideIcons.userPlus;
      default:
        return LucideIcons.fileText;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(ticketHistoryProvider(ticketId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Ticket History',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
      ),
      body: historyAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return const Center(
              child: Text('No history yet',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
            );
          }
          final sorted = [...events]..sort((a, b) => b.changedAt.compareTo(a.changedAt));
          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: sorted.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final event = sorted[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_iconFor(event.fieldName), size: 16, color: const Color(0xFF0F172A)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event.message,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                          const SizedBox(height: 4),
                          Text(event.changedAt.toString().split('.')[0],
                            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
