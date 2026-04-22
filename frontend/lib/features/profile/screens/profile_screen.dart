import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:e_ticketing/features/auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  // Function to handle logout based on BACKEND_SPEC.md
  Future<void> _handleLogout(WidgetRef ref, BuildContext context) async {
    const storage = FlutterSecureStorage();
    
    // 1. Clear the local JWT token
    await storage.delete(key: 'jwt_token');
    
    // 2. Reset the Auth Notifier state
    ref.read(authProvider.notifier).logout();
    
    // 3. Navigate back to Login
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the real auth state
    final authState = ref.watch(authProvider).value;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Profile Header with real user data
          Center(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A), 
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 40, 
                        backgroundColor: Colors.blue, 
                        child: Text(
                          authState?.userName?.substring(0, 1).toUpperCase() ?? 'U', 
                          style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)
                        )
                      ),
                    ),
                    Container(
                      height: 24, 
                      width: 24, 
                      decoration: BoxDecoration(
                        color: Colors.green, 
                        shape: BoxShape.circle, 
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ],
                      )
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  authState?.userName ?? "User", 
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))
                ),
                Text(
                  "${authState?.role?.toUpperCase() ?? 'USER'} REGISTRY ACCESS", 
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 2)
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Status Cards
          Row(
            children: [
              _buildSmallStatCard("AFFILIATION", "IT SERVICES"),
              const SizedBox(width: 16),
              _buildSmallStatCard(
                "STATUS", 
                authState?.isAuthenticated == true ? "AUTHENTICATED" : "OFFLINE", 
                textColor: Colors.green
              ),
            ],
          ),
          const SizedBox(height: 24),          // Account Management List
          Container(
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(32), 
              border: Border.all(color: const Color(0xFFF1F5F9)),
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
                _buildProfileAction(LucideIcons.settings, "System Configuration", "Adjust registry preferences"),
                _buildProfileAction(LucideIcons.shield, "Security & Privacy", "Biometric & Session keys"),
                _buildProfileAction(LucideIcons.bell, "Notification Stream", "Push and email routing"),
                // Logout Action
                _buildProfileAction(
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
  Widget _buildSmallStatCard(String label, String value, {Color? textColor}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(20), 
          border: Border.all(color: const Color(0xFFF1F5F9)),
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
            Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
            Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor ?? const Color(0xFF0F172A))),
          ],
        ),
      ),
    );
  }
  Widget _buildProfileAction(IconData icon, String title, String sub, {bool isDestructive = false, VoidCallback? onTap}) {
    final color = isDestructive ? Colors.red : const Color(0xFF0F172A);
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05), 
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        subtitle: Text(sub.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color.withValues(alpha: 0.4))),
        trailing: const Icon(LucideIcons.chevronRight, size: 18, color: Color(0xFFE2E8F0)),
      ),
    );
  }
}