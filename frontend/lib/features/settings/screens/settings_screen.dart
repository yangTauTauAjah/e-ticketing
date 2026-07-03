import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:e_ticketing/core/theme/theme_provider.dart';

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
          _buildSection('APPEARANCE', [
            _buildSwitchTile(
              icon: isDark ? LucideIcons.moon : LucideIcons.sun,
              title: 'Dark Mode',
              subtitle: isDark ? 'Dark theme active' : 'Light theme active',
              value: isDark,
              onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
            ),
          ]),
          const SizedBox(height: 24),
          _buildSection('NOTIFICATIONS', [
            _buildSwitchTile(
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

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(title,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
              color: Color(0xFF94A3B8), letterSpacing: 2)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF0F172A)),
      ),
      title: Text(title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
      subtitle: Text(subtitle,
        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
      value: value,
      onChanged: onChanged,
    );
  }
}
