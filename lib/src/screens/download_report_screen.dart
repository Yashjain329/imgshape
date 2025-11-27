import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DownloadReportScreen extends StatefulWidget {
  const DownloadReportScreen({super.key});
  @override
  State<DownloadReportScreen> createState() => _DownloadReportScreenState();
}

class _DownloadReportScreenState extends State<DownloadReportScreen> {
  bool _loading = false;
  Map<String, dynamic>? _result;

  Future<void> _runDownload() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.downloadReportLastUpload();
      setState(() => _result = res);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download report failed: \$e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _prettyJson(Map<String, dynamic>? data) {
    if (data == null) return const Text('No result');
    const encoder = JsonEncoder.withIndent('  ');
    return SingleChildScrollView(child: Text(encoder.convert(data)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Download Report')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(onPressed: _loading ? null : _runDownload, child: _loading ? const CircularProgressIndicator() : const Text('Download Report')),
            const SizedBox(height: 12),
            Expanded(child: _prettyJson(_result)),
          ],
        ),
      ),
    );
  }
}
