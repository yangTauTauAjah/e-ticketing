import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:e_ticketing/features/tickets/models/ticket_model.dart';
import 'package:e_ticketing/features/tickets/providers/ticket_provider.dart';
import 'package:e_ticketing/features/auth/providers/auth_provider.dart';
import 'package:e_ticketing/features/tickets/providers/helpdesk_provider.dart';
import 'package:e_ticketing/core/network/dio_client.dart';
import 'package:e_ticketing/core/constants/api_constants.dart';
import 'package:e_ticketing/core/theme/app_colors.dart';
import 'package:e_ticketing/core/theme/status_colors.dart';

class TicketListScreen extends ConsumerStatefulWidget {
  const TicketListScreen({super.key});

  @override
  ConsumerState<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends ConsumerState<TicketListScreen> {
  String selectedFilter = 'ALL';
  String searchQuery = '';
  final List<String> filters = ['ALL', 'OPEN', 'IN PROGRESS', 'CLOSED'];
  String? _selectedHelpdeskId;
  Map<String, String> _filterParams = const <String, String>{};

  Future<void> _patchAssign(String ticketId, String? helpdeskId) async {
    try {
      final dio = ref.read(dioProvider).instance;
      await dio.patch('${ApiConstants.tickets}/$ticketId',
          data: {'assignedToId': helpdeskId});
      ref.invalidate(ticketsProvider);
      ref.invalidate(filteredTicketsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment updated')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update assignment')),
        );
      }
    }
  }

  void _showAssignSheet(Ticket ticket) {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Consumer(
        builder: (ctx, sheetRef, _) {
          final helpdesksAsync = sheetRef.watch(helpdesksProvider);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: colors.surfaceBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Assign Helpdesk — ${ticket.title}',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Divider(height: 1),
              helpdesksAsync.when(
                data: (helpdesks) => Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      ListTile(
                        title: const Text('Unassigned',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        trailing: ticket.assignedToId == null
                          ? Icon(LucideIcons.check, size: 16, color: colors.textPrimary)
                          : null,
                        onTap: () {
                          Navigator.pop(ctx);
                          _patchAssign(ticket.id, null);
                        },
                      ),
                      ...helpdesks.map((h) => ListTile(
                        title: Text(h.name,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: Text(h.email,
                          style: TextStyle(fontSize: 11, color: colors.textMuted)),
                        trailing: ticket.assignedToId == h.id
                          ? Icon(LucideIcons.check, size: 16, color: colors.textPrimary)
                          : null,
                        onTap: () {
                          Navigator.pop(ctx);
                          _patchAssign(ticket.id, h.id);
                        },
                      )),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text('Error loading helpdesk users: $e',
                    style: TextStyle(color: colors.danger)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(filteredTicketsProvider(_filterParams));
    final authState = ref.watch(authProvider).value;
    final isAdmin = authState?.role == 'admin';
    final colors = context.colors;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.surfaceBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: TextField(
                      onChanged: (value) => setState(() => searchQuery = value),
                      style: TextStyle(color: colors.textPrimary),
                      decoration: InputDecoration(
                        icon: Icon(LucideIcons.search, size: 18, color: colors.textMuted),
                        hintText: "Search tickets...",
                        hintStyle: TextStyle(color: colors.textDim),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.accent,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: const Icon(LucideIcons.slidersHorizontal, color: Colors.white, size: 20),
                )
              ],
            ),
          ),

          // Filter Chips
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = filters[index];
                final isSelected = selectedFilter == filter;
                return ChoiceChip(
                  label: Text(filter, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : colors.textMuted)),
                  selected: isSelected,
                  onSelected: (_) => setState(() => selectedFilter = filter),
                  selectedColor: colors.accent,
                  backgroundColor: colors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isSelected ? Colors.transparent : colors.surfaceBorder)),
                  showCheckmark: false,
                  elevation: 2,
                  shadowColor: Colors.black.withValues(alpha: 0.08),
                );
              },
            ),
          ),

          // Helpdesk filter — admin only
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: ref.watch(helpdesksProvider).when(
                data: (helpdesks) => DropdownButtonFormField<String?>(
                  value: _selectedHelpdeskId,
                  decoration: InputDecoration(
                    labelText: 'Filter by helpdesk',
                    labelStyle: const TextStyle(fontSize: 12),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.surfaceBorder)),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('All helpdesks')),
                    ...helpdesks.map((h) => DropdownMenuItem<String?>(
                      value: h.id,
                      child: Text(h.name, style: const TextStyle(fontSize: 13)),
                    )),
                  ],
                  onChanged: (val) => setState(() {
                    _selectedHelpdeskId = val;
                    _filterParams = val != null
                        ? <String, String>{'assignedToId': val}
                        : const <String, String>{};
                  }),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

          // 2. Data-Driven Ticket List
          Expanded(
            child: ticketsAsync.when(
              data: (tickets) {
                // Apply Search and Filter logic locally
                final filteredTickets = tickets.where((ticket) {
                  final matchesFilter = selectedFilter == 'ALL' ||
                      ticket.status.name.toUpperCase().replaceAll('_', ' ') == selectedFilter;
                  final matchesSearch = ticket.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
                      ticket.id.toLowerCase().contains(searchQuery.toLowerCase());
                  return matchesFilter && matchesSearch;
                }).toList();

                if (filteredTickets.isEmpty) {
                  return const Center(child: Text("No records found"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: filteredTickets.length,
                  itemBuilder: (context, index) => _buildTicketCard(context, filteredTickets[index], isAdmin),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text("Sync Error: $err")),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/create-ticket'),
        backgroundColor: colors.accent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Icon(LucideIcons.plus, color: Colors.white, size: 32),
      ),
    );
  }

  // Helper Widget updated to use Ticket Model
  Widget _buildTicketCard(BuildContext context, Ticket ticket, bool isAdmin) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.surfaceBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/ticket-detail', arguments: ticket.id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildBadge(ticket.status.name.toUpperCase(), ticket.statusColor),
                const SizedBox(width: 8),
                _buildBadge(ticket.priority.name.toUpperCase(), StatusColors.forPriority(ticket.priority)),
                const Spacer(),
                if (isAdmin)
                  IconButton(
                    onPressed: () => _showAssignSheet(ticket),
                    icon: Icon(LucideIcons.userPlus, size: 16, color: colors.textSecondary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Assign helpdesk',
                  ),
                if (isAdmin) const SizedBox(width: 8),
                Flexible(child: Text(ticket.createdAt.toString().split(' ')[0],
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: colors.textMuted))),
              ],
            ),
            const SizedBox(height: 16),
            Text(ticket.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary)),
            const SizedBox(height: 8),
            Text(
              ticket.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 16),
            Divider(color: colors.background),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("ID: ${ticket.id.substring(0, 8).toUpperCase()}",
                  style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: colors.textMuted, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Icon(LucideIcons.messageSquare, size: 14, color: colors.textDim),
                    const SizedBox(width: 4),
                    Text("${ticket.commentCount}", style: TextStyle(fontSize: 10, color: colors.textMuted)),
                    const SizedBox(width: 12),
                    Icon(LucideIcons.arrowRight, size: 18, color: colors.textDim),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
    );
  }
}
