import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette extracted 1:1 from the website login page design.
class AppColors {
  AppColors._();

  // Outer / dark surfaces
  static const Color darkBg = Color(0xFF050E0C);
  static const Color brandDeep = Color(0xFF0B2B26); // #0B2B26
  static const Color brandMid = Color(0xFF0F3D35); // #0F3D35
  static const Color primary = Color(0xFF12463E); // #12463E

  // Emerald / teal accents
  static const Color emerald = Color(0xFF10B981); // #10b981
  static const Color emeraldLight = Color(0xFF34D399); // #34d399
  static const Color emeraldDark = Color(0xFF047857); // #047857
  static const Color tealAccent = Color(0xFF0D9488); // #0d9488

  // Light surfaces (right panel)
  static const Color pageTop = Color(0xFFF8FAF9); // #F8FAF9
  static const Color pageBottom = Color(0xFFF0F5F3); // #F0F5F3
  static const Color inputBg = Color(0xFFF6F8F7); // #F6F8F7
  static const Color inputBorder = Color(0xFFD7E2DC); // #D7E2DC
  static const Color tabBg = Color(0xFFEEF4F1); // #EEF4F1

  // Text
  static const Color textDark = Color(0xFF0B2B26);
  static const Color textStrong = Color(0xFF12463E);
  static const Color textBody = Color(0xFF6B8078); // #6B8078
  static const Color textMuted = Color(0xFF8AA098); // #8AA098
  static const Color textHint = Color(0xFF9CAEA6); // #9CAEA6
  static const Color textFaint = Color(0xFFC3CFC9); // #C3CFC9
  static const Color textMid = Color(0xFF4B5F58); // #4B5F58

  // Feedback
  static const Color error = Color(0xFFC4392A); // #C4392A
  static const Color accentRed = Color(0xFFE85C4A); // #E85C4A
  static const Color successDark = Color(0xFF047857);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.emerald,
      brightness: Brightness.light,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      splashFactory: InkSparkle.splashFactory,
      scaffoldBackgroundColor: AppColors.darkBg,
      fontFamily: 'Inter',
      textTheme: GoogleFonts.interTextTheme(),
    );

    return base;
  }
}