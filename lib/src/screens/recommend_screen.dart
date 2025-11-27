import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RecommendScreen extends StatefulWidget {
  const RecommendScreen({super.key});
  @override
  State<RecommendScreen> createState() => _RecommendScreenState();
}

class _RecommendScreenState extends State<RecommendScreen> {
  bool _loading = false;
  Map<String, dynamic>? _result;

  Future<void> _runRecommend() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.recommendLastUpload();
      setState(() => _result = res);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Recommend failed: \$e')));
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
      appBar: AppBar(title: const Text('Recommendations')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(onPressed: _loading ? null : _runRecommend, child: _loading ? const CircularProgressIndicator() : const Text('Get Recommendations')),
            const SizedBox(height: 12),
            Expanded(child: _prettyJson(_result)),
          ],
        ),
      ),
    );
  }
}
