import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:e_ticketing/features/auth/providers/auth_provider.dart';
import 'package:e_ticketing/features/tickets/models/ticket_model.dart';
import 'package:e_ticketing/features/tickets/providers/helpdesk_provider.dart';
import 'package:e_ticketing/core/network/dio_client.dart';
import 'package:e_ticketing/core/constants/api_constants.dart';
import 'package:e_ticketing/features/tickets/providers/ticket_provider.dart';
import 'package:e_ticketing/features/tickets/providers/ticket_history_provider.dart';
import 'package:e_ticketing/core/theme/app_colors.dart';

final ticketDetailProvider = FutureProvider.family<Ticket, String>((ref, id) async {
  final dio = ref.read(dioProvider).instance;
  final response = await dio.get('${ApiConstants.tickets}/$id');
  return Ticket.fromJson(response.data['data']['ticket']);
});

class TicketDetailScreen extends ConsumerStatefulWidget {
  final String ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  String? _loadingField;
  late final TextEditingController _replyController;

  @override
  void initState() {
    super.initState();
    _replyController = TextEditingController();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _patchTicket(Map<String, dynamic> data, String fieldName) async {
    setState(() => _loadingField = fieldName);
    try {
      final dio = ref.read(dioProvider).instance;
      await dio.patch('${ApiConstants.tickets}/${widget.ticketId}', data: data);
      ref.invalidate(ticketDetailProvider(widget.ticketId));
      ref.invalidate(ticketsProvider);
      ref.invalidate(filteredTicketsProvider);
      ref.invalidate(ticketStatsProvider);
      ref.invalidate(ticketHistoryProvider(widget.ticketId));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Update failed. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingField = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketAsync = ref.watch(ticketDetailProvider(widget.ticketId));
    final authState = ref.watch(authProvider).value;
    final role = authState?.role ?? 'user';
    final canEdit = role == 'admin' || role == 'helpdesk';
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.gitBranch),
            tooltip: 'View tracking',
            onPressed: () => Navigator.pushNamed(
              context,
              '/ticket-tracking',
              arguments: widget.ticketId,
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.history),
            tooltip: 'View history',
            onPressed: () => Navigator.pushNamed(
              context,
              '/ticket-history',
              arguments: widget.ticketId,
            ),
          ),
        ],
      ),
      body: ticketAsync.when(
        data: (ticket) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Dark transaction card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: HeroCard.gradient,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: HeroCard.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TRANSACTION REGISTRY',
                      style: TextStyle(color: colors.accent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    Text('Case ID #${ticket.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('SUBJECT HEADER',
                      style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                    Text(ticket.title,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 24),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 24,
                      crossAxisSpacing: 0,
                      childAspectRatio: 4.0,
                      children: [
                        _buildInfoTile('REPORTER', ticket.createdByName),
                        _buildInfoTile('ASSIGNED TO', ticket.assignedToName ?? 'Unassigned'),
                        _buildInfoTile('STATUS', ticket.status.name.toUpperCase().replaceAll('_', ' ')),
                        _buildInfoTile('CREATED AT', ticket.createdAt.toString().split(' ')[0]),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 24),
                    const Text('DESCRIPTION',
                      style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(height: 8),
                    Text(ticket.description,
                      style: const TextStyle(color: Colors.white, fontSize: 12, letterSpacing: 0.5, height: 1.6)),
                  ],
                ),
              ),

              // Edit panel — helpdesk and admin only
              if (canEdit) ...[
                const SizedBox(height: 24),
                _buildEditPanel(context, ticket, role),
              ],

              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('COMMENTS',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.textPrimary)),
              ),
              const SizedBox(height: 24),
              ..._buildTimeline(context, ticket, authState?.id).map((item) => item.widget),
              const SizedBox(height: 70),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      bottomSheet: _buildReplyBar(context),
    );
  }

  Widget _buildEditPanel(BuildContext context, Ticket ticket, String role) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.surfaceBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MANAGE TICKET',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.textMuted, letterSpacing: 2)),
          const SizedBox(height: 16),
          _buildFieldDropdown<TicketStatus>(
            context,
            label: 'STATUS',
            fieldKey: 'status',
            value: ticket.status,
            items: TicketStatus.values.map((s) => DropdownMenuItem(
              value: s,
              child: Text(s.name.toUpperCase().replaceAll('_', ' ')),
            )).toList(),
            onChanged: (val) => _patchTicket({'status': val!.name}, 'status'),
          ),
          const SizedBox(height: 12),
          _buildFieldDropdown<TicketPriority>(
            context,
            label: 'PRIORITY',
            fieldKey: 'priority',
            value: ticket.priority,
            items: TicketPriority.values.map((p) => DropdownMenuItem(
              value: p,
              child: Text(p.name.toUpperCase()),
            )).toList(),
            onChanged: (val) => _patchTicket({'priority': val!.name}, 'priority'),
          ),
          const SizedBox(height: 12),
          _buildFieldDropdown<TicketCategory>(
            context,
            label: 'CATEGORY',
            fieldKey: 'category',
            value: ticket.category,
            items: TicketCategory.values.map((c) => DropdownMenuItem(
              value: c,
              child: Text(
                c.name.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}').toUpperCase(),
              ),
            )).toList(),
            onChanged: (val) {
              final apiVal = val!.name.replaceAllMapped(
                RegExp(r'([A-Z])'), (m) => '_${m.group(0)!.toLowerCase()}');
              _patchTicket({'category': apiVal}, 'category');
            },
          ),
          if (role == 'admin') ...[
            const SizedBox(height: 12),
            _buildAssignDropdown(context, ticket),
          ],
        ],
      ),
    );
  }

  Widget _buildFieldDropdown<T>(
    BuildContext context, {
    required String label,
    required String fieldKey,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    final colors = context.colors;
    final isLoading = _loadingField == fieldKey;
    return Row(
      children: [
        SizedBox(
          width: 84,
          child: Text(label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.textSecondary)),
        ),
        Expanded(
          child: isLoading
            ? const LinearProgressIndicator(minHeight: 2)
            : DropdownButtonHideUnderline(
                child: DropdownButton<T>(
                  value: value,
                  isDense: true,
                  isExpanded: true,
                  items: items,
                  onChanged: onChanged,
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold, color: colors.textPrimary),
                ),
              ),
        ),
      ],
    );
  }

  Widget _buildAssignDropdown(BuildContext context, Ticket ticket) {
    final colors = context.colors;
    final helpdesksAsync = ref.watch(helpdesksProvider);
    return helpdesksAsync.when(
      data: (helpdesks) => _buildFieldDropdown<String?>(
        context,
        label: 'ASSIGN TO',
        fieldKey: 'assignedTo',
        value: helpdesks.any((h) => h.id == ticket.assignedToId) ? ticket.assignedToId : null,
        items: [
          const DropdownMenuItem<String?>(value: null, child: Text('UNASSIGNED')),
          ...helpdesks.map((h) => DropdownMenuItem<String?>(
            value: h.id,
            child: Text(h.name.toUpperCase()),
          )),
        ],
        onChanged: (val) => _patchTicket({'assignedToId': val}, 'assignedTo'),
      ),
      loading: () => Row(
        children: [
          SizedBox(
            width: 84,
            child: Text('ASSIGN TO',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.textSecondary)),
          ),
          const SizedBox(width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2)),
        ],
      ),
      error: (e, _) => Text('Failed to load helpdesk users',
        style: TextStyle(color: colors.danger, fontSize: 12)),
    );
  }

  Widget _buildReplyBar(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: colors.surfaceBorder),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20)],
        ),
        child: Row(
          children: [
            Expanded(child: TextField(
              controller: _replyController,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'message...',
                hintStyle: TextStyle(color: colors.textMuted),
                border: InputBorder.none,
              ),
            )),
            IconButton(
              onPressed: () async {
                final text = _replyController.text.trim();
                if (text.isEmpty) return;
                try {
                  final dio = ref.read(dioProvider).instance;
                  await dio.post(
                    '${ApiConstants.comments}/tickets/${widget.ticketId}/comments',
                    data: {'content': text},
                  );
                  _replyController.clear();
                  ref.invalidate(ticketDetailProvider(widget.ticketId));
                } catch (_) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to send comment. Please try again.')),
                    );
                  }
                }
              },
              icon: Icon(LucideIcons.send, color: colors.accent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentBubble(BuildContext context, String author, String text, {bool isMe = false}) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isMe ? colors.accent : colors.surface,
            borderRadius: BorderRadius.circular(20).copyWith(
              topLeft: isMe ? const Radius.circular(20) : Radius.zero,
              bottomRight: isMe ? Radius.zero : const Radius.circular(20),
            ),
            border: isMe ? null : Border.all(color: colors.surfaceBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMe) Text(author.toUpperCase(),
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: colors.accent)),
              Text(text,
                style: TextStyle(color: isMe ? Colors.white : colors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryMessage(BuildContext context, String message) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: colors.textMuted, fontStyle: FontStyle.italic),
        ),
      ),
    );
  }

  List<_TimelineItem> _buildTimeline(BuildContext context, Ticket ticket, String? currentUserId) {
    final items = <_TimelineItem>[];
    for (final c in ticket.comments) {
      items.add(_TimelineItem(
        c.createdAt,
        _buildCommentBubble(context, c.authorName, c.content, isMe: c.authorId == currentUserId),
      ));
    }
    for (final h in ticket.history) {
      items.add(_TimelineItem(h.changedAt, _buildHistoryMessage(context, h.message)));
    }
    items.sort((a, b) => a.time.compareTo(b.time));
    return items;
  }

  Widget _buildInfoTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
          style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _TimelineItem {
  final DateTime time;
  final Widget widget;
  _TimelineItem(this.time, this.widget);
}
