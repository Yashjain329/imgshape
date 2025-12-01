import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';
import '../theme/app_theme.dart';
import 'download_report_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    // 1. Pre-calculate values so the UI doesn't have to do logic
    final analysisData = _result?['analysis'] as Map<String, dynamic>?;

    // Parse Entropy
    dynamic entropyRaw = analysisData?['entropy'] ?? _result?['entropy'];
    double? entropyVal = (entropyRaw is num) ? entropyRaw.toDouble() : null;

    // Calculate Complexity
    dynamic complexityRaw = analysisData?['complexity'] ?? _result?['complexity'];
    double? complexityVal;

    if (complexityRaw is num) {
      complexityVal = complexityRaw.toDouble();
    } else if (entropyVal != null) {
      complexityVal = (entropyVal / 8.0) * 100;
      if (complexityVal > 100) complexityVal = 100;
    }

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
              // Action Button
              AnalyzeActionButton(
                loading: _loading,
                onTap: _runAnalyze,
              ),
              const SizedBox(height: 16),

              // State Handling Logic
              if (_errorMessage != null)
                ErrorDisplayCard(message: _errorMessage!)
              else if (_loading)
                const LoadingIndicator()
              else if (_result != null)
                  Column(
                    children: [
                      Text(
                        'Analysis Complete',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      // Metrics Row
                      Row(
                        children: [
                          Expanded(
                            child: AnalysisMetricTile(
                              label: 'Entropy',
                              value: entropyVal,
                              color: AppTheme.accentCyan,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AnalysisMetricTile(
                              label: 'Complexity',
                              value: complexityVal,
                              color: AppTheme.accentViolet,
                              isPercentage: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Export Button
                      ExportReportButton(data: _result),
                      const SizedBox(height: 16),

                      // Static Info Cards (Now CONST so they never rebuild!)
                      const AnalysisInfoCard(),
                      const SizedBox(height: 12),

                      // JSON Viewer
                      JsonResultViewer(data: _result),
                      const SizedBox(height: 12),

                      const TipCard(),
                    ],
                  )
                else
                  const EmptyStateView(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// --- OPTIMIZED SUB-WIDGETS ---

class AnalyzeActionButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const AnalyzeActionButton({
    super.key,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: loading ? null : onTap,
            icon: loading
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.play_arrow),
            label: Text(loading ? 'Analyzing...' : 'Analyze Last Upload'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentCyan,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ),
    );
  }
}

class ExportReportButton extends StatelessWidget {
  final Map<String, dynamic>? data;

  const ExportReportButton({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DownloadReportScreen(initialData: data),
                ),
              );
            },
            icon: const Icon(Icons.download_rounded),
            label: const Text('Export Report (PDF/CSV)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentViolet,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ),
    );
  }
}

class AnalysisMetricTile extends StatelessWidget {
  final String label;
  final dynamic value;
  final Color color;
  final bool isPercentage;

  const AnalysisMetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.isPercentage = false,
  });

  String get _formattedValue {
    if (value == null) return 'N/A';
    if (value is num) {
      return isPercentage
          ? '${value.toStringAsFixed(1)}%'
          : value.toStringAsFixed(2);
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
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
                _formattedValue,
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
}

class JsonResultViewer extends StatelessWidget {
  final Map<String, dynamic>? data;

  const JsonResultViewer({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
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

    // Move heavy JSON encoding inside the build method of this isolated widget
    const encoder = JsonEncoder.withIndent('  ');
    final jsonString = encoder.convert(data);

    return GlassCard(
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
            Container(
              width: double.infinity,
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
            ),
          ],
        ),
      ),
    );
  }
}

class AnalysisInfoCard extends StatelessWidget {
  const AnalysisInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.lightbulb_outline, size: 32, color: Colors.amber),
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
}

class TipCard extends StatelessWidget {
  const TipCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.tips_and_updates_outlined, size: 32, color: AppTheme.accentCyan),
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
}

class ErrorDisplayCard extends StatelessWidget {
  final String message;
  const ErrorDisplayCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentCyan),
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
    );
  }
}

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
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
          const TipCard(),
        ],
      ),
    );
  }
}