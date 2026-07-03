import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:e_ticketing/core/theme/theme_provider.dart';
import 'package:e_ticketing/core/theme/app_colors.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Settings',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSection(context, 'APPEARANCE', [
            _buildSwitchTile(
              context,
              icon: isDark ? LucideIcons.moon : LucideIcons.sun,
              title: 'Dark Mode',
              subtitle: isDark ? 'Dark theme active' : 'Light theme active',
              value: isDark,
              onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
            ),
          ]),
          const SizedBox(height: 24),
          _buildSection(context, 'NOTIFICATIONS', [
            _buildSwitchTile(
              context,
              icon: LucideIcons.bell,
              title: 'Push Notifications',
              subtitle: 'Ticket status updates',
              value: false,
              onChanged: null,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(title,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
              color: colors.textMuted, letterSpacing: 2)),
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.surfaceBorder),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    final colors = context.colors;
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colors.accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 18, color: colors.accent),
      ),
      title: Text(title,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary)),
      subtitle: Text(subtitle,
        style: TextStyle(fontSize: 11, color: colors.textMuted)),
      value: value,
      onChanged: onChanged,
    );
  }
}
