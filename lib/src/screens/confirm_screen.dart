// lib/src/screens/confirm_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class ConfirmScreen extends StatefulWidget {
  const ConfirmScreen({super.key});

  @override
  State<ConfirmScreen> createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends State<ConfirmScreen> {
  bool _loading = false;

  String? _emailFromArgs(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.isNotEmpty) return args;
    return null;
  }

  Future<void> _resendConfirmation(String email) async {
    setState(() => _loading = true);
    try {
      await AuthService.resendSignupEmail(email: email);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Confirmation email resent')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Resend failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openMailApp() async {
    final uri = Uri.parse('mailto:');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot open mail app')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = _emailFromArgs(context);

    return Container(
      decoration: AppTheme.heroBackground(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mark_email_read_outlined, size: 72),
                  const SizedBox(height: 18),
                  Text('Confirm your email', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  Text(
                    email != null ? 'A confirmation email has been sent to $email.' : 'A confirmation email has been sent to your address.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loading || email == null ? null : () => _resendConfirmation(email),
                    child: _loading ? const CircularProgressIndicator() : const Text('Resend confirmation'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _openMailApp,
                    child: const Text('Open Mail App'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      // go back to login for manual sign-in attempt
                      Navigator.pushReplacementNamed(context, '/');
                    },
                    child: const Text('Back to Login'),
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