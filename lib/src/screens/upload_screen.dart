// lib/src/screens/upload_screen.dart

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import '../services/upload_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import 'dart:async';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  Uint8List? _preview;
  String? _filename;
  bool _uploading = false;
  DropzoneViewController? _dropController;
  Future<void> _pickFromCamera() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 4096,
      maxHeight: 4096,
    );
    if (picked == null) return;

    final file = File(picked.path);
    await _handleFile(file);
  }

  Future<void> _pickFromFiles() async {
    final res = await FilePicker.platform.pickFiles(withData: true);
    if (res == null) return;

    final bytes = res.files.single.bytes;
    final name = res.files.single.name;
    if (bytes == null || name.isEmpty) return;

    setState(() {
      _preview = bytes;
      _filename = name;
    });

    await _handleBytes(bytes, name);
  }

  Future<void> _onDrop(dynamic ev) async {
    if (!kIsWeb) return;
    final bytes = await _dropController!.getFileData(ev);
    final name = await _dropController!.getFilename(ev);

    setState(() {
      _preview = bytes;
      _filename = name;
    });

    await _handleBytes(bytes, name);
  }

  Future<void> _handleFile(File file) async {
    setState(() => _uploading = true);

    try {
      final analysisResult = await UploadService.uploadFile(file);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Uploaded successfully ✅ — Analysis complete!'),
          duration: const Duration(seconds: 3),
        ),
      );

      debugPrint('Analysis Result: $analysisResult');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _handleBytes(Uint8List bytes, String name) async {
    setState(() => _uploading = true);

    try {
      final completer = Completer<ui.Image>();
      ui.decodeImageFromList(bytes, (img) => completer.complete(img));
      final img = await completer.future;
      debugPrint('Selected image dimensions: ${img.width}x${img.height}');
      final analysisResult = await UploadService.uploadBytes(bytes, name);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Uploaded successfully ✅ — Analysis complete!'),
          duration: const Duration(seconds: 3),
        ),
      );

      debugPrint('Analysis Result: $analysisResult');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.heroBackground(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Upload Image'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, false),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Share Your Image',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Upload an image to analyze and get insights',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                if (_preview != null)
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(
                              _preview!,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          if (_filename != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text('Selected File',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                                  const SizedBox(height: 4),
                                  Text(
                                    _filename!,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                      color: AppTheme.accentCyan,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  )
                else
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppTheme.accentCyan.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              Icons.image_outlined,
                              size: 40,
                              color: AppTheme.accentCyan,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No Image Selected',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Choose an image to get started',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 24),
                Center(
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _uploading ? null : _pickFromCamera,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Capture Photo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentCyan,
                            foregroundColor: Colors.black,
                            padding:
                            const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _uploading ? null : _pickFromFiles,
                          icon: const Icon(Icons.folder),
                          label: const Text('Choose from Files'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentViolet,
                            foregroundColor: Colors.white,
                            padding:
                            const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_uploading) ...[
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.accentCyan,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Uploading...',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 24),
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline,
                            size: 28, color: AppTheme.accentCyan),
                        const SizedBox(height: 8),
                        Text('Supported Formats',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Text(
                          'JPG, PNG, WebP\nMax size: 50 MB\nMin 100x100px',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.lightbulb_outline,
                            size: 28, color: Colors.amber),
                        const SizedBox(height: 8),
                        Text('Pro Tips',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Text(
                          '• Use clear, well-lit images\n'
                              '• Square images work best\n'
                              '• Remove watermarks if possible',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}