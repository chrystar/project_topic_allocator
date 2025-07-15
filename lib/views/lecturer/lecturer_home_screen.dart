import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/lecturer_viewmodel.dart';
import '../../viewmodels/navigation_viewmodel.dart';
import 'lecturer_dashboard_screen.dart';
import 'lecturer_topics_screen.dart';
import 'lecturer_students_screen.dart';
import 'lecturer_profile_screen.dart';
import 'lecturer_specializations_screen.dart';

class LecturerHomeScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  const LecturerHomeScreen({super.key, this.onLogout});

  @override
  State<LecturerHomeScreen> createState() => _LecturerHomeScreenState();
}

class _LecturerHomeScreenState extends State<LecturerHomeScreen> {
  int _selectedIndex = 0;
    @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LecturerViewModel()),
        ChangeNotifierProvider(create: (_) => NavigationViewModel()),
      ],
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            // Dashboard
            const LecturerDashboardScreen(),
            
            // Topics
            const LecturerTopicsScreen(),
            
            // Specializations
            const LecturerSpecializationsScreen(),
            
            // Students
            const LecturerStudentsScreen(),
            
            // Profile
            LecturerProfileScreen(onLogout: widget.onLogout),
          ],
        ),        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.topic_outlined),
              selectedIcon: Icon(Icons.topic),
              label: 'Topics',
            ),
            NavigationDestination(
              icon: Icon(Icons.psychology_outlined),
              selectedIcon: Icon(Icons.psychology),
              label: 'Expertise',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Students',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
