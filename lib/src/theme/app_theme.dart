// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'dart:ui';

class AppTheme {
  static const Color bgTop = Color(0xFF060607);
  static const Color bgBottom = Color(0xFF0B0B0D);
  static const Color accentCyan = Color(0xFF6BE6FF);
  static const Color accentViolet = Color(0xFF8A7CFF);
  static const Color mutedText = Color(0xFF9AA3A9);

  static const Duration motionFast = Duration(milliseconds: 160);
  static const Duration motionMedium = Duration(milliseconds: 220);
  static const Duration motionSlow = Duration(milliseconds: 320);

  static ThemeData light() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: bgTop,
      primaryColor: accentCyan,
      colorScheme: base.colorScheme.copyWith(primary: accentCyan),
      textTheme: _textTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'SFPro'),
        ),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'SFPro'),
      titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'SFPro'),
      titleMedium: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'SFPro'),
      bodyMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white, fontFamily: 'SFPro'),
      bodySmall: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: mutedText, fontFamily: 'SFPro'),
    );
  }

  Widget buildGlass(Widget child, {double borderRadius = 20}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14.0, sigmaY: 14.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white.withOpacity(0.03), Colors.white.withOpacity(0.02)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8, offset: Offset(0,4))],
          ),
          child: child,
        ),
      ),
    );
  }

  static BoxDecoration heroBackground() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [bgTop, bgBottom],
      ),
    );
  }

  static BoxDecoration pillDecoration() {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.02),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.03)),
    );
  }
}
