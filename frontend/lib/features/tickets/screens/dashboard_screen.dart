import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:e_ticketing/features/tickets/models/ticket_model.dart';
import 'package:e_ticketing/features/tickets/providers/ticket_provider.dart'; // Ensure this uses your real Dio/API logic
import 'package:e_ticketing/features/auth/providers/auth_provider.dart';
import 'package:e_ticketing/core/theme/app_colors.dart';
import 'package:e_ticketing/core/theme/status_colors.dart';
import 'package:e_ticketing/features/notifications/providers/notification_provider.dart';

class CardBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      // A subtle white/blue tint to match the mock's abstract shapes
      ..color = Colors.white.withValues(alpha: 0.04) 
      ..style = PaintingStyle.fill;

    // Center-left circle
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.8), 
      100, 
      paint,
    );

    // Far-right circle
    canvas.drawCircle(
      Offset(size.width * 1.0, 50), 
      70, 
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider).value;
    final ticketsAsync = ref.watch(ticketsProvider);
    final unreadCountAsync = ref.watch(unreadNotificationCountProvider);
    final colors = context.colors;

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
                      color: colors.accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(child: Container(height: 20, width: 20, decoration: BoxDecoration(color: colors.accent, borderRadius: BorderRadius.circular(4)))),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("WELCOME BACK,",
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.textMuted, letterSpacing: 1.5)),
                      Text(authState?.userName ?? 'Adrian Thorne',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colors.textPrimary)),
                    ],
                  ),
                ],
              ),
              Row(
                spacing: 12,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/notifications'),
                    child: Container(
                      height: 44, width: 44,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colors.surfaceBorder),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Icon(LucideIcons.bell, size: 20, color: colors.textMuted),
                          if ((unreadCountAsync.value ?? 0) > 0)
                            Positioned(
                              top: 8, right: 8,
                              child: Container(
                                width: 8, height: 8,
                                decoration: BoxDecoration(color: colors.danger, shape: BoxShape.circle),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: colors.accent,
                    child: Text(
                      authState?.userName?.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)
                    )
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 2. Data-driven Stats Card
          ref.watch(ticketStatsProvider).when(
            data: (stats) => Column(
              children: [
                Container(
                  width: double.infinity,
                  // IMPORTANT: Clips the CustomPaint circles to the border radius
                  clipBehavior: Clip.antiAlias, 
                  decoration: BoxDecoration(
                    gradient: HeroCard.gradient,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: HeroCard.border),
                  ),
                  child: Stack(
                    children: [
                      // Abstract Background Shapes
                      Positioned.fill(
                        child: CustomPaint(
                          painter: CardBackgroundPainter(),
                        ),
                      ),
                      
                      // Card Content
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("TOTAL SUPPORT TICKETS",
                              style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            const SizedBox(height: 8),
                            Text("${stats.total}",
                              style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 24),
                            
                            // Replaced badge grid with the mock's success state layout
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB).withValues(alpha: 0.25), // Transparent Blue
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(LucideIcons.checkCircle2, color: Color(0xFF60A5FA), size: 14),
                                      const SizedBox(width: 6),
                                      Text("${stats.closed} Resolved",
                                        style: const TextStyle(color: Color(0xFF60A5FA), fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Text("OVERALL SUCCESS STATE",
                                  style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                              ],
                            ),
                          ],
                        ),
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
              _buildQuickAction(colors, LucideIcons.arrowUpRight, "NEW", colors.accent),
              _buildQuickAction(colors, LucideIcons.list, "MY LIST", StatusColors.open),
              _buildQuickAction(colors, LucideIcons.grid, "OPEN", StatusColors.priorityCritical),
              _buildQuickAction(colors, LucideIcons.moreHorizontal, "MORE", StatusColors.inProgress),
            ],
          ),

          const SizedBox(height: 32),

          // 3. Dynamic Support Tracking List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("SUPPORT TRACKING", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.textPrimary, letterSpacing: 1)),
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
  Widget _buildQuickAction(AppColors colors, IconData icon, String label, Color color) {
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
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.textMuted)),
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

  // Real data-driven Ticket Item
  Widget _buildTicketItem(BuildContext context, Ticket ticket) {
    final colors = context.colors;
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/ticket-detail', arguments: ticket.id),
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Container(
              height: 40, width: 40,
              decoration: BoxDecoration(color: ticket.statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(LucideIcons.ticket, color: colors.accent, size: 18),
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
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.textSecondary)),
                      ),
                      const SizedBox(width: 8),
                      // Priority Badge with Color Coding
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: StatusColors.forPriority(ticket.priority).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          ticket.priority.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: StatusColors.forPriority(ticket.priority),
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
                      backgroundColor: colors.surfaceBorder,
                      color: ticket.statusColor,
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
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: colors.textMuted)),
                Text(ticket.createdAt.toString().split(' ')[0],
                  style: TextStyle(fontSize: 8, color: colors.textDim)),
              ],
            )
          ],
        ),
      ),
    );
  }
}
