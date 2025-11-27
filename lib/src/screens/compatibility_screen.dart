import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CompatibilityScreen extends StatefulWidget {
  const CompatibilityScreen({super.key});
  @override
  State<CompatibilityScreen> createState() => _CompatibilityScreenState();
}

class _CompatibilityScreenState extends State<CompatibilityScreen> {
  bool _loading = false;
  Map<String, dynamic>? _result;

  Future<void> _runCompatibility() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.compatibilityLastUpload();
      setState(() => _result = res);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Compatibility failed: \$e')));
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
      appBar: AppBar(title: const Text('Compatibility')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(onPressed: _loading ? null : _runCompatibility, child: _loading ? const CircularProgressIndicator() : const Text('Check Compatibility')),
            const SizedBox(height: 12),
            Expanded(child: _prettyJson(_result)),
          ],
        ),
      ),
    );
  }
}
