import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:file_saver/file_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:media_scanner/media_scanner.dart'; // Import MediaScanner
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class DownloadReportScreen extends StatefulWidget {
  // Allow passing data directly to avoid refetching
  final Map<String, dynamic>? initialData;

  const DownloadReportScreen({super.key, this.initialData});

  @override
  State<DownloadReportScreen> createState() => _DownloadReportScreenState();
}

class _DownloadReportScreenState extends State<DownloadReportScreen> {
  bool _loading = false;
  bool _generatingReport = false;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    // Use passed data if available, otherwise fetch
    if (widget.initialData != null) {
      _result = widget.initialData;
    } else {
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.downloadReportLastUpload();
      if (mounted) {
        setState(() => _result = res);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // --- PDF GENERATION LOGIC ---
  Future<Uint8List?> _generatePdfBytes() async {
    if (_result == null) return null;

    final pdf = pw.Document();
    final analysis = _result?['analysis'] ?? {};
    final meta = analysis['meta'] ?? {};

    final entropy = analysis['entropy'];
    double? complexity;
    if (analysis['complexity'] != null) {
      complexity = (analysis['complexity'] as num).toDouble();
    } else if (entropy != null && entropy is num) {
      complexity = (entropy / 8.0) * 100;
      if (complexity > 100) complexity = 100;
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Image Analysis Report',
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                  'Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}'),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text('Core Metrics',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              _buildPdfMetricRow('Entropy', entropy?.toString() ?? 'N/A'),
              _buildPdfMetricRow('Complexity',
                  complexity != null ? '${complexity.toStringAsFixed(1)}%' : 'N/A'),
              pw.SizedBox(height: 20),
              pw.Text('Metadata',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              _buildPdfMetricRow('Resolution',
                  '${meta['width'] ?? '?'} x ${meta['height'] ?? '?'}'),
              _buildPdfMetricRow('Channels', '${meta['channels'] ?? '?'}'),
              _buildPdfMetricRow('Mode', '${meta['mode'] ?? 'RGB'}'),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text('Raw Data Dump',
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
              pw.SizedBox(height: 5),
              pw.Paragraph(
                text: const JsonEncoder.withIndent('  ').convert(_result),
                style: pw.TextStyle(fontSize: 8, font: pw.Font.courier()),
              ),
            ],
          );
        },
      ),
    );
    return await pdf.save();
  }

  pw.Widget _buildPdfMetricRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  // --- CSV GENERATION LOGIC ---
  String? _generateCsvString() {
    if (_result == null) return null;
    List<List<dynamic>> rows = [];
    rows.add(['Key', 'Value']); // Header
    _flattenMap(_result!, rows);
    return const ListToCsvConverter().convert(rows);
  }

  void _flattenMap(Map<String, dynamic> map, List<List<dynamic>> rows,
      [String prefix = '']) {
    map.forEach((key, value) {
      String newKey = prefix.isEmpty ? key : '$prefix.$key';
      if (value is Map<String, dynamic>) {
        _flattenMap(value, rows, newKey);
      } else if (value is List) {
        rows.add([newKey, value.toString()]);
      } else {
        rows.add([newKey, value.toString()]);
      }
    });
  }

  // --- PERMISSION & SAVING HELPER ---
  Future<bool> _checkPermission() async {
    // For Android 11+ (API 30+), storage permission is handled differently.
    // FileSaver often handles this natively, but good to check storage for older OS.
    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
      return status.isGranted || await Permission.manageExternalStorage.isGranted;
    }
    return true; // iOS/Desktop usually handled by UI picker
  }

  // --- ACTIONS ---

  Future<void> _shareFile(String type) async {
    if (_result == null) return;
    setState(() => _generatingReport = true);
    try {
      final output = await getTemporaryDirectory();

      if (type == 'pdf') {
        final bytes = await _generatePdfBytes();
        if (bytes == null) return;
        final file = File('${output.path}/analysis_report.pdf');
        await file.writeAsBytes(bytes);
        await Share.shareXFiles([XFile(file.path)], text: 'Image Analysis Report (PDF)');
      } else {
        final csv = _generateCsvString();
        if (csv == null) return;
        final file = File('${output.path}/analysis_data.csv');
        await file.writeAsString(csv);
        await Share.shareXFiles([XFile(file.path)], text: 'Image Analysis Data (CSV)');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Share failed: $e')));
    } finally {
      if (mounted) setState(() => _generatingReport = false);
    }
  }

  Future<void> _saveToDevice(String type) async {
    if (_result == null) return;
    setState(() => _generatingReport = true);

    try {
      // 1. Generate Data
      Uint8List bytes;
      String name;
      String ext;
      MimeType mime;
      String? csvContent;

      if (type == 'pdf') {
        final pdfBytes = await _generatePdfBytes();
        if (pdfBytes == null) throw Exception("PDF Generation failed");
        bytes = pdfBytes;
        name = 'analysis_report';
        ext = 'pdf';
        mime = MimeType.pdf;
      } else {
        csvContent = _generateCsvString();
        if (csvContent == null) throw Exception("CSV Generation failed");
        bytes = Uint8List.fromList(utf8.encode(csvContent));
        name = 'analysis_data';
        ext = 'csv';
        mime = MimeType.text; // Using text for CSV is safer
      }

      await _checkPermission();

      String savedPath = '';

      // 2. Try saving to PUBLIC Downloads folder directly on Android
      if (Platform.isAndroid) {
        try {
          // Attempt to write directly to /storage/emulated/0/Download
          final downloadDir = Directory('/storage/emulated/0/Download');
          if (await downloadDir.exists()) {
            final path = '${downloadDir.path}/$name.$ext';
            final file = File(path);

            // Ensure unique name if exists
            File targetFile = file;
            if (await file.exists()) {
              final timestamp = DateTime.now().millisecondsSinceEpoch;
              targetFile = File('${downloadDir.path}/${name}_$timestamp.$ext');
            }

            // Write content
            if (type == 'pdf') {
              await targetFile.writeAsBytes(bytes);
            } else {
              // For CSV, write as string explicitly
              await targetFile.writeAsString(csvContent!);
            }

            savedPath = targetFile.path;

            // FORCE SCAN: Tell Android to index this new file immediately
            try {
              await MediaScanner.loadMedia(path: savedPath);
            } catch (e) {
              debugPrint('Media scan failed: $e');
            }
          }
        } catch (e) {
          debugPrint('Direct save failed: $e');
        }
      }

      // 3. Fallback to FileSaver if manual save didn't happen
      if (savedPath.isEmpty) {
        // Appending extension to name manually to ensure it appears
        savedPath = await FileSaver.instance.saveFile(
          name: '$name.$ext',
          bytes: bytes,
          mimeType: mime,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to: $savedPath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _generatingReport = false);
    }
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: _generatingReport ? null : onTap,
      icon: Icon(icon, color: Colors.white, size: 20),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
          title: const Text('Export Report'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.accentCyan))
              : _result == null
              ? Center(
              child: Text('No data available.',
                  style: Theme.of(context).textTheme.bodyLarge))
              : Column(
            children: [
              // Control Panel
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('PDF Report', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _actionButton(
                              label: 'Share',
                              icon: Icons.share,
                              onTap: () => _shareFile('pdf'),
                              color: Colors.blue.shade600,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _actionButton(
                              label: 'Save',
                              icon: Icons.download,
                              onTap: () => _saveToDevice('pdf'),
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text('CSV Data', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _actionButton(
                              label: 'Share',
                              icon: Icons.share,
                              onTap: () => _shareFile('csv'),
                              color: Colors.green.shade600,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _actionButton(
                              label: 'Save',
                              icon: Icons.download,
                              onTap: () => _saveToDevice('csv'),
                              color: Colors.green.shade800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Loading Indicator
              if (_generatingReport)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: 12),
                      Text('Generating...', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),

              const SizedBox(height: 10),

              // Preview Area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text('Data Preview',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall),
                        ),
                        Divider(color: Colors.white.withOpacity(0.1), height: 1),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              const JsonEncoder.withIndent('  ')
                                  .convert(_result),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                  fontFamily: 'Courier',
                                  fontSize: 12,
                                  color: AppTheme.accentCyan),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}