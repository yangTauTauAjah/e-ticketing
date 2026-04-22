import 'package:flutter/material.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), 
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 1.5)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)), // slate-100
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
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFFCBD5E1)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
            ),
          ),
        ),
      ],
    );
  }
}