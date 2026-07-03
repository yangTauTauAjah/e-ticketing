import 'package:e_ticketing/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_ticketing/widgets/auth_text_field.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:e_ticketing/features/auth/screens/register_screen.dart';
import 'package:e_ticketing/features/auth/screens/reset_password.dart';
import 'package:e_ticketing/core/theme/app_colors.dart';
import 'package:e_ticketing/core/network/api_error.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late TextEditingController emailController;
  late TextEditingController passController;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passController = TextEditingController();
  }

  @override
  void dispose() {
    emailController.dispose();
    passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final colors = context.colors;

    // Listen to auth state changes and navigate if authenticated
    ref.listen(authProvider, (previous, next) {
      next.when(
        data: (authState) {
          if (authState.isAuthenticated) {
            Navigator.of(context).pushReplacementNamed('/dashboard');
          }
        },        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(extractErrorMessage(error, fallback: 'Invalid email or password')), backgroundColor: Colors.red),
          );
        },
        loading: () {},
      );
    });

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            // Logo - Centered and Rotated
            Transform.rotate(
              angle: 0.15, // Slight rotation in radians (~8.6 degrees)
              child: Container(
                height: 100, width: 100,
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Center(child: Container(height: 40, width: 40, decoration: BoxDecoration(color: colors.accent, borderRadius: BorderRadius.circular(8)))),
              ),
            ),
            const SizedBox(height: 40),
            Text("Secure Access", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.textMuted, letterSpacing: 2)),
            Text("Sign in to E-Ticket", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: colors.textPrimary, letterSpacing: -1)),
            const SizedBox(height: 40),
            AuthTextField(label: "Email Address", hint: "name@company.com", icon: LucideIcons.mail, controller: emailController),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Password", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.textMuted, letterSpacing: 1.5)),
                    TextButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ResetPasswordScreen()));
                      },
                      child: Text("Forgot password?", style: TextStyle(fontSize: 10, color: colors.accent, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ),
                  ]
                ),
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
                    controller: passController,
                    obscureText: true,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colors.textPrimary),
                    decoration: InputDecoration(
                      prefixIcon: Icon(LucideIcons.lock, size: 18, color: colors.textMuted),
                      hintText: "••••••••",
                      hintStyle: TextStyle(color: colors.textDim),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: auth.isLoading ? null : () => ref.read(authProvider.notifier).login(emailController.text, passController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 4,
                  shadowColor: Colors.black.withValues(alpha: 0.15),
                ),
                child: auth.isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Continue To Dashboard", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 16)),
              ),
            ),
            // Register Link
            Center(
              child: TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                child: Text.rich(TextSpan(children: [
                  TextSpan(text: "New to the platform? ", style: TextStyle(color: colors.textMuted)),
                  TextSpan(text: "Register an account", style: TextStyle(color: colors.accent, fontWeight: FontWeight.bold)),
                ], style: const TextStyle(fontSize: 10, letterSpacing: 1))),
              ),
            )
          ],
        ),
      ),
    );
  }
}
