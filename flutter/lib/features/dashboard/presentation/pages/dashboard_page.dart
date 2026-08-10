import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/repositories/auth_repository.dart';

/// Minimal post-login landing that proves the authenticated session works.
/// Swap this out for the real role-based dashboards.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.portal});

  final String portal;

  @override
  Widget build(BuildContext context) {
    final user = AuthRepository.cachedUser;
    final name = user?['user_name'] ?? user?['name'] ?? 'User';
    final email = user?['email'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: Text('$portal Portal'),
        backgroundColor: AppColors.emerald,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_user,
                size: 64, color: AppColors.emeraldDark),
            const SizedBox(height: 16),
            Text(
              'Welcome, $name',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            if (email != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  email,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                (user?['role'] ?? portal).toString().toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () async {
                await AuthRepository.clearSession();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (_) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Log out'),
            ),
          ],
        ),
      ),
    );
  }
}