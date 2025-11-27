// lib/src/services/auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';

class AuthService {
  static SupabaseClient get _client => Supabase.instance.client;

  /// Sign up using email & password.
  static Future<User?> signUpWithEmail({
    required String email,
    required String password,
    String? emailRedirectTo,
  }) async {
    try {
      final res = await _client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: emailRedirectTo ?? Config.redirectUri,
      );
      return res.user;
    } on AuthException catch (e) {
      throw Exception('Sign up failed: ${e.message}');
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  /// Sign in with email & password.
  static Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return res.user;
    } on AuthException catch (e) {
      throw Exception('Sign in failed: ${e.message}');
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  /// Reset password: send reset email.
  /// Depending on your Supabase settings this will send an email with a link.
  static Future<void> resetPassword({required String email, String? redirectTo}) async {
    try {
      // Newer SDK method:
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: redirectTo ?? Config.redirectUri,
      );
    } on AuthException catch (e) {
      throw Exception('Reset password failed: ${e.message}');
    } catch (e) {
      throw Exception('Reset password failed: $e');
    }
  }

  /// Re-send signup confirmation email (by re-calling signUp with same email,
  /// or call a server endpoint if you implemented one). Some Supabase setups
  /// don't offer a direct "resend confirmation" endpoint — re-signup with the
  /// same email will trigger it in many setups.
  static Future<void> resendSignupEmail({required String email, String? redirectTo}) async {
    try {
      // Using signUp again to trigger email (safe because supabase handles duplicates)
      await _client.auth.signUp(
        email: email,
        password: '${DateTime.now().millisecondsSinceEpoch}@tmp', // throwaway password
        emailRedirectTo: redirectTo ?? Config.redirectUri,
      );
    } on AuthException catch (e) {
      throw Exception('Resend confirmation failed: ${e.message}');
    } catch (e) {
      throw Exception('Resend confirmation failed: $e');
    }
  }

  /// Sign in with Google (OAuth redirect).
  static Future<void> signInWithGoogle() async {
    return signInWithProvider(
      OAuthProvider.google,
      redirectTo: (Config.redirectUri != null && Config.redirectUri!.isNotEmpty)
          ? Config.redirectUri
          : null,
    );
  }

  static Future<void> signInWithProvider(
      OAuthProvider provider, {
        String? redirectTo,
      }) async {
    try {
      await _client.auth.signInWithOAuth(provider, redirectTo: redirectTo);
    } on AuthException catch (e) {
      throw Exception('Auth failed: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  static User? get currentUser => _client.auth.currentUser;
  static Session? get currentSession => _client.auth.currentSession;
}