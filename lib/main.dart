import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'auth/app_state.dart';
import 'theme/custom_theme.dart';
import 'views/auth/auth_screen.dart';
import 'views/student/student_home_screen.dart';
import 'views/lecturer/lecturer_home_screen.dart';
import 'views/admin/admin_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return MaterialApp(
      title: 'Project Topic Allocator',
      theme: customTheme,
      debugShowCheckedModeBanner: false,
      home: AnimatedBuilder(
        animation: appState,
        builder: (context, _) {
          if (!appState.isAuthenticated) {
            return AuthScreen(
              onLogin: appState.loginWithEmail,
              onRegister: appState.registerWithEmail,
            );
          }
          switch (appState.role) {
            case 'student':
              return StudentHomeScreen(onLogout: appState.logout);
            case 'lecturer':
              return LecturerHomeScreen(onLogout: appState.logout);
            case 'admin':
              return AdminHomeScreen(onLogout: appState.logout);
            default:
              return AuthScreen(
                onLogin: appState.loginWithEmail,
                onRegister: appState.registerWithEmail,
              );
          }
        },
      ),
    );
  }
}
