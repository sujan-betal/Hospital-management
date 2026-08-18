import 'package:flutter/material.dart';

import '../patient_colors.dart';
import 'patient_navbar.dart';
import 'patient_sidebar.dart';

/// Responsive dashboard shell (fixed sidebar on desktop, drawer on mobile)
/// that composes the patient portal chrome — dark sidebar + light workspace.
class PatientScaffold extends StatelessWidget {
  const PatientScaffold({
    super.key,
    required this.current,
    required this.userName,
    required this.userPhone,
    required this.onSelect,
    required this.onSignOut,
    required this.body,
  });

  final PatientTab current;
  final String userName;
  final String userPhone;
  final ValueChanged<PatientTab> onSelect;
  final VoidCallback onSignOut;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 960;

        final sidebar = PatientSidebar(
          current: current,
          userName: userName,
          userPhone: userPhone,
          onSelect: onSelect,
          onSignOut: onSignOut,
        );

        final content = AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: KeyedSubtree(key: ValueKey(current), child: body),
        );

        if (!isDesktop) {
          final scaffoldKey = GlobalKey<ScaffoldState>();
          return Scaffold(
            key: scaffoldKey,
            backgroundColor: PatientColors.canvas,
            drawer: Drawer(
              backgroundColor: PatientColors.sidebar,
              width: 280,
              child: sidebar,
            ),
            body: Column(
              children: [
                PatientNavbar(
                  title: current.label,
                  subtitle: 'Aura Medical Center patient portal console.',
                  phone: userPhone,
                  onMenuTap: () => scaffoldKey.currentState?.openDrawer(),
                ),
                Expanded(child: content),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: PatientColors.canvas,
          body: Row(
            children: [
              sidebar,
              Expanded(
                child: Column(
                  children: [
                    PatientNavbar(
                      title: current.label,
                      subtitle: 'Aura Medical Center patient portal console.',
                      phone: userPhone,
                    ),
                    Expanded(
                      child: Container(
                        color: PatientColors.canvas,
                        padding: const EdgeInsets.all(24),
                        child: content,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}