import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:e_ticketing/features/tickets/models/ticket_model.dart';
import 'package:e_ticketing/features/tickets/providers/ticket_provider.dart'; // Ensure this uses your real Dio/API logic
import 'package:e_ticketing/features/auth/providers/auth_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider).value;
    final ticketsAsync = ref.watch(ticketsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                spacing: 12,
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A), 
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Center(child: Container(height: 20, width: 20, decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(4)))),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("WELCOME BACK,", 
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 1.5)),
                      Text(authState?.userName ?? 'Adrian Thorne', 
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A), 
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: CircleAvatar(
                  radius: 20, 
                  backgroundColor: Colors.blue, 
                  child: Text(
                    authState?.userName?.substring(0, 1).toUpperCase() ?? 'U', 
                    style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)
                  )
                ),
              ),
              /* CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFF1F5F9),
                child: Text(authState?.userName?.substring(0, 1) ?? 'A', 
                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ) */
            ],
          ),
          const SizedBox(height: 24),
          
          // 2. Data-driven Stats Card
          ref.watch(ticketStatsProvider).when(
            data: (stats) => Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("TOTAL SUPPORT TICKETS",
                        style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      const SizedBox(height: 8),
                      Text("${stats.total}",
                        style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildStatBadge("OPEN", stats.open, Colors.blue),
                          const SizedBox(width: 8),
                          _buildStatBadge("IN PROGRESS", stats.inProgress, Colors.orange),
                          const SizedBox(width: 8),
                          _buildStatBadge("ON HOLD", stats.onHold, Colors.amber),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildStatBadge("CLOSED", stats.closed, Colors.green),
                          const SizedBox(width: 8),
                          _buildStatBadge("REOPENED", stats.reopened, Colors.red),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text("Error loading stats: $err"),
          ),

          const SizedBox(height: 32),

          // Quick Actions Grid (Static for now, matches UI reqs)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildQuickAction(LucideIcons.arrowUpRight, "NEW", Colors.blue),
              _buildQuickAction(LucideIcons.list, "MY LIST", Colors.green),
              _buildQuickAction(LucideIcons.grid, "OPEN", Colors.purple),
              _buildQuickAction(LucideIcons.moreHorizontal, "MORE", Colors.orange),
            ],
          ),
          
          const SizedBox(height: 32),

          // 3. Dynamic Support Tracking List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("SUPPORT TRACKING", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: 1)),
              TextButton(onPressed: () {}, child: const Text("VIEW ALL", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
            ],
          ),
          ticketsAsync.when(
            data: (tickets) => ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tickets.take(5).length, // Only show recent 5
              itemBuilder: (context, index) => _buildTicketItem(context, tickets[index]),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (err, _) => const Center(child: Text("FAILED TO SYNC RECORDS")),
          ),
        ],
      ),
    );
  }
  // Helper Widget for Quick Actions
  Widget _buildQuickAction(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          height: 56, width: 56,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
      ],
    );
  }

  // Helper Widget for Stat Badges
  Widget _buildStatBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("$count", style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // Helper to get priority color
  Color _getPriorityColor(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low:
        return const Color(0xFF10B981); // Green
      case TicketPriority.medium:
        return const Color(0xFFF59E0B); // Amber
      case TicketPriority.high:
        return const Color(0xFFEF4444); // Red
      case TicketPriority.critical:
        return const Color(0xFF7C3AED); // Purple
    }
  }

  // Real data-driven Ticket Item
  Widget _buildTicketItem(BuildContext context, Ticket ticket) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/ticket-detail', arguments: ticket.id),
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 40, width: 40,
              decoration: BoxDecoration(color: ticket.statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(LucideIcons.ticket, color: Colors.blue, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(ticket.title, 
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                      ),
                      const SizedBox(width: 8),
                      // Priority Badge with Color Coding
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(ticket.priority).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          ticket.priority.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: _getPriorityColor(ticket.priority),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Progress Bar from Dashboard.tsx
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ticket.status == TicketStatus.closed ? 1.0 : ticket.status == TicketStatus.in_progress ? 0.5 : 0.1,
                      minHeight: 4,
                      backgroundColor: const Color(0xFFF1F5F9),
                      color: ticket.status == TicketStatus.closed ? Colors.green : ticket.status == TicketStatus.in_progress ? Colors.blue : Colors.orange,
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(ticket.status.name.toUpperCase(), 
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                Text(ticket.createdAt.toString().split(' ')[0], 
                  style: const TextStyle(fontSize: 8, color: Color(0xFFCBD5E1))),
              ],
            )
          ],
        ),
      ),
    );
  }
}