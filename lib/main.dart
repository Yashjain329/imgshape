// lib/main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'src/app.dart';
import 'src/config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _AppEntry());
}

class _AppEntry extends StatefulWidget {
  const _AppEntry({super.key});

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  late Future<_InitResult> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initializeAll().timeout(const Duration(seconds: 20),
        onTimeout: () => _InitResult(
            success: false,
            message:
            'Initialization timed out. Check network / .env / backend.'));
  }

  Future<_InitResult> _initializeAll() async {
    try {
      try {
        await Config.loadEnvSafely();
      } catch (e) {
        return _InitResult(
            success: false, message: 'Failed to load .env: $e');
      }

      if (Config.supabaseUrl == null ||
          Config.supabaseUrl!.isEmpty ||
          Config.supabaseAnonKey == null ||
          Config.supabaseAnonKey!.isEmpty) {
        return _InitResult(
          success: false,
          message:
          'Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env (see README).',
        );
      }

      try {
        await Supabase.initialize(
          url: Config.supabaseUrl!,
          anonKey: Config.supabaseAnonKey!,
        ).timeout(const Duration(seconds: 8));
      } catch (e) {
        return _InitResult(
            success: false, message: 'Supabase init failed: $e');
      }

      // successful init
      return _InitResult(success: true);
    } catch (e, st) {
      debugPrint('Initialization error: $e\n$st');
      return _InitResult(success: false, message: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_InitResult>(
      future: _initFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Starting Imgshape...'),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final res = snap.data;
        if (res == null || !res.success) {
          final message = res?.message ?? 'Unknown initialization error';
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 64),
                        const SizedBox(height: 12),
                        Text('Initialization failed',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(message, textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _initFuture = _initializeAll().timeout(
                                  const Duration(seconds: 20),
                                  onTimeout: () => _InitResult(
                                      success: false,
                                      message:
                                      'Initialization timed out. Check network / .env / backend.'));
                            });
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        return const ImgShapeApp();
      },
    );
  }
}

class _InitResult {
  final bool success;
  final String? message;
  _InitResult({required this.success, this.message});
}