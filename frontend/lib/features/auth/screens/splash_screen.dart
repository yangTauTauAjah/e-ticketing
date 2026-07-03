import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_ticketing/features/auth/providers/auth_provider.dart';
import 'package:e_ticketing/core/theme/app_colors.dart';

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
    final colors = context.colors;

    return Scaffold(
      backgroundColor: AppColors.dark.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon(Icons.confirmation_number_outlined, size: 72, color: Colors.white),
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
            SizedBox(height: 32),
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
            SizedBox(height: 32),
            CircularProgressIndicator(color: Colors.white24, strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}
