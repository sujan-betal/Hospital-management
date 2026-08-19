import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hospital_management/core/theme/app_theme.dart';
import 'package:hospital_management/features/auth/presentation/pages/login_page.dart';

void main() {
  testWidgets('Patient / Staff toggle labels are centered in the buttons',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const LoginPage(),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Patient'), findsOneWidget);
    expect(find.text('Staff'), findsOneWidget);

    // The toggle Stack must center its children vertically (default is
    // topStart, which pushed the labels to the top of the 48px bar).
    for (final label in ['Patient', 'Staff']) {
      final toggleStack = tester.widget<Stack>(
        find.ancestor(
          of: find.text(label),
          matching: find.byType(Stack),
        ).first,
      );
      expect(toggleStack.alignment, Alignment.center,
          reason: '"$label" tab should be centered in the toggle');
    }
  });
}