import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Additional palette for the admin console, matching the web admin layout
/// (Tailwind classes translated 1:1).
class AdminColors {
  AdminColors._();

  // Dark shell
  static const Color sidebarBg = Color(0xFF0C1E1A);
  static const Color sidebarBorder = Color(0xFF1B352E);
  static const Color sidebarFooter = Color(0xFF071310);

  // Emerald scale (web: emerald-500/600/700)
  static const Color emerald500 = AppColors.emerald;
  static const Color emerald600 = Color(0xFF059669);
  static const Color emerald700 = AppColors.emeraldDark;

  // Status / accent scale
  static const Color blue = Color(0xFF3B82F6);
  static const Color blue50 = Color(0xFFEFF6FF);
  static const Color blue100 = Color(0xFFDBEAFE);
  static const Color rose = Color(0xFFF43F5E);
  static const Color rose50 = Color(0xFFFFF1F2);
  static const Color rose100 = Color(0xFFFFE4E6);
  static const Color ambery = Color(0xFFE8BA60);
  static const Color amber50 = Color(0xFFFFFBEB);
  static const Color amber100 = Color(0xFFFDE68A);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color purple50 = Color(0xFFFAF5FF);
  static const Color purple100 = Color(0xFFF3E8FF);
  static const Color teal = Color(0xFF14B8A6);
  static const Color teal50 = Color(0xFFF0FDFA);
  static const Color teal100 = Color(0xFFCCFBF1);
  static const Color violet = purple;
  static const Color amber = Color(0xFFF59E0B);
  static const Color darkAmber = Color(0xFFB45309);

  // Neutral shells
  static const Color canvas = Color(0xFFF1F5F4);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE8ECEB);
  static const Color borderLight = Color(0xFFD7E2DC);
  static const Color bgSoft = Color(0xFFF6F8F7);
  static const Color bgSubtle = Color(0xFFEEF4F1);
}