// lib/src/screens/analyze_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';
import '../theme/app_theme.dart';

class AnalyzeScreen extends StatefulWidget {
  const AnalyzeScreen({super.key});

  @override
  State<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends State<AnalyzeScreen> {
  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAnalysisOnInit();
  }

  Future<void> _loadAnalysisOnInit() async {
    await _runAnalyze();
  }

  Future<void> _runAnalyze() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiService.analyzeLastUpload();
      if (mounted) {
        setState(() {
          _result = res as Map<String, dynamic>?;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Analysis failed: ${e.toString()}';
          _result = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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

  Widget _analysisMetricTile(String label, String value, Color color) {
    return Center(
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(Icons.analytics, color: color, size: 24),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _prettyJson(Map<String, dynamic>? data) {
    if (data == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                size: 48,
                color: AppTheme.accentCyan.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No analysis data',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    const encoder = JsonEncoder.withIndent('  ');
    final jsonString = encoder.convert(data);

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.all(14.0),
      child: SingleChildScrollView(
        child: Text(
          jsonString,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontFamily: 'Courier',
            color: AppTheme.accentCyan,
          ),
        ),
      ),
    );
  }

  Widget _analysisInfoCard() {
    return Center(
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 32,
                color: Colors.amber,
              ),
              const SizedBox(height: 8),
              Text(
                'How Analysis Works',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Our AI analyzes your image for entropy, complexity, and compatibility. '
                    'Results include detailed metrics and recommendations for preprocessing.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tipCard() {
    return Center(
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.tips_and_updates_outlined,
                size: 32,
                color: AppTheme.accentCyan,
              ),
              const SizedBox(height: 8),
              Text(
                'Pro Tips',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '• Analyze multiple images to compare results\n'
                    '• Higher entropy = more complex image\n'
                    '• Follow recommendations for best results\n'
                    '• Check compatibility before processing',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
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
          title: const Text('Analysis Results'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _runAnalyze,
                      icon: _loading
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                          : const Icon(Icons.play_arrow),
                      label: Text(
                        _loading
                            ? 'Analyzing...'
                            : 'Analyze Last Upload',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentCyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null)
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage ?? 'Unknown error',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_loading)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.accentCyan),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Processing your image...',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This may take a few moments',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                )
              else if (_result != null)
                  Column(
                    children: [
                      Text(
                        'Analysis Complete',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _analysisMetricTile(
                              'Entropy',
                              (_result?['entropy'] as dynamic)?.toString() ?? 'N/A',
                              AppTheme.accentCyan,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _analysisMetricTile(
                              'Complexity',
                              (_result?['complexity'] as dynamic)?.toString() ??
                                  'N/A',
                              AppTheme.accentViolet,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _analysisInfoCard(),
                      const SizedBox(height: 12),
                      GlassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Detailed Results',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 12),
                              _prettyJson(_result),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _tipCard(),
                    ],
                  )
                else
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.analytics_outlined,
                            size: 48,
                            color: AppTheme.accentCyan.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Click "Analyze Last Upload" to start',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Make sure you have uploaded an image first',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 24),
                          _tipCard(),
                        ],
                      ),
                    ),
                  ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}