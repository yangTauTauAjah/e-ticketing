import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:e_ticketing/widgets/auth_text_field.dart';
import 'package:e_ticketing/core/theme/app_colors.dart';
import 'package:e_ticketing/core/constants/api_constants.dart';
import 'package:e_ticketing/core/network/dio_client.dart';
import 'package:e_ticketing/core/network/api_error.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _otpSent = false;
  bool _isSuccess = false;
  bool _isLoading = false;
  String? _error;

  Future<void> _requestOtp() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() => _error = 'Enter your email address');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dio = ref.read(dioProvider).instance;
      await dio.post(ApiConstants.forgotPasswordRequest, data: {
        'email': _emailController.text.trim(),
      });
      if (mounted) setState(() => _otpSent = true);
    } catch (e) {
      setState(() => _error = extractErrorMessage(e, fallback: 'Failed to send verification code'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmReset() async {
    if (_otpController.text.trim().length != 6) {
      setState(() => _error = 'Enter the 6-digit code sent to your email');
      return;
    }
    if (_newPasswordController.text.length < 8) {
      setState(() => _error = 'New password must be at least 8 characters');
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dio = ref.read(dioProvider).instance;
      await dio.post(ApiConstants.forgotPasswordConfirm, data: {
        'email': _emailController.text.trim(),
        'otp': _otpController.text.trim(),
        'newPassword': _newPasswordController.text,
      });
      if (mounted) setState(() => _isSuccess = true);
    } catch (e) {
      setState(() => _error = extractErrorMessage(e, fallback: 'Invalid or expired verification code'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
          child: _isSuccess
            ? _buildSuccessView(context)
            : (_otpSent ? _buildOtpView(context) : _buildEmailView(context)),
        ),
      ),
    );
  }

  Widget _buildEmailView(BuildContext context) {
    final colors = context.colors;
    return Column(
      key: const ValueKey('email'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Account Recovery",
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.textMuted, letterSpacing: 2)),
        Text("Reset Password",
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: colors.textPrimary, letterSpacing: -1)),
        const SizedBox(height: 12),
        Text("We'll email a 6-digit verification code to confirm it's you.",
          style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.4)),
        const SizedBox(height: 28),

        AuthTextField(
          label: "Email Address",
          hint: "name@example.com",
          icon: LucideIcons.mail,
          controller: _emailController
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: TextStyle(color: colors.danger, fontSize: 12)),
        ],
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _requestOtp,
            icon: _isLoading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(LucideIcons.send, size: 18, color: Colors.white),
            label: Text(_isLoading ? "Sending Code..." : "Send Verification Code", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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

  Widget _buildOtpView(BuildContext context) {
    final colors = context.colors;
    return Column(
      key: const ValueKey('otp'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Verify & Reset",
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.textMuted, letterSpacing: 2)),
        Text("Enter Code",
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: colors.textPrimary, letterSpacing: -1)),
        const SizedBox(height: 12),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: "A 6-digit code was sent to "),
              TextSpan(text: _emailController.text.trim(), style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary)),
              const TextSpan(text: "."),
            ],
          ),
          style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 28),

        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: TextStyle(color: colors.textPrimary, letterSpacing: 4),
          decoration: InputDecoration(
            labelText: 'Verification code',
            counterText: '',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _newPasswordController,
          obscureText: true,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            labelText: 'New password',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmPasswordController,
          obscureText: true,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            labelText: 'Confirm new password',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: TextStyle(color: colors.danger, fontSize: 12)),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _confirmReset,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent,
              padding: const EdgeInsets.symmetric(vertical: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.15),
            ),
            child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text("Confirm Reset", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
        Center(
          child: TextButton(
            onPressed: _isLoading ? null : () => setState(() => _otpSent = false),
            child: const Text("Use a different email"),
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
          Text("Password Reset!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colors.textPrimary)),
          const SizedBox(height: 12),
          Text("You can now sign in with your new password.",
            textAlign: TextAlign.center,
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
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
