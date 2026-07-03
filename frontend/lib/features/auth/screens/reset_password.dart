import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:e_ticketing/widgets/auth_text_field.dart';
import 'package:e_ticketing/core/theme/app_colors.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isSuccess = false;
  bool _isLoading = false;

  Future<void> _handleReset() async {
    setState(() => _isLoading = true);
    // Replicating mock delay from ResetPassword.tsx
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {
      _isLoading = false;
      _isSuccess = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isSuccess ? _buildSuccessView(context) : _buildFormView(context),
        ),
      ),
    );
  }

  Widget _buildFormView(BuildContext context) {
    final colors = context.colors;
    return Column(
      key: const ValueKey('form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Account Recovery",
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.textMuted, letterSpacing: 2)),
        Text("Reset Password",
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: colors.textPrimary, letterSpacing: -1)),
        const SizedBox(height: 40),

        AuthTextField(
          label: "Email Address",
          hint: "name@example.com",
          icon: LucideIcons.mail,
          controller: _emailController
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleReset,
            icon: _isLoading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(LucideIcons.send, size: 18, color: Colors.white),
            label: Text(_isLoading ? "Sending Request..." : "Send Reset Link", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent,
              padding: const EdgeInsets.symmetric(vertical: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView(BuildContext context) {
    final colors = context.colors;
    return Center(
      key: const ValueKey('success'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: colors.success.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Icon(LucideIcons.checkCircle2, color: colors.success, size: 40),
          ),
          const SizedBox(height: 24),
          Text("Email Sent!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colors.textPrimary)),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: "Check "),
                TextSpan(text: _emailController.text, style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary)),
                const TextSpan(text: " for recovery steps."),
              ],
            ),            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent,
                padding: const EdgeInsets.symmetric(vertical: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 4,
                shadowColor: Colors.black.withValues(alpha: 0.15),
              ),
              child: const Text("RETURN TO LOGIN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
