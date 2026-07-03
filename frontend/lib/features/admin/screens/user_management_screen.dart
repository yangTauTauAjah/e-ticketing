import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:e_ticketing/core/constants/api_constants.dart';
import 'package:e_ticketing/core/network/dio_client.dart';
import 'package:e_ticketing/features/admin/models/admin_user_model.dart';
import 'package:e_ticketing/features/admin/providers/admin_user_provider.dart';
import 'package:e_ticketing/core/theme/app_colors.dart';
import 'package:e_ticketing/features/auth/providers/auth_provider.dart';
import 'package:e_ticketing/core/network/api_error.dart';

const _roles = ['user', 'helpdesk', 'admin'];
const _monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String _formatDate(DateTime date) => '${_monthNames[date.month - 1]} ${date.day}, ${date.year}';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  String _search = '';

  Future<void> _showEditUserSheet(AdminUser user) async {
    final colors = context.colors;
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    String role = user.role;
    bool isActive = user.isActive;
    bool isSaving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          Future<void> saveChanges() async {
            setSheetState(() => isSaving = true);
            try {
              final dio = ref.read(dioProvider).instance;
              await dio.patch('${ApiConstants.usersAdmin}/${user.id}', data: {
                'name': nameController.text.trim(),
                'email': emailController.text.trim(),
                'role': role,
                'isActive': isActive,
              });
              ref.invalidate(adminUsersProvider);
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User updated successfully')),
                );
              }
            } catch (e) {
              setSheetState(() => isSaving = false);
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(extractErrorMessage(e, fallback: 'Failed to update user'))),
                );
              }
            }
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: colors.surfaceBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text('Edit User', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary)),
                  Text('Joined ${_formatDate(user.createdAt)}', style: TextStyle(fontSize: 11, color: colors.textMuted)),
                  const SizedBox(height: 20),

                  Text('NAME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.textMuted, letterSpacing: 1)),
                  const SizedBox(height: 6),
                  TextField(controller: nameController, style: TextStyle(color: colors.textPrimary)),
                  const SizedBox(height: 16),

                  Text('EMAIL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.textMuted, letterSpacing: 1)),
                  const SizedBox(height: 6),
                  TextField(controller: emailController, style: TextStyle(color: colors.textPrimary)),
                  const SizedBox(height: 16),

                  Text('ROLE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.textMuted, letterSpacing: 1)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: role,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colors.surfaceBorder)),
                    ),
                    items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase()))).toList(),
                    onChanged: (val) => setSheetState(() => role = val ?? role),
                  ),
                  const SizedBox(height: 16),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Active', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary)),
                    subtitle: Text(isActive ? 'User can sign in' : 'User is blocked from signing in',
                      style: TextStyle(fontSize: 11, color: colors.textMuted)),
                    value: isActive,
                    onChanged: (val) => setSheetState(() => isActive = val),
                  ),
                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.accent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);
    final currentUserId = ref.watch(authProvider).value?.id;
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text('User Management',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: Icon(LucideIcons.search, size: 18, color: colors.textMuted),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colors.surfaceBorder)),
                filled: true,
                fillColor: colors.surface,
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
                  return Center(child: Text('No users found',
                    style: TextStyle(color: colors.textMuted)));
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final user = filtered[index];
                    final isSelf = user.id == currentUserId;
                    return Opacity(
                      opacity: isSelf ? 0.6 : 1,
                      child: InkWell(
                        onTap: isSelf ? null : () => _showEditUserSheet(user),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colors.surfaceBorder),
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
                                    Row(
                                      children: [
                                        Text(user.name,
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary)),
                                        if (isSelf) ...[
                                          const SizedBox(width: 6),
                                          Text('(You)', style: TextStyle(fontSize: 11, color: colors.textMuted)),
                                        ],
                                      ],
                                    ),
                                    Text(user.email,
                                      style: TextStyle(fontSize: 11, color: colors.textMuted)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        _buildRoleBadge(user.role),
                                        const SizedBox(width: 8),
                                        _buildActiveBadge(context, user.isActive),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Joined ${_formatDate(user.createdAt)}',
                                      style: TextStyle(fontSize: 10, color: colors.textDim)),
                                  ],
                                ),
                              ),
                              Icon(isSelf ? LucideIcons.lock : LucideIcons.chevronRight, size: 18, color: colors.textDim),
                            ],
                          ),
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

  Widget _buildActiveBadge(BuildContext context, bool isActive) {
    final colors = context.colors;
    final color = isActive ? colors.success : colors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(isActive ? 'ACTIVE' : 'INACTIVE',
        style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold,
          color: color)),
    );
  }
}
