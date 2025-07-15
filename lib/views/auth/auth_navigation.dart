import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class AuthNavigation extends StatefulWidget {
  final Future<void> Function(String email, String password)? onLogin;
  final Future<void> Function(String email, String password, String role)? onRegister;

  const AuthNavigation({
    Key? key,
    required this.onLogin,
    required this.onRegister,
  }) : super(key: key);

  @override
  State<AuthNavigation> createState() => _AuthNavigationState();
}

class _AuthNavigationState extends State<AuthNavigation> {
  bool _showLogin = true;

  void _toggleView() {
    setState(() {
      _showLogin = !_showLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showLogin) {
      return LoginScreen(
        onLogin: widget.onLogin,
        onNavigateToRegister: _toggleView,
      );
    }
    
    return RegisterScreen(
      onRegister: widget.onRegister,
      onNavigateToLogin: _toggleView,
    );
  }
}
