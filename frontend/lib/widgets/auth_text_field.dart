import 'package:flutter/material.dart';
import 'package:e_ticketing/core/theme/app_colors.dart';
// import 'package:lucide_icons/lucide_icons.dart';

class AuthTextField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final TextEditingController controller;

  const AuthTextField({
    super.key, 
    required this.label, 
    required this.hint, 
    required this.icon, 
    required this.controller,
    this.isPassword = false
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.textMuted, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.surfaceBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colors.textPrimary),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 18, color: colors.textMuted),
              hintText: hint,
              hintStyle: TextStyle(color: colors.textDim),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
            ),
          ),
        ),
      ],
    );
  }
}