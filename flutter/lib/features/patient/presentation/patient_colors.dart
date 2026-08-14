import 'package:flutter/material.dart';

/// Light patient portal palette matching the web patient panel
/// (`frontend/src/app/(dashboard)/patient/page.tsx`, Tailwind classes 1:1).
class PatientColors {
  PatientColors._();

  // Light canvas & surfaces
  static const Color canvas = Color(0xFFF0F5F3);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFEEF4F1);
  static const Color surfaceDeep = Color(0xFFF6F8F7);
  static const Color border = Color(0xFFE8ECEB);
  static const Color borderStrong = Color(0xFFD7E2DC);

  // Dark sidebar
  static const Color sidebar = Color(0xFF0C1E1A);
  static const Color sidebarDeep = Color(0xFF071310);
  static const Color sidebarBorder = Color(0xFF1B352E);
  static const Color sidebarAccent = Color(0xFF1E5D52);

  // Text
  static const Color textStrong = Color(0xFF0B2B26);
  static const Color primary = Color(0xFF12463E);
  static const Color primaryHover = Color(0xFF0B2B26);
  static const Color textBody = Color(0xFF6B8078);
  static const Color textMid = Color(0xFF4B5F58);
  static const Color textMuted = Color(0xFF8AA098);
  static const Color textHint = Color(0xFF9CAEA6);
  static const Color textFaint = Color(0xFFC3CFC9);

  // Accents
  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldLight = Color(0xFF34D399);
  static const Color emeraldDark = Color(0xFF047857);
  static const Color blue = Color(0xFF2563EB);
  static const Color amber = Color(0xFFF59E0B);
  static const Color rose = Color(0xFFE11D48);

  // Status soft fills (mirror emerald-50/blue-50/rose-50/amber-50)
  static const Color emeraldSoft = Color(0xFFECFDF5);
  static const Color emeraldLine = Color(0xFFA7F3D0);
  static const Color blueSoft = Color(0xFFEFF6FF);
  static const Color blueLine = Color(0xFFBFDBFE);
  static const Color roseSoft = Color(0xFFFFF1F2);
  static const Color roseLine = Color(0xFFFECDD3);
  static const Color amberSoft = Color(0xFFFFFBEB);
  static const Color amberLine = Color(0xFFFDE68A);

  // Status text (mirror emerald-700/blue-700/rose-700/amber-700)
  static const Color emeraldText = Color(0xFF047857);
  static const Color blueText = Color(0xFF1D4ED8);
  static const Color roseText = Color(0xFFBE123C);
  static const Color amberText = Color(0xFFB45309);
}
