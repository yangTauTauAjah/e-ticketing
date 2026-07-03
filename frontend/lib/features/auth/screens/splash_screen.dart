import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_ticketing/features/auth/providers/auth_provider.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<AuthState>>(authProvider, (_, next) {
      next.whenData((state) {
        if (!context.mounted) return;
        if (state.isAuthenticated) {
          Navigator.of(context).pushReplacementNamed('/dashboard');
        } else {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      });
    });

    return const Scaffold(
      backgroundColor: Color(0xFF0F172A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.confirmation_number_outlined, size: 72, color: Colors.white),
            SizedBox(height: 24),
            Text('E-TICKETING',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 4,
              )),
            SizedBox(height: 8),
            Text('HELPDESK SYSTEM',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white38,
                letterSpacing: 3,
                fontWeight: FontWeight.bold,
              )),
            SizedBox(height: 48),
            CircularProgressIndicator(color: Colors.white24, strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}
