// lib/src/services/api_service.dart

import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../config.dart';

class ApiService {
  static final Dio _dio = Dio();
  static final SupabaseClient _supabase = Supabase.instance.client;
  static Future<Map<String, dynamic>> _getLastUploadWithSignedUrl() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final res = await _supabase
        .from('user_images')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (res == null) throw Exception('No uploads found');

    final bucket = (res['bucket'] as String?) ?? 'user-uploads';
    final path = res['path'] as String?;
    if (path == null || path.isEmpty) throw Exception('Invalid file path');

    final signedUrl =
    await _supabase.storage.from(bucket).createSignedUrl(path, 60 * 60);

    return {'record': res, 'signedUrl': signedUrl, 'path': path};
  }

  static Future<Map<String, dynamic>?> _postToBackend(
      String endpoint, String signedUrl) async {
    final backendUrl =
        dotenv.env['BACKEND_URL'] ?? Config.backendUrl ?? ''; // fallback
    if (backendUrl.isEmpty) throw Exception('Backend URL not configured');

    try {
      final response = await _dio.post(
        '$backendUrl/$endpoint',
        data: {'image_url': signedUrl},
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: const Duration(seconds: 25),
          receiveTimeout: const Duration(seconds: 25),
        ),
      );
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>?;
      } else {
        throw Exception('API ${response.statusCode}: ${response.data}');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> _updateImageAnalysis(
      String path, Map<String, dynamic>? data, String field) async {
    if (data == null) return;
    await _supabase
        .from('user_images')
        .update({field: data}).eq('path', path);
  }

  static Future<Map<String, dynamic>?> analyzeLastUpload() async {
    final info = await _getLastUploadWithSignedUrl();
    final signedUrl = info['signedUrl'] as String;
    final path = info['path'] as String;

    final result = await _postToBackend('analyze', signedUrl);
    await _updateImageAnalysis(path, result, 'analysis');
    return result;
  }

  static Future<Map<String, dynamic>?> recommendLastUpload() async {
    final info = await _getLastUploadWithSignedUrl();
    final signedUrl = info['signedUrl'] as String;
    final path = info['path'] as String;

    final result = await _postToBackend('recommend', signedUrl);
    await _updateImageAnalysis(path, result, 'recommendation');
    return result;
  }

  static Future<Map<String, dynamic>?> compatibilityLastUpload() async {
    final info = await _getLastUploadWithSignedUrl();
    final signedUrl = info['signedUrl'] as String;
    final path = info['path'] as String;

    final result = await _postToBackend('compatibility', signedUrl);
    await _updateImageAnalysis(path, result, 'compatibility');
    return result;
  }
  static Future<Map<String, dynamic>?> downloadReportLastUpload() async {
    final info = await _getLastUploadWithSignedUrl();
    final signedUrl = info['signedUrl'] as String;
    final path = info['path'] as String;

    final result = await _postToBackend('download_report', signedUrl);
    await _updateImageAnalysis(path, result, 'report');
    return result;
  }
}