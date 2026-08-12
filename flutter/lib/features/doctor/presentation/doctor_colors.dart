import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Dark clinical palette matching the web doctor panel
/// (`frontend/src/app/(dashboard)/doctor/page.tsx`, Tailwind classes 1:1).
class DoctorColors {
  DoctorColors._();

  // Shell
  static const Color canvas = Color(0xFF050E0C);
  static const Color surface = Color(0xFF0C1E1A);
  static const Color surfaceDeep = Color(0xFF071310);
  static const Color border = Color(0xFF1B352E);
  static const Color borderAccent = Color(0xFF1E5D52);

  // Emerald / accents
  static const Color emerald = AppColors.emerald;
  static const Color emeraldLight = Color(0xFF34D399);
  static const Color emeraldDark = Color(0xFF047857);
  static const Color primary = Color(0xFF12463E);
  static const Color primaryHover = Color(0xFF1B564C);

  // Text
  static const Color textStrong = Color(0xFFE5ECE9);
  static const Color textBody = Color(0xFF8AA098);
  static const Color textFaint = Color(0xFF5C7D73);

  // Status
  static const Color blue = Color(0xFF3B82F6);
  static const Color amber = Color(0xFFF59E0B);
  static const Color rose = Color(0xFFF43F5E);
}
