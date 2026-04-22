import 'package:e_ticketing/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_ticketing/widgets/auth_text_field.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:e_ticketing/features/auth/screens/register_screen.dart';
import 'package:e_ticketing/features/auth/screens/reset_password.dart';

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

    // Listen to auth state changes and navigate if authenticated
    ref.listen(authProvider, (previous, next) {
      next.when(
        data: (authState) {
          if (authState.isAuthenticated) {
            Navigator.of(context).pushReplacementNamed('/dashboard');
          }
        },        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString()), backgroundColor: Colors.red),
          );
        },
        loading: () {},
      );
    });

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [            const SizedBox(height: 60),
            // Logo from Screenshot
            Container(
              height: 48, width: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A), 
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Center(child: Container(height: 20, width: 20, decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(4)))),
            ),
            const SizedBox(height: 40),
            const Text("SECURE ACCESS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 2)),
            const Text("Sign in to E-Ticket", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -1)),
            const SizedBox(height: 40),
              AuthTextField(label: "Email Address", hint: "name@company.com", icon: LucideIcons.mail, controller: emailController),
            const SizedBox(height: 24),
            AuthTextField(label: "Password", hint: "••••••••", icon: LucideIcons.lock, isPassword: true, controller: passController),
              // Forgot Password Link
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ResetPasswordScreen()));
                },
                child: const Text("Forgot password?", style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
            ),
            
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: auth.isLoading ? null : () => ref.read(authProvider.notifier).login(emailController.text, passController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
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
                child: const Text.rich(TextSpan(children: [
                  TextSpan(text: "New to the platform? ", style: TextStyle(color: Color(0xFF94A3B8))),
                  TextSpan(text: "Register an account", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                ], style: TextStyle(fontSize: 10, letterSpacing: 1))),
              ),
            )
          ],
        ),
      ),
    );
  }
}