import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:e_ticketing/features/tickets/screens/dashboard_screen.dart';
import 'package:e_ticketing/features/tickets/screens/ticket_list_screen.dart';
import 'package:e_ticketing/features/profile/screens/profile_screen.dart';
import 'package:e_ticketing/features/auth/screens/login_screen.dart';
import 'package:e_ticketing/features/tickets/screens/create_ticket_screen.dart';
import 'package:e_ticketing/features/tickets/screens/ticket_detail_screen.dart';

void main() {
  runApp(
    const ProviderScope( // Required for Riverpod
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'E-Ticket',      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: const LoginScreen(),
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
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF1F5F9)))),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: Colors.blue,
          unselectedItemColor: const Color(0xFF94A3B8),
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