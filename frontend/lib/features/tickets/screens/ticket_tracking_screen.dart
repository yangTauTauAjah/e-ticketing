import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:e_ticketing/features/tickets/screens/ticket_detail_screen.dart';
import 'package:e_ticketing/core/theme/app_colors.dart';
import 'package:e_ticketing/core/theme/status_colors.dart';

class TicketTrackingScreen extends ConsumerWidget {
  final String ticketId;
  const TicketTrackingScreen({super.key, required this.ticketId});

  IconData _statusIcon(String? status) {
    switch (status) {
      case 'open': return LucideIcons.circleDot;
      case 'in_progress': return LucideIcons.loader;
      case 'on_hold': return LucideIcons.pauseCircle;
      case 'closed': return LucideIcons.checkCircle2;
      case 'reopened': return LucideIcons.refreshCw;
      default: return LucideIcons.circle;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketAsync = ref.watch(ticketDetailProvider(ticketId));
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text('Ticket Tracking',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary)),
      ),
      body: ticketAsync.when(
        data: (ticket) {
          final statusEvents = ticket.history
            .where((h) => h.fieldName == 'status')
            .toList()
            ..sort((a, b) => a.changedAt.compareTo(b.changedAt));

          if (statusEvents.isEmpty) {
            return Center(child: Text('No tracking data yet',
              style: TextStyle(color: colors.textMuted, fontSize: 13)));
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Ticket info header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: HeroCard.gradient,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: HeroCard.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TRACKING', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    const SizedBox(height: 8),
                    Text(ticket.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('ID: ${ticket.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(color: Colors.white38, fontSize: 11, fontFamily: 'monospace')),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Timeline stepper
              ...statusEvents.asMap().entries.map((entry) {
                final index = entry.key;
                final event = entry.value;
                final isLast = index == statusEvents.length - 1;
                final color = StatusColors.forStatusName(event.newValue);

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Line + dot column
                      SizedBox(
                        width: 32,
                        child: Column(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(color: color, width: 2),
                              ),
                              child: Icon(_statusIcon(event.newValue), size: 14, color: color),
                            ),
                            if (!isLast)
                              Expanded(
                                child: Container(
                                  width: 2,
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  color: colors.surfaceBorder,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Content
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
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
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
