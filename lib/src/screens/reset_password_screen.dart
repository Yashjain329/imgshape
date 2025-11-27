// lib/src/screens/reset_password_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordCtl = TextEditingController();
  final _confirmCtl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  @override
  void dispose() {
    _passwordCtl.dispose();
    _confirmCtl.dispose();
    super.dispose();
  }

  String? _passwordValidator(String? s) {
    if (s == null || s.isEmpty) return 'Password is required';
    if (s.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  Future<void> _submit(String? accessToken) async {
    if (!_formKey.currentState!.validate()) return;
    final newPass = _passwordCtl.text;
    setState(() => _loading = true);

    try {
      final client = Supabase.instance.client;

      // Two common approaches exist depending on the SDK and whether you
      // are handling the reset token in-app:
      //
      // 1) If the user arrived with a session (deep link automatically logged them in)
      //    then you can call updateUser to change the password:
      //
      //    await client.auth.updateUser(UserAttributes(password: newPass));
      //
      // 2) If you received an access token (from the link) you may need to
      //    call the recover/reset API on your backend or use:
      //
      //    await client.auth.api.updateUserById(userId, { password: newPass }, headers: {...})
      //
      // Because SDK names and flows change, try approach (1) first. If you get
      // a compile error or it doesn't work, paste the error and I will adapt.
      //
      // Implementation below uses updateUser from the common SDK:
      try {
        await client.auth.updateUser(UserAttributes(password: newPass));
      } catch (e) {
        // If updateUser isn't available or fails, rethrow and we'll show the error
        rethrow;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated. You can now sign in.')));
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reset failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Optionally accept an accessToken from arguments
    final args = ModalRoute.of(context)?.settings.arguments;
    String? accessToken;
    if (args is Map && args['accessToken'] is String) accessToken = args['accessToken'] as String;

    return Container(
      decoration: AppTheme.heroBackground(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Set new password')),
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Enter a new password (minimum 8 characters)'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordCtl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'New password', prefixIcon: Icon(Icons.lock)),
                    validator: _passwordValidator,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmCtl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Confirm password', prefixIcon: Icon(Icons.lock)),
                    validator: (s) {
                      final v = _passwordValidator(s);
                      if (v != null) return v;
                      if (s != _passwordCtl.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : () => _submit(accessToken),
                      child: _loading ? const CircularProgressIndicator() : const Text('Update password'),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}