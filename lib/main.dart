import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'auth/app_state.dart';
import 'theme/custom_theme.dart';
import 'views/auth/auth_navigation.dart';
import 'views/splash_screen.dart';
import 'views/student/student_home_screen.dart';
import 'views/student/student_dashboard_screen.dart';
import 'views/student/student_interests_screen.dart';
import 'views/student/student_topic_screen.dart';
import 'views/student/student_profile_screen.dart';
import 'views/student/project_recommendations_screen.dart';
import 'views/lecturer/lecturer_home_screen.dart';
import 'views/lecturer/lecturer_specializations_screen.dart';
import 'firebase_options.dart';
import 'views/student/student_messages_screen.dart';
import 'views/student/student_support_screen.dart';
import 'views/student/student_guidelines_screen.dart';
import 'views/student/student_dates_screen.dart';
import 'views/lecturer/lecturer_progress_screen.dart';
import 'views/lecturer/lecturer_messaging_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Failed to initialize Firebase: $e');
    // Continue anyway for development purposes
  }
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});  @override  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return MaterialApp(
      title: 'Project Topic Allocator',
      theme: customTheme,
      debugShowCheckedModeBanner: false,
      home: appState.isInitializing 
          ? const SplashScreen() 
          : _buildHomeScreen(appState),
      // Using onGenerateRoute for safer navigation
      onGenerateRoute: (RouteSettings settings) {
        switch (settings.name) {          case '/student/dashboard':
            return MaterialPageRoute(builder: (_) => const StudentDashboardScreen());
          case '/student/interests':
            return MaterialPageRoute(builder: (_) => const StudentInterestsScreen());
          case '/student/recommendations':
            return MaterialPageRoute(builder: (_) => const ProjectRecommendationsScreen());
          case '/student/topic':
            return MaterialPageRoute(builder: (_) => const StudentTopicScreen());
          case '/student/profile':
            return MaterialPageRoute(builder: (_) => StudentProfileScreen(onLogout: appState.logout));
          case '/student/messages':
            return MaterialPageRoute(builder: (_) => const StudentMessagesScreen());
          case '/student/support':
            return MaterialPageRoute(builder: (_) => const StudentSupportScreen());
          case '/student/guidelines':
            return MaterialPageRoute(builder: (_) => const StudentGuidelinesScreen());
          case '/student/dates':
            return MaterialPageRoute(builder: (_) => const StudentDatesScreen());
          case '/lecturer/specializations':
            return MaterialPageRoute(builder: (_) => const LecturerSpecializationsScreen());
          case '/lecturer/progress':
            return MaterialPageRoute(builder: (_) => const LecturerProgressScreen());
          case '/lecturer/messages':
            return MaterialPageRoute(builder: (_) => const LecturerMessagingScreen());
          default:
            // Return a 404 error page for unknown routes
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Page Not Found')),
                body: Center(child: Text('No route defined for ${settings.name}')),
              ),
            );
        }
      },
    );
  }
    Widget _buildHomeScreen(AppState appState) {
    // Safety check for authentication
    if (appState.firebaseUser == null || !appState.isAuthenticated) {
      return AuthNavigation(
        onLogin: appState.loginWithEmail,
        onRegister: appState.registerWithEmail,
      );
    }
    
    // Default to student role if role is null to avoid crashes
    final role = appState.role ?? 'student';
      switch (role) {
      case 'student':
        return StudentHomeScreen(onLogout: appState.logout);
      case 'lecturer':
        return LecturerHomeScreen(onLogout: appState.logout);
      default:
        return AuthNavigation(
          onLogin: appState.loginWithEmail,
          onRegister: appState.registerWithEmail,
        );
    }
  }
}
