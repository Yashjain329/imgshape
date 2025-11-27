// lib/src/config.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  static String? supabaseUrl = 'https://your-project.supabase.co';
  static String? supabaseAnonKey = 'your-public-anon-key';
  static String? backendUrl =
      'https://imgshape-412998139400.asia-south1.run.app';
  static String? redirectUri = 'com.imgshape.app://login-callback/';
  static const int maxUploadBytes = 200 * 1024 * 1024; // 200 MB
  static Future<void> loadEnvSafely({String fileName = '.env'}) async {
    try {
      await dotenv.load(fileName: fileName);
      final envSupabaseUrl = dotenv.env['SUPABASE_URL'];
      final envSupabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
      final envBackendUrl = dotenv.env['BACKEND_URL'];
      final envRedirectUri = dotenv.env['REDIRECT_URI'];
      if (envSupabaseUrl != null && envSupabaseUrl.isNotEmpty) {
        supabaseUrl = envSupabaseUrl;
      }
      if (envSupabaseAnonKey != null && envSupabaseAnonKey.isNotEmpty) {
        supabaseAnonKey = envSupabaseAnonKey;
      }
      if (envBackendUrl != null && envBackendUrl.isNotEmpty) {
        backendUrl = envBackendUrl;
      }
      if (envRedirectUri != null && envRedirectUri.isNotEmpty) {
        redirectUri = envRedirectUri;
      }
    } catch (e) {
      rethrow;
    }
  }
}