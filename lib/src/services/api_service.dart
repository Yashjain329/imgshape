// lib/src/services/api_service.dart

import 'package:dio/dio.dart';
// ✅ FIX: Hide MultipartFile from Supabase to prevent conflict with Dio
import 'package:supabase_flutter/supabase_flutter.dart' hide MultipartFile;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:archive/archive.dart'; // ✅ Required for compatibility zipping
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

    // Create a temporary signed URL to download the file
    final signedUrl =
    await _supabase.storage.from(bucket).createSignedUrl(path, 60 * 60);

    return {'record': res, 'signedUrl': signedUrl, 'path': path};
  }

  static Future<Map<String, dynamic>?> _postToBackend(
      String endpoint, String signedUrl) async {
    final backendUrl =
        dotenv.env['BACKEND_URL'] ?? Config.backendUrl ?? '';
    if (backendUrl.isEmpty) throw Exception('Backend URL not configured');

    try {
      // 1. Download the file bytes from Supabase first
      // The backend cannot access the URL directly, so we must proxy the file.
      final fileResponse = await Dio().get<List<int>>(
        signedUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      if (fileResponse.data == null) throw Exception('Failed to download image data');

      List<int> fileBytes = fileResponse.data!;
      String fileName = 'image.jpg';
      String fieldName = 'file';

      // 2. Apply Specific Logic (Matches UploadService)
      if (endpoint.contains('compatibility')) {
        // Compatibility endpoint needs a ZIP file and 'dataset' field
        fieldName = 'dataset';
        final archive = Archive();
        archive.addFile(ArchiveFile('image.jpg', fileBytes.length, fileBytes));
        final encoder = ZipEncoder();
        fileBytes = encoder.encode(archive)!;
        fileName = 'dataset.zip';
      }

      // 3. Prepare FormData
      final formDataMap = <String, dynamic>{
        fieldName: MultipartFile.fromBytes(
          fileBytes,
          filename: fileName,
        ),
      };

      // Add 'model' only for compatibility
      if (endpoint.contains('compatibility')) {
        formDataMap['model'] = 'yolov8';
      }

      final formData = FormData.fromMap(formDataMap);

      // 4. Send to Backend
      final response = await _dio.post(
        '$backendUrl/$endpoint',
        data: formData,
        options: Options(
          // Don't set Content-Type manually; Dio sets it for Multipart
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
          validateStatus: (status) => status != null && status < 500,
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
    try {
      await _supabase
          .from('user_images')
          .update({field: data}).eq('path', path);
    } catch (e) {
      print('Failed to save analysis to history: $e');
      // Non-fatal error, don't crash UI
    }
  }

  static Future<Map<String, dynamic>?> analyzeLastUpload() async {
    try {
      final info = await _getLastUploadWithSignedUrl();
      final signedUrl = info['signedUrl'] as String;
      final path = info['path'] as String;

      final result = await _postToBackend('analyze', signedUrl);

      if (result != null) {
        await _updateImageAnalysis(path, result, 'analysis');
      }
      return result;
    } catch (e) {
      print('Analyze error: $e');
      rethrow;
    }
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