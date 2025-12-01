// lib/src/services/upload_service.dart
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
import 'package:archive/archive.dart'; // ✅ REQUIRED: Add this for zipping

class UploadService {
  static final SupabaseClient _client = Supabase.instance.client;
  static const String bucket = 'user-uploads';

  static Future<Map<String, dynamic>?> _callBackendWithRetry(
      String endpoint,
      Uint8List fileBytes,
      String filename,
      {int maxRetries = 3}) async {

    final backendUrl = dotenv.env['BACKEND_URL'];
    if (backendUrl == null || backendUrl.isEmpty) {
      throw Exception('Missing BACKEND_URL in .env');
    }

    final uri = Uri.parse('$backendUrl/$endpoint');
    int attempt = 0;

    while (attempt < maxRetries) {
      attempt++;

      try {
        final request = http.MultipartRequest('POST', uri);

        String fieldName = 'file';
        List<int> bytesToSend = fileBytes;
        String filenameToSend = filename;

        // ✅ KEY FIX: Compatibility Endpoint Logic
        if (endpoint.contains('compatibility')) {
          // 1. Change field name to 'dataset'
          fieldName = 'dataset';

          // 2. Wrap the image in a ZIP file
          // The backend crashes if it gets a raw JPG, so we give it a ZIP.
          final archive = Archive();
          archive.addFile(ArchiveFile(filename, fileBytes.lengthInBytes, fileBytes));
          final encoder = ZipEncoder();
          bytesToSend = encoder.encode(archive)!;
          filenameToSend = 'dataset.zip';
        }

        request.files.add(http.MultipartFile.fromBytes(
          fieldName,
          bytesToSend,
          filename: filenameToSend,
        ));

        // Add 'model' field for compatibility endpoint
        if (endpoint.contains('compatibility')) {
          request.fields['model'] = 'yolov8';
        }

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          try {
            return jsonDecode(response.body) as Map<String, dynamic>;
          } catch (_) {
            return {'raw': response.body};
          }
        }

        print('Backend Error ($endpoint) [${response.statusCode}]: ${response.body}');

        // Retry only on server errors (500), not client errors (400)
        if (response.statusCode >= 500) {
          await Future.delayed(const Duration(seconds: 2));
          continue;
        }

        throw Exception('Backend error ($endpoint): ${response.body}');

      } catch (e) {
        print('Network error on attempt $attempt: $e');
        if (attempt >= maxRetries) rethrow;
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    throw Exception('Failed to process $endpoint after $maxRetries retries.');
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

    // 1. Upload to Supabase
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
      'metadata': {'source': 'upload_service_direct'},
    });

    // 2. Call Backend with ACTUAL FILES
    final results = await Future.wait<Map<String, dynamic>?>([
      _callBackendWithRetry('analyze', bytes, filename),
      _callBackendWithRetry('recommend', bytes, filename),
      _callBackendWithRetry('compatibility', bytes, filename),
      _callBackendWithRetry('download_report', bytes, filename),
    ]);

    final analysis = results[0];
    final recommendation = results[1];
    final compatibility = results[2];
    final report = results[3];

    // 3. Update Supabase (Safely)
    try {
      await _client.from('user_images').update({
        'analysis': analysis,
        'recommendation': recommendation,
        'compatibility': compatibility, // Ensure this column exists in DB!
        'report': report,
      }).eq('path', path);
    } catch (e) {
      print('Database Update Failed: $e');
      // We do NOT rethrow here. The user should still see the results
      // even if saving them to history failed.
    }

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