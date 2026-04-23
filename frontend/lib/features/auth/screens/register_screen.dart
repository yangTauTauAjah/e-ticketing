import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:e_ticketing/widgets/auth_text_field.dart';
import 'package:e_ticketing/features/auth/providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController passController;
  late TextEditingController phoneController;
  late TextEditingController confirmPassController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    emailController = TextEditingController();
    passController = TextEditingController();
    phoneController = TextEditingController();
    confirmPassController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passController.dispose();
    phoneController.dispose();
    confirmPassController.dispose();
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
        },
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString()), backgroundColor: Colors.red),
          );
        },
        loading: () {},
      );
    });

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "NEW ACCOUNT",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF94A3B8),
                letterSpacing: 2,
              ),
            ),
            const Text(
              "Join E-Ticket",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 40),
            AuthTextField(
              label: "Full Name",
              hint: "John Doe",
              icon: LucideIcons.user,
              controller: nameController,
            ),
            const SizedBox(height: 24),
            AuthTextField(
              label: "Email Address",
              hint: "name@example.com",
              icon: LucideIcons.mail,
              controller: emailController,
            ),
            const SizedBox(height: 24),
            AuthTextField(
              label: "Phone Number (Optional)",
              hint: "123-456-7890",
              icon: LucideIcons.phone,
              controller: phoneController,
            ),
            const SizedBox(height: 24),
            AuthTextField(
              label: "Password",
              hint: "••••••••",
              icon: LucideIcons.lock,
              isPassword: true,
              controller: passController,
            ),
            const SizedBox(height: 24),
            AuthTextField(
              label: "Confirm Password",
              hint: "••••••••",
              icon: LucideIcons.shieldCheck,
              isPassword: true,
              controller: confirmPassController,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: auth.isLoading
                  ? null
                  : () async {
                      if (passController.text == confirmPassController.text) {
                        final success = await ref.read(authProvider.notifier)
                          .register(
                            nameController.text,
                            emailController.text,
                            phoneController.text,
                            passController.text,
                          );

                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Registration Successful! Please login to continue."),
                              backgroundColor: Colors.green,
                            ),
                          );

                          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Passwords do not match"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 4,
                  shadowColor: Colors.black.withValues(alpha: 0.15),
                ),
                child: auth.when(
                  loading: () => const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  data: (_) => const Text(
                    "Create Account",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16
                    ),
                  ),
                  error: (_, __) => const Text(
                    "Create Account",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
