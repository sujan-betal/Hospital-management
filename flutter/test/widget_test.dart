// Basic smoke test for the Hospital Management Flutter app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hospital_management/core/theme/app_theme.dart';
import 'package:hospital_management/features/auth/presentation/pages/login_page.dart';

void main() {
  testWidgets('Login page renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const LoginPage(),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('AURA Medical'), findsWidgets);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in to access your medical portal'), findsOneWidget);
  });
}