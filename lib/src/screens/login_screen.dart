// lib/src/login_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _isSignUp = false;

  final _supabase = Supabase.instance.client;

  @override
  void dispose() {
    _emailCtl.dispose();
    _passwordCtl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? s) {
    if (s == null || s.trim().isEmpty) return 'Email is required';
    final email = s.trim();
    final emailRegex = RegExp(r"^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$");
    if (!emailRegex.hasMatch(email)) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? s) {
    if (s == null || s.isEmpty) return 'Password is required';
    if (s.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  Future<void> _handleEmailAction() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final email = _emailCtl.text.trim();
    final password = _passwordCtl.text;

    try {
      if (_isSignUp) {
        final user = await AuthService.signUpWithEmail(email: email, password: password);
        if (user != null) {
          if (mounted) context.go('/home');
        } else {
          if (mounted) context.go('/confirm', extra: email);
        }
      } else {
        final user = await AuthService.signInWithEmail(email: email, password: password);
        if (user != null) {
          if (mounted) context.go('/home');
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sign in succeeded but no user found')),
            );
          }
        }
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Auth error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      await AuthService.signInWithGoogle();
      final user = _supabase.auth.currentUser;
      if (user != null) {
        if (mounted) context.go('/home');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Browser opened for Google sign-in. Complete the flow and return to the app.'),
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign-in failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.heroBackground(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/logo.jpg', width: 120, height: 120),
                  const SizedBox(height: 18),
                  Text('imgshape', style: Theme.of(context).textTheme.displayLarge),
                  const SizedBox(height: 8),
                  const Text(
                    'Analyze images, get preprocessing recommendations, and generate compatibility reports.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF9AA3A9)),
                  ),
                  const SizedBox(height: 20),

                  // Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailCtl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordCtl,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)),
                          validator: _validatePassword,
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _handleEmailAction,
                            child: _loading
                                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                : Text(_isSignUp ? 'Create account' : 'Sign in'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_isSignUp ? 'Already have an account?' : "Don't have an account?"),
                            TextButton(
                              onPressed: _loading ? null : () => setState(() => _isSignUp = !_isSignUp),
                              child: Text(_isSignUp ? 'Sign in' : 'Sign up'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: _loading ? null : () => context.go('/forgot'),
                              child: const Text('Forgot password?'),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.login),
                              label: _loading
                                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Text('Sign in with Google'),
                              onPressed: _loading ? null : _signInWithGoogle,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}