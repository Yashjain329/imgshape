// lib/src/services/upload_service.dart
// -----------------------------------------------------------------------------
// ✅ FINAL STABLE VERSION (by ChatGPT - GPT-5)
// - Uses getPublicUrl() for public bucket
// - Retries backend calls if file not yet visible on CDN
// - Parallel backend calls maintained for speed
// -----------------------------------------------------------------------------

import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UploadService {
  static final SupabaseClient _client = Supabase.instance.client;
  static const String bucket = 'user-uploads';
  static Future<Map<String, dynamic>?> _callBackendWithRetry(
      String endpoint, String datasetPath,
      {int maxRetries = 5}) async {
    final backendUrl = dotenv.env['BACKEND_URL'];
    if (backendUrl == null || backendUrl.isEmpty) {
      throw Exception('Missing BACKEND_URL in .env');
    }

    final uri = Uri.parse('$backendUrl/$endpoint');
    int attempt = 0;
    late http.Response response;

    while (attempt < maxRetries) {
      attempt++;
      final request = http.MultipartRequest('POST', uri);
      request.fields['dataset_path'] = datasetPath;

      final streamedResponse = await request.send();
      response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        try {
          return jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {
          return {'raw': response.body};
        }
      }
      if (response.body.contains('File not found')) {
        final delay = Duration(seconds: attempt * 2);
        print(
            '[Retry] File not found for $endpoint. Waiting ${delay.inSeconds}s before retry $attempt/$maxRetries...');
        await Future.delayed(delay);
        continue;
      }
      throw Exception('Backend error ($endpoint): ${response.body}');
    }
    throw Exception(
        'File not found on Supabase CDN after $maxRetries retries (${endpoint}).');
  }

  static Future<Map<String, dynamic>> _uploadAndProcess({
    required Uint8List bytes,
    required String filename,
    required int fileSize,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    if (fileSize > Config.maxUploadBytes) {
      throw Exception(
          'File exceeds max allowed size of ${Config.maxUploadBytes} bytes');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = p.join(user.id, '${timestamp}_$filename');
    final contentType =
        lookupMimeType(filename, headerBytes: bytes) ?? 'application/octet-stream';

    await _client.storage.from(bucket).uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: contentType),
    );

    await _client.from('user_images').insert({
      'user_id': user.id,
      'bucket': bucket,
      'path': path,
      'filename': filename,
      'content_type': contentType,
      'size_bytes': fileSize,
      'metadata': {'source': 'upload_service_parallel'},
    });

    final publicUrl = _client.storage.from(bucket).getPublicUrl(path);
    await Future.delayed(const Duration(seconds: 2));

    final results = await Future.wait<Map<String, dynamic>?>([
      _callBackendWithRetry('analyze', publicUrl),
      _callBackendWithRetry('recommend', publicUrl),
      _callBackendWithRetry('compatibility', publicUrl),
      _callBackendWithRetry('download_report', publicUrl),
    ]);

    final analysis = results[0];
    final recommendation = results[1];
    final compatibility = results[2];
    final report = results[3];

    await _client.from('user_images').update({
      'analysis': analysis,
      'recommendation': recommendation,
      'compatibility': compatibility,
      'report': report,
    }).eq('path', path);

    return {
      'analysis': analysis,
      'recommendation': recommendation,
      'compatibility': compatibility,
      'report': report,
    };
  }

  static Future<Map<String, dynamic>> uploadFile(File file) async {
    final bytes = await file.readAsBytes();
    return _uploadAndProcess(
      bytes: bytes,
      filename: p.basename(file.path),
      fileSize: bytes.length,
    );
  }

  static Future<Map<String, dynamic>> uploadBytes(
      Uint8List bytes, String filename) async {
    return _uploadAndProcess(
      bytes: bytes,
      filename: filename,
      fileSize: bytes.length,
    );
  }
}
