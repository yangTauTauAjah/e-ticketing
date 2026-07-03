import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:e_ticketing/features/tickets/providers/ticket_history_provider.dart';
import 'package:e_ticketing/core/theme/app_colors.dart';

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
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text('Ticket History',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary)),
      ),
      body: historyAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return Center(
              child: Text('No history yet',
                style: TextStyle(color: colors.textMuted, fontSize: 13)),
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
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.surfaceBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_iconFor(event.fieldName), size: 16, color: colors.accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event.message,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                          const SizedBox(height: 4),
                          Text(event.changedAt.toString().split('.')[0],
                            style: TextStyle(fontSize: 10, color: colors.textMuted)),
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
