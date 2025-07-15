import 'package:flutter/material.dart';

class AuthScreen extends StatefulWidget {
  final Future<void> Function(String email, String password, String role)? onRegister;
  final Future<void> Function(String email, String password)? onLogin;
  const AuthScreen({super.key, this.onRegister, this.onLogin});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String _role = 'student';
  bool _isLogin = true;
  String? _error;
  bool _loading = false;
  bool _obscurePassword = true;

  void _resetForm() {
    setState(() {
      _email = '';
      _password = '';
      _role = 'student';
      _error = null;
      _formKey.currentState?.reset();
    });
  }

  String _friendlyError(dynamic e) {
    final msg = e.toString();
    if (msg.contains('user-not-found')) return 'No user found for that email.';
    if (msg.contains('wrong-password')) return 'Incorrect password.';
    if (msg.contains('email-already-in-use')) return 'Email already in use.';
    if (msg.contains('invalid-email')) return 'Invalid email address.';
    if (msg.contains('network-request-failed')) return 'Network error. Please try again.';
    if (msg.contains('too-many-requests')) return 'Too many attempts. Try again later.';
    return 'Authentication failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Login' : 'Register')),
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Branding/logo
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Icon(Icons.account_circle, size: 56, color: Theme.of(context).colorScheme.primary),
                    ),
                    TextFormField(
                      key: const ValueKey('email'),
                      decoration: const InputDecoration(labelText: 'Email'),
                      onChanged: (v) => _email = v,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Email is required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                      initialValue: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const ValueKey('password'),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      obscureText: _obscurePassword,
                      onChanged: (v) => _password = v,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required';
                        if (v.length < 6) return 'Min 6 characters';
                        return null;
                      },
                      initialValue: _password,
                      autofillHints: const [AutofillHints.password],
                    ),
                    if (!_isLogin) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _role,
                        items: const [
                          DropdownMenuItem(value: 'student', child: Text('Student')),
                          DropdownMenuItem(value: 'lecturer', child: Text('Lecturer')),
                          DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        ],
                        onChanged: (v) => setState(() => _role = v ?? 'student'),
                        decoration: const InputDecoration(labelText: 'Role'),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ],
                    if (_loading) ...[
                      const SizedBox(height: 24),
                      const CircularProgressIndicator(),
                    ] else ...[
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState?.validate() ?? false) {
                            setState(() {
                              _error = null;
                              _loading = true;
                            });
                            try {
                              if (_isLogin) {
                                await widget.onLogin?.call(_email, _password);
                              } else {
                                await widget.onRegister?.call(_email, _password, _role);
                                // Optionally, show a dialog to verify email
                                if (mounted) {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Registration Successful'),
                                      content: const Text('Please check your email to verify your account before logging in.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(ctx).pop(),
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              }
                              _resetForm();
                            } catch (e) {
                              setState(() => _error = _friendlyError(e));
                            } finally {
                              setState(() => _loading = false);
                            }
                          }
                        },
                        child: Text(_isLogin ? 'Login' : 'Register'),
                      ),
                    ],
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isLogin = !_isLogin;
                          _resetForm();
                        });
                      },
                      child: Text(_isLogin ? 'No account? Register' : 'Have an account? Login'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
