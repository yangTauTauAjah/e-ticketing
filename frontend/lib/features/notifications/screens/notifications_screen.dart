import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:e_ticketing/core/constants/api_constants.dart';
import 'package:e_ticketing/core/network/dio_client.dart';
import 'package:e_ticketing/core/theme/app_colors.dart';
import 'package:e_ticketing/features/notifications/models/notification_model.dart';
import 'package:e_ticketing/features/notifications/providers/notification_provider.dart';

String _relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';
}

IconData _iconFor(String type) {
  switch (type) {
    case 'ticket_assigned': return LucideIcons.userPlus;
    case 'status_changed': return LucideIcons.activity;
    case 'new_comment': return LucideIcons.messageSquare;
    default: return LucideIcons.bell;
  }
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _markAllRead(WidgetRef ref) async {
    final dio = ref.read(dioProvider).instance;
    await dio.patch(ApiConstants.notificationsReadAll);
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadNotificationCountProvider);
  }

  Future<void> _handleTap(BuildContext context, WidgetRef ref, AppNotification notification) async {
    if (!notification.isRead) {
      final dio = ref.read(dioProvider).instance;
      try {
        await dio.patch('${ApiConstants.notifications}/${notification.id}/read');
        ref.invalidate(notificationsProvider);
        ref.invalidate(unreadNotificationCountProvider);
      } catch (_) {
        // Non-critical — ignore and still navigate.
      }
    }
    if (notification.ticketId != null && context.mounted) {
      Navigator.pushNamed(context, '/ticket-detail', arguments: notification.ticketId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text('Notifications',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary)),
        actions: [
          TextButton(
            onPressed: () => _markAllRead(ref),
            child: const Text('Mark all read', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(notificationsProvider);
          await ref.read(notificationsProvider.future);
        },
        child: notificationsAsync.when(
          data: (notifications) {
            if (notifications.isEmpty) {
              return ListView(
                children: [
                  SizedBox(
                    height: 300,
                    child: Center(
                      child: Text('No notifications yet',
                        style: TextStyle(color: colors.textMuted, fontSize: 13)),
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return InkWell(
                  onTap: () => _handleTap(context, ref, notification),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: notification.isRead ? colors.surface : colors.accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: notification.isRead ? colors.surfaceBorder : colors.accent.withValues(alpha: 0.3),
                      ),
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
                          child: Icon(_iconFor(notification.type), size: 16, color: colors.accent),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(notification.title,
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                              const SizedBox(height: 4),
                              Text(notification.message,
                                style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                              const SizedBox(height: 6),
                              Text(_relativeTime(notification.createdAt),
                                style: TextStyle(fontSize: 10, color: colors.textMuted)),
                            ],
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8, height: 8,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(color: colors.accent, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}
