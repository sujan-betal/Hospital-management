import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/repositories/auth_repository.dart';
import 'heartbeat_line.dart';
import 'patient_login_form.dart';
import 'staff_login_form.dart';

class LoginCard extends StatefulWidget {
  const LoginCard({super.key});

  @override
  State<LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends State<LoginCard> {
  bool _staff = false;

  /// Staff login → POST /api/admin/login, persist the session and route by role.
  Future<void> _staffLogin(String identifier, String password) async {
    final session = await AuthRepository.loginStaff(
      identifier: identifier,
      password: password,
    );
    await AuthRepository.saveSession(session);
    if (!mounted) return;
    _navigateByRole(session.role);
  }

  /// Patient OTP → POST /api/patient/otp/send. Returns the demo OTP shown by
  /// the dev-mode backend so the demo flow works without an SMS provider.
  Future<String?> _sendPatientOtp(String phone) async {
    final result = await AuthRepository.sendPatientOtp(phone);
    return result.demoOtp;
  }

  /// Patient verify → POST /api/patient/otp/verify, persist the session.
  Future<bool> _verifyPatientOtp(String phone, String otp) async {
    final session = await AuthRepository.verifyPatientOtp(phone: phone, otp: otp);
    await AuthRepository.saveSession(session);
    if (mounted) _navigateByRole(session.role);
    return true;
  }

  /// Redirect based on the `role` decoded from the token payload (web does the
  /// same: doctor → doctor, receptionist → receptionist, else admin).
  void _navigateByRole(String role) {
    final normalized = role.toLowerCase();
    final route = normalized == 'doctor'
        ? '/dashboard/doctor'
        : normalized == 'receptionist'
            ? '/dashboard/receptionist'
            : normalized == 'patient'
                ? '/dashboard/patient'
                : '/dashboard/admin';
    Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <_LoginTab>[
      _LoginTab(
        icon: Icons.smartphone,
        label: 'Patient',
        selected: !_staff,
        onTap: () => setState(() => _staff = false),
      ),
      _LoginTab(
        icon: Icons.verified_user,
        label: 'Staff',
        selected: _staff,
        onTap: () => setState(() => _staff = true),
      ),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.80),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.60)),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandDeep.withValues(alpha: 0.08),
                blurRadius: 60,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 36, 32, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sign in to access your medical portal',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textBody.withValues(alpha: 0.95),
                      ),
                    ),
                  ],
                ),
              ),

              // Heartbeat divider
              Transform.translate(
                offset: const Offset(0, -6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: HeartbeatLine(height: 22),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 8, 32, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _tabSwitcher(tabs),
                    const SizedBox(height: 28),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: _staff
                          ? StaffLoginForm(
                              key: const ValueKey('staff'),
                              onSubmit: _staffLogin,
                            )
                          : PatientLoginForm(
                              key: const ValueKey('patient'),
                              onSendOtp: _sendPatientOtp,
                              onVerify: _verifyPatientOtp,
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabSwitcher(List<_LoginTab> tabs) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final padding = 6.0;
        final tabWidth = (width - padding * 2) / 2;
        return Container(
          height: 48,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.tabBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            // Center the tab labels vertically so "Patient" / "Staff" sit in
            // the middle of the toggle (Stack defaults to topStart otherwise).
            alignment: Alignment.center,
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
                top: 0,
                bottom: 0,
                left: _staff ? tabWidth : 0,
                width: tabWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.emeraldDark.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(children: tabs),
            ],
          ),
        );
      },
    );
  }
}

class _LoginTab extends StatelessWidget {
  const _LoginTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: selected ? AppColors.textStrong : AppColors.textMuted,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.textStrong : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}