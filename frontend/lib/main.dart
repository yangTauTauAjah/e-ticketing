import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:e_ticketing/core/theme/theme_provider.dart';
import 'package:e_ticketing/core/theme/app_colors.dart';
import 'package:e_ticketing/features/tickets/screens/dashboard_screen.dart';
import 'package:e_ticketing/features/tickets/screens/ticket_list_screen.dart';
import 'package:e_ticketing/features/profile/screens/profile_screen.dart';
import 'package:e_ticketing/features/auth/screens/login_screen.dart';
import 'package:e_ticketing/features/auth/screens/splash_screen.dart';
import 'package:e_ticketing/features/tickets/screens/create_ticket_screen.dart';
import 'package:e_ticketing/features/tickets/screens/ticket_detail_screen.dart';
import 'package:e_ticketing/features/tickets/screens/ticket_tracking_screen.dart';
import 'package:e_ticketing/features/settings/screens/settings_screen.dart';
import 'package:e_ticketing/features/settings/screens/security_privacy_screen.dart';
import 'package:e_ticketing/features/admin/screens/user_management_screen.dart';
import 'package:e_ticketing/features/notifications/screens/notifications_screen.dart';

void main() {
  runApp(
    const ProviderScope( // Required for Riverpod
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'E-Ticket',
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.light.background,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.light.textPrimary),
        extensions: const [AppColors.light],
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.dark.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.dark.accent,
          brightness: Brightness.dark,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.dark.background,
          foregroundColor: AppColors.dark.textPrimary,
          surfaceTintColor: Colors.transparent,
        ),
        extensions: const [AppColors.dark],
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const MainLayout(),
        '/create-ticket': (context) => const CreateTicketScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/ticket-detail') {
          final ticketId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => TicketDetailScreen(ticketId: ticketId),
          );
        }
        if (settings.name == '/ticket-tracking') {
          final ticketId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => TicketTrackingScreen(ticketId: ticketId),
          );
        }
        if (settings.name == '/settings') {
          return MaterialPageRoute(builder: (context) => const SettingsScreen());
        }
        if (settings.name == '/security-privacy') {
          return MaterialPageRoute(builder: (context) => const SecurityPrivacyScreen());
        }
        if (settings.name == '/admin/users') {
          return MaterialPageRoute(builder: (context) => const UserManagementScreen());
        }
        if (settings.name == '/notifications') {
          return MaterialPageRoute(builder: (context) => const NotificationsScreen());
        }
        return null;
      },
    );
  }
}

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _selectedIndex = 0;

  // List of screens corresponding to the Bottom Nav
  static const List<Widget> _screens = [
    DashboardScreen(), // Home
    TicketListScreen(), // Tickets
    ProfileScreen(),    // Account
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      /* appBar: AppBar(
        toolbarHeight: 100.0,
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        elevation: 0,
        titleSpacing: 24,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("E-TICKETING", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 2)),
            Text(_selectedIndex == 0 ? "Dashboard" : _selectedIndex == 1 ? "Tickets" : "Profile", 
              style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.bell, color: Color(0xFF94A3B8), size: 20),
            onPressed: () {},
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(radius: 16, backgroundColor: Colors.blue, child: Text("S", style: TextStyle(color: Colors.white, fontSize: 12))),
          )
        ],
      ), */
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colors.background,
          border: Border(top: BorderSide(color: colors.surfaceBorder)),
        ),
        child: BottomNavigationBar(
          backgroundColor: colors.background,
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: colors.accent,
          unselectedItemColor: colors.textMuted,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
          items: const [
            BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: "HOME"),
            BottomNavigationBarItem(icon: Icon(LucideIcons.ticket), label: "TICKETS"),
            BottomNavigationBarItem(icon: Icon(LucideIcons.user), label: "ACCOUNT"),
          ],
        ),
      ),
    );
  }
}