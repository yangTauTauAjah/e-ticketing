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

          // 3. New Performance Analytics Section
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "PERFORMANCE ANALYTICS",
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.textPrimary, letterSpacing: 1)
            ),
          ),
          const SizedBox(height: 16),
          statsAsync.when(
            data: (stats) => Row(
              children: [
                _buildSmallStatCard(context, "TOTAL", "${stats.total}", textColor: colors.accent),
                const SizedBox(width: 16),
                _buildSmallStatCard(context, "OPEN", "${stats.open}", textColor: StatusColors.open),
                const SizedBox(width: 16),
                _buildSmallStatCard(context, "RESOLVED", "${stats.closed}", textColor: StatusColors.closed),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
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