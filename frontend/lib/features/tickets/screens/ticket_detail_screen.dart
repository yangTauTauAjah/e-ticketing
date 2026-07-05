import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:e_ticketing/features/auth/providers/auth_provider.dart';
import 'package:e_ticketing/features/tickets/models/ticket_model.dart';
import 'package:e_ticketing/features/tickets/providers/helpdesk_provider.dart';
import 'package:e_ticketing/core/network/dio_client.dart';
import 'package:e_ticketing/core/constants/api_constants.dart';
import 'package:e_ticketing/features/tickets/providers/ticket_provider.dart';
import 'package:e_ticketing/core/theme/app_colors.dart';
import 'package:e_ticketing/core/theme/status_colors.dart';
import 'package:e_ticketing/features/tickets/screens/dashboard_screen.dart';

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

  void _showImagePreview(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // InteractiveViewer allows pinch-to-zoom and panning
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(LucideIcons.imageOff, color: Colors.white, size: 48),
                  ),
                ),
              ),
            ),
            
            // Close Button
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.x, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _patchTicket(Map<String, dynamic> data, String fieldName) async {
    setState(() => _loadingField = fieldName);
    try {
      final dio = ref.read(dioProvider).instance;
      await dio.patch('${ApiConstants.tickets}/${widget.ticketId}', data: data);
      // ref.invalidate(ticketsProvider);
      ref.invalidate(ticketDetailProvider(widget.ticketId));
      ref.invalidate(filteredTicketsProvider);
      ref.invalidate(ticketStatsProvider);
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
            tooltip: 'View activity',
            onPressed: () => Navigator.pushNamed(
              context,
              '/ticket-tracking',
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
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  gradient: HeroCard.gradient,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: HeroCard.border),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: CardBackgroundPainter(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
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
                              _buildInfoTile('STATUS', ticket.status.name.toUpperCase().replaceAll('_', ' '),
                                dotColor: StatusColors.forStatus(ticket.status)),
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
                          
                          // Image Attachments Section
                          if (ticket.attachments.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            const Text('EVIDENCE LOG',
                              style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 80,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: ticket.attachments.length,
                                itemBuilder: (context, index) {
                                  final url = ticket.attachments[index].toString(); 
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: GestureDetector(
                                      onTap: () => _showImagePreview(context, url), // Trigger full screen
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          url,
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            width: 80, height: 80, color: Colors.white10,
                                            child: const Icon(LucideIcons.imageOff, color: Colors.white54),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
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
              const SizedBox(height: 100),
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
    final isClosed = ticket.status.name == 'closed';
    
    // Filter statuses so Flutter doesn't crash, but disable selection for closed/reopened
    final availableStatuses = TicketStatus.values.where((s) {
      if (s.name == 'closed' || s.name == 'reopened') {
        return s == ticket.status; 
      }
      return true;
    }).toList();

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
          if (ticket.status != TicketStatus.closed && ticket.status != TicketStatus.reopened) _buildFieldDropdown<TicketStatus>(
            context,
            label: 'STATUS',
            fieldKey: 'status',
            value: ticket.status,
            items: availableStatuses.map((s) => DropdownMenuItem(
              value: s,
              enabled: s.name != 'closed' && s.name != 'reopened', // Disable selection from dropdown
              child: Text(s.name.toUpperCase().replaceAll('_', ' ')),
            )).toList(),
            onChanged: (val) => _patchTicket({'status': val!.name}, 'status'),
          ) else if (ticket.status == TicketStatus.reopened) 
            _buildFieldDropdown<TicketStatus>(
              context,
              label: 'STATUS',
              fieldKey: 'status',
              value: ticket.status,
              items: [DropdownMenuItem(
                value: TicketStatus.reopened,
                child: Text(TicketStatus.reopened.name.toUpperCase().replaceAll('_', ' ')),
              ),],
            onChanged: (val) => {},
            ),
          if (ticket.status != TicketStatus.closed) ...[
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
            )
          ],
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
          if (ticket.status != TicketStatus.closed && role == 'admin') ...[
            const SizedBox(height: 12),
            _buildAssignDropdown(context, ticket),
          ],
          
          // Toggle Button for Close/Reopen
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loadingField == 'status' ? null : () {
                _patchTicket({'status': isClosed ? 'reopened' : 'closed'}, 'status');
              },
              icon: _loadingField == 'status' 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Icon(isClosed ? LucideIcons.unlock : LucideIcons.lock, size: 18),
              label: Text(
                isClosed ? 'REOPEN TICKET' : 'CLOSE TICKET',
                style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isClosed ? colors.warning : colors.danger,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
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

  Widget _buildInfoTile(String label, String value, {Color? dotColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
          style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Row(
          children: [
            if (dotColor != null) ...[
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }
}

class _TimelineItem {
  final DateTime time;
  final Widget widget;
  _TimelineItem(this.time, this.widget);
}
