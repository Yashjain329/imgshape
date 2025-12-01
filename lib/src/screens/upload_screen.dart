import 'dart:async';
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

  // --- LOGIC ---

  Future<void> _pickFromCamera() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048, // Optimized: Cap resolution to save bandwidth/memory
        maxHeight: 2048,
        imageQuality: 85, // Optimized: Slight compression
      );
      if (picked == null) return;

      final file = File(picked.path);
      await _handleFile(file);
    } catch (e) {
      _showError('Camera error: $e');
    }
  }

  Future<void> _pickFromFiles() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true, // Needed for web/memory access
      );
      if (res == null) return;

      final bytes = res.files.single.bytes;
      final name = res.files.single.name;

      if (bytes != null) {
        // Web or memory-based pick
        await _setPreview(bytes, name);
        await _handleBytes(bytes, name);
      } else if (res.files.single.path != null) {
        // Native file pick
        final file = File(res.files.single.path!);
        await _handleFile(file);
      }
    } catch (e) {
      _showError('File picker error: $e');
    }
  }

  Future<void> _onDrop(dynamic ev) async {
    if (_dropController == null) return;
    try {
      final bytes = await _dropController!.getFileData(ev);
      final name = await _dropController!.getFilename(ev);
      await _setPreview(bytes, name);
      await _handleBytes(bytes, name);
    } catch (e) {
      debugPrint('Drop error: $e');
    }
  }

  Future<void> _setPreview(Uint8List bytes, String name) async {
    setState(() {
      _preview = bytes;
      _filename = name;
    });
  }

  Future<void> _handleFile(File file) async {
    setState(() => _uploading = true);
    try {
      // Show preview immediately if possible (native only)
      if (!kIsWeb) {
        final bytes = await file.readAsBytes();
        final name = file.path.split('/').last;
        _setPreview(bytes, name);
      }

      final result = await UploadService.uploadFile(file);
      _onUploadSuccess(result);
    } catch (e) {
      _showError('Upload failed: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _handleBytes(Uint8List bytes, String name) async {
    setState(() => _uploading = true);
    try {
      // Validate image data integrity
      final completer = Completer<ui.Image>();
      ui.decodeImageFromList(bytes, (img) => completer.complete(img));
      await completer.future; // Waits for decode to ensure valid image

      final result = await UploadService.uploadBytes(bytes, name);
      _onUploadSuccess(result);
    } catch (e) {
      _showError('Invalid image data or upload failed: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _onUploadSuccess(dynamic result) {
    if (!mounted) return;
    debugPrint('Analysis Result: $result');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Uploaded successfully ✅ — Analysis complete!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.pop(context, true);
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  // --- UI ---

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
        body: Stack(
          children: [
            // Dropzone layer (Web only)
            if (kIsWeb)
              Positioned.fill(
                child: DropzoneView(
                  operation: DragOperation.copy,
                  cursor: CursorType.grab,
                  onCreated: (ctrl) => _dropController = ctrl,
                  onDrop: _onDrop,
                ),
              ),

            // Main Content
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const UploadHeader(),
                    const SizedBox(height: 24),

                    // Preview Area
                    UploadPreviewCard(
                      previewBytes: _preview,
                      filename: _filename,
                    ),

                    const SizedBox(height: 24),

                    // Action Buttons
                    ActionButtons(
                      loading: _uploading,
                      onCameraTap: _pickFromCamera,
                      onFileTap: _pickFromFiles,
                    ),

                    if (_uploading) ...[
                      const SizedBox(height: 16),
                      const UploadLoadingIndicator(),
                    ],

                    const SizedBox(height: 24),
                    const InfoSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- OPTIMIZED SUB-WIDGETS ---

class UploadHeader extends StatelessWidget {
  const UploadHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Share Your Image',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Upload an image to analyze and get insights',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class UploadPreviewCard extends StatelessWidget {
  final Uint8List? previewBytes;
  final String? filename;

  const UploadPreviewCard({
    super.key,
    required this.previewBytes,
    required this.filename,
  });

  @override
  Widget build(BuildContext context) {
    if (previewBytes != null) {
      return GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  previewBytes!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  // Optimization: Cache large previews
                  cacheWidth: 800,
                ),
              ),
              if (filename != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Column(
                    children: [
                      Text('Selected File', style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Text(
                        filename!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
      );
    }

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
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
              child: Icon(Icons.image_outlined, size: 40, color: AppTheme.accentCyan),
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
    );
  }
}

class ActionButtons extends StatelessWidget {
  final bool loading;
  final VoidCallback onCameraTap;
  final VoidCallback onFileTap;

  const ActionButtons({
    super.key,
    required this.loading,
    required this.onCameraTap,
    required this.onFileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: loading ? null : onCameraTap,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Capture Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: loading ? null : onFileTap,
              icon: const Icon(Icons.folder),
              label: const Text('Choose from Files'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentViolet,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UploadLoadingIndicator extends StatelessWidget {
  const UploadLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentCyan),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Uploading...',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ],
    );
  }
}

class InfoSection extends StatelessWidget {
  const InfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        // Using const allows Flutter to cache this entire subtree
        GlassCard(
          child: Padding(
            padding: EdgeInsets.all(12.0),
            child: FormatInfoContent(),
          ),
        ),
        SizedBox(height: 16),
        GlassCard(
          child: Padding(
            padding: EdgeInsets.all(12.0),
            child: ProTipsContent(),
          ),
        ),
      ],
    );
  }
}

class FormatInfoContent extends StatelessWidget {
  const FormatInfoContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.info_outline, size: 28, color: AppTheme.accentCyan),
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
    );
  }
}

class ProTipsContent extends StatelessWidget {
  const ProTipsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.lightbulb_outline, size: 28, color: Colors.amber),
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
    );
  }
}