import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:e_ticketing/features/auth/providers/auth_provider.dart';
import 'package:e_ticketing/core/theme/app_colors.dart';
import 'package:e_ticketing/features/tickets/providers/ticket_provider.dart';
import 'package:e_ticketing/core/theme/status_colors.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  // Function to handle logout based on BACKEND_SPEC.md[cite: 5]
  Future<void> _handleLogout(WidgetRef ref, BuildContext context) async {
    const storage = FlutterSecureStorage();

    // 1. Clear the local JWT token[cite: 5]
    await storage.delete(key: 'jwt_token');

    // 2. Reset the Auth Notifier state[cite: 5]
    ref.read(authProvider.notifier).logout();

    // 3. Navigate back to Login[cite: 5]
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the real auth state[cite: 5]
    final authState = ref.watch(authProvider).value;
    final colors = context.colors;
    
    // 2. Watch the ticket stats provider to fetch the analytics data
    final statsAsync = ref.watch(ticketStatsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Profile Header with real user data[cite: 5]
          Center(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colors.accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(45),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 65,
                        backgroundColor: colors.accent,
                        child: Text(
                          authState?.userName?.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold)
                        )
                      ),
                    ),
                    Container(
                      height: 32,
                      width: 32,
                      decoration: BoxDecoration(
                        color: colors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.background, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: colors.success.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ],
                      )
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  authState?.userName ?? "User",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: colors.textPrimary)
                ),
                Text(
                  "${authState?.role?.toUpperCase() ?? 'USER'} REGISTRY ACCESS",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.textMuted, letterSpacing: 2)
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Status Cards[cite: 5]
          Row(
            children: [
              _buildSmallStatCard(context, "ROLE", authState?.role?.toUpperCase() ?? "USER"),
              const SizedBox(width: 16),
              _buildSmallStatCard(
                context,
                "STATUS",
                authState?.isAuthenticated == true ? "AUTHENTICATED" : "OFFLINE",
                textColor: colors.success
              ),
            ],
          ),
          const SizedBox(height: 32),

          // 3. Performance Analytics Section: status breakdown donut + derived metrics
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "PERFORMANCE ANALYTICS",
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.textPrimary, letterSpacing: 1)
            ),
          ),
          const SizedBox(height: 16),
          statsAsync.when(
            data: (stats) => _buildAnalyticsCard(context, stats),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Center(
              child: Text("Analytics unavailable", style: TextStyle(color: colors.danger, fontSize: 12))
            ),
          ),
          const SizedBox(height: 32),

          // Account Management List[cite: 5]
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: colors.surfaceBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              children: [
                _buildProfileAction(
                  context,
                  LucideIcons.settings, "System Configuration", "Adjust registry preferences",
                  onTap: () => Navigator.pushNamed(context, '/settings'),
                ),
                _buildProfileAction(
                  context,
                  LucideIcons.shield, "Security & Privacy", "Account security & password reset",
                  onTap: () => Navigator.pushNamed(context, '/security-privacy'),
                ),
                _buildProfileAction(
                  context,
                  LucideIcons.bell, "Notification Stream", "Push and email routing",
                  onTap: () => Navigator.pushNamed(context, '/notifications'),
                ),
                if (authState?.role == 'admin')
                  _buildProfileAction(
                    context,
                    LucideIcons.users, "User Management", "Manage accounts & roles",
                    onTap: () => Navigator.pushNamed(context, '/admin/users'),
                  ),
                // Logout Action[cite: 5]
                _buildProfileAction(
                  context,
                  LucideIcons.logOut,
                  "Logout",
                  "Safely exit registry",
                  isDestructive: true,
                  onTap: () => _handleLogout(ref, context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStatCard(BuildContext context, String label, String value, {Color? textColor}) {
    final colors = context.colors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.textMuted)),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor ?? colors.textPrimary)),
          ],
        ),
      ),
    );
  }

  // Builds the analytics hero card: a status-breakdown donut chart paired
  // with a numerical legend, plus a row of derived KPI metrics
  // (resolution rate, active load, reopen rate) computed from [stats].
  Widget _buildAnalyticsCard(BuildContext context, TicketStats stats) {
    final total = stats.total;
    final resolutionRate = total > 0 ? (stats.closed / total * 100) : 0.0;
    final active = stats.open + stats.inProgress + stats.onHold + stats.reopened;
    final reopenRate = total > 0 ? (stats.reopened / total * 100) : 0.0;

    final segments = <_StatusSegment>[
      _StatusSegment("Open", stats.open, StatusColors.open),
      _StatusSegment("Assigned", stats.onHold, StatusColors.assigned),
      _StatusSegment("In Progress", stats.inProgress, StatusColors.inProgress),
      _StatusSegment("Resolved", stats.closed, StatusColors.closed),
      _StatusSegment("Reopened", stats.reopened, StatusColors.reopened),
    ];

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: HeroCard.gradient,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: HeroCard.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (total == 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                "No tickets logged yet — analytics will appear once activity starts.",
                style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 116,
                  width: 116,
                  child: CustomPaint(
                    painter: _DonutChartPainter(
                      segments: segments,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "${resolutionRate.toStringAsFixed(0)}%",
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            "RESOLVED",
                            style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.6),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: segments.map((s) => _buildLegendRow(s, total)).toList(),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 24),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildHeroMetric("TOTAL TICKETS", "$total", Colors.white)),
              Expanded(child: _buildHeroMetric("ACTIVE LOAD", "$active", StatusColors.open)),
              Expanded(child: _buildHeroMetric("REOPEN RATE", "${reopenRate.toStringAsFixed(0)}%", StatusColors.reopened)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(_StatusSegment segment, int total) {
    final pct = total > 0 ? (segment.value / total * 100) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: segment.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              segment.label.toUpperCase(),
              style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          Text("${segment.value}", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          SizedBox(
            width: 34,
            child: Text(
              "${pct.toStringAsFixed(0)}%",
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMetric(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8),
        ),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valueColor, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildProfileAction(BuildContext context, IconData icon, String title, String sub, {bool isDestructive = false, VoidCallback? onTap}) {
    final colors = context.colors;
    final color = isDestructive ? colors.danger : colors.textPrimary;
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          )
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        leading: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        subtitle: Text(sub.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color.withValues(alpha: 0.4))),
        trailing: Icon(LucideIcons.chevronRight, size: 22, color: colors.textDim),
      ),
    );
  }
}

/// One slice of the ticket-status donut chart: how many tickets are in
/// [label]'s status and which color represents it (sourced from [StatusColors]
/// so it always matches the rest of the app).
class _StatusSegment {
  final String label;
  final int value;
  final Color color;

  const _StatusSegment(this.label, this.value, this.color);
}

/// Paints a multi-segment ring chart proportional to each segment's value,
/// used to visualize the ticket status breakdown without pulling in an
/// external charting dependency.
class _DonutChartPainter extends CustomPainter {
  final List<_StatusSegment> segments;
  final Color backgroundColor;

  const _DonutChartPainter({required this.segments, required this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold<int>(0, (sum, s) => sum + s.value);
    final strokeWidth = size.width * 0.16;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect, 0, 2 * math.pi, false, bgPaint);

    if (total == 0) return;

    // Leave a hairline gap between adjacent slices so they read as distinct.
    const gap = 0.04;
    var startAngle = -math.pi / 2;
    for (final segment in segments) {
      if (segment.value <= 0) continue;
      final sweep = (segment.value / total) * (2 * math.pi - gap * segments.length);
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.segments != segments || oldDelegate.backgroundColor != backgroundColor;
  }
}