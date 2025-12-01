// lib/src/app.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/upload_screen.dart';
import 'screens/analyze_screen.dart';
import 'screens/recommend_screen.dart';
import 'screens/compatibility_screen.dart';
import 'screens/download_report_screen.dart';
import 'screens/confirm_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/profile_screen.dart';

import 'theme/app_theme.dart';

class ImgShapeApp extends StatefulWidget {
  const ImgShapeApp({super.key});

  @override
  State<ImgShapeApp> createState() => _ImgShapeAppState();
}

class _ImgShapeAppState extends State<ImgShapeApp> {
  late final GoRouter _router;
  StreamSubscription? _authSub;

  @override
  void initState() {
    super.initState();

    _router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => HomeScreen(),
        ),
        GoRoute(
          path: '/upload',
          builder: (context, state) => const UploadScreen(),
        ),
        GoRoute(
          path: '/analyze',
          builder: (context, state) => const AnalyzeScreen(),
        ),
        GoRoute(
          path: '/recommend',
          builder: (context, state) => const RecommendScreen(),
        ),
        GoRoute(
          path: '/compatibility',
          builder: (context, state) => const CompatibilityScreen(),
        ),
        GoRoute(
          path: '/download',
          builder: (context, state) => const DownloadReportScreen(),
        ),
        GoRoute(
          path: '/confirm',
          builder: (context, state) => const ConfirmScreen(),
        ),
        GoRoute(
          path: '/forgot',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/reset',
          builder: (context, state) => const ResetPasswordScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    );

    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      try {
        final session = (event as dynamic).session;
        if (session != null && session.user != null) {
          if (mounted) _router.go('/home');
        }
      } catch (_) {
        final sess = Supabase.instance.client.auth.currentSession;
        if (sess != null && sess.user != null) {
          if (mounted) _router.go('/home');
        }
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Imgshape',
      theme: AppTheme.light(),
      routerConfig: _router,
    );
  }
}