import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:e_ticketing/core/constants/api_constants.dart';
import 'package:e_ticketing/core/network/dio_client.dart';
import 'package:e_ticketing/features/admin/models/admin_user_model.dart';
import 'package:e_ticketing/features/admin/providers/admin_user_provider.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  String _search = '';
  bool _isUpdating = false;

  Future<void> _toggleActive(AdminUser user) async {
    setState(() => _isUpdating = true);
    try {
      final dio = ref.read(dioProvider).instance;
      await dio.patch(
        '${ApiConstants.usersAdmin}/${user.id}/active',
        data: {'isActive': !user.isActive},
      );
      ref.invalidate(adminUsersProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update user status')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('User Management',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(LucideIcons.search, size: 18, color: Color(0xFF94A3B8)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFF1F5F9))),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: usersAsync.when(
              data: (users) {
                final filtered = _search.isEmpty ? users : users.where((u) =>
                  u.name.toLowerCase().contains(_search.toLowerCase()) ||
                  u.email.toLowerCase().contains(_search.toLowerCase())).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No users found',
                    style: TextStyle(color: Color(0xFF94A3B8))));
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final user = filtered[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: _roleColor(user.role).withValues(alpha: 0.15),
                            child: Text(user.name.substring(0, 1).toUpperCase(),
                              style: TextStyle(color: _roleColor(user.role), fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.name,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                Text(user.email,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    _buildRoleBadge(user.role),
                                    const SizedBox(width: 8),
                                    _buildActiveBadge(user.isActive),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: user.isActive,
                            onChanged: _isUpdating ? null : (_) => _toggleActive(user),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin': return Colors.purple;
      case 'helpdesk': return Colors.blue;
      default: return Colors.green;
    }
  }

  Widget _buildRoleBadge(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _roleColor(role).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(role.toUpperCase(),
        style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: _roleColor(role))),
    );
  }

  Widget _buildActiveBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (isActive ? Colors.green : Colors.red).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(isActive ? 'ACTIVE' : 'INACTIVE',
        style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold,
          color: isActive ? Colors.green : Colors.red)),
    );
  }
}
