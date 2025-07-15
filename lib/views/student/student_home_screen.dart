import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/student_viewmodel.dart';
import '../../viewmodels/allocation_viewmodel.dart';
import '../../viewmodels/navigation_viewmodel.dart';
import '../../viewmodels/lecturer_viewmodel.dart';
import 'student_dashboard_screen.dart';
import 'student_interests_screen.dart';
import 'student_topic_screen.dart';
import 'student_profile_screen.dart';
import 'project_recommendations_screen.dart';
import 'student_lecturers_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  const StudentHomeScreen({super.key, this.onLogout});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  static const int _lecturersTabIndex = 4;  
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Create NavigationViewModel for handling navigation
        ChangeNotifierProvider(
          create: (_) => NavigationViewModel(),
        ),
        // Create AllocationViewModel
        ChangeNotifierProvider(
          create: (_) => AllocationViewModel(),
        ),
        // Create LecturerViewModel for project recommendations
        ChangeNotifierProvider(
          create: (_) => LecturerViewModel(),
        ),
        // Create StudentViewModel with access to the AllocationViewModel
        ChangeNotifierProxyProvider<AllocationViewModel, StudentViewModel>(
          create: (_) => StudentViewModel(),
          update: (_, allocationViewModel, studentViewModel) {
            studentViewModel!.setAllocationViewModel(allocationViewModel);
            return studentViewModel;
          },
        ),
      ],
      child: Consumer<NavigationViewModel>(
        builder: (context, navigationModel, _) {
          return Scaffold(            body: IndexedStack(
              index: navigationModel.selectedIndex,
              children: [                // Dashboard
                const StudentDashboardScreen(),
                // Interests
                const StudentInterestsScreen(),
                // Project Recommendations
                const ProjectRecommendationsScreen(),
                // Topic
                const StudentTopicScreen(),
                // Lecturers
                const StudentLecturersScreen(),
                // Profile
                StudentProfileScreen(onLogout: widget.onLogout),
              ],
            ),            bottomNavigationBar: NavigationBar(
              selectedIndex: navigationModel.selectedIndex,
              onDestinationSelected: (index) => navigationModel.navigate(index),
              destinations: const [                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.interests_outlined),
                  selectedIcon: Icon(Icons.interests),
                  label: 'Interests',
                ),
                NavigationDestination(
                  icon: Icon(Icons.recommend_outlined),
                  selectedIcon: Icon(Icons.recommend),
                  label: 'Projects',
                ),
                NavigationDestination(
                  icon: Icon(Icons.assignment_outlined),
                  selectedIcon: Icon(Icons.assignment),
                  label: 'Topic',
                ),
                NavigationDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people),
                  label: 'Lecturers',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
