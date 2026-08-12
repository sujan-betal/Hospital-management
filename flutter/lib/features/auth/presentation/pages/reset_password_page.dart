import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../widgets/auth_inputs.dart';

/// Handles the emailed reset link inside the app itself.
///
/// Reached via `/reset-password` on web (the emailed link carries the token as
/// a query parameter, either path-style `?token=` or inside the `#/` fragment
/// used by Flutter's default hash router).
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key, this.token});

  /// Optional token passed directly as a route argument (non-web deep links).
  final String? token;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _showPassword = false;
  bool _submitting = false;
  bool _done = false;
  String? _token;
  String? _passwordError;
  String? _confirmError;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _token = widget.token ?? _tokenFromUri();
  }

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  /// Pulls the token out of the current URL, covering both the hash router
  /// (`/#/reset-password?token=...`) and path-style links (`/reset-password?token=...`).
  static String? _tokenFromUri() {
    final uri = Uri.base;
    final direct = uri.queryParameters['token'];
    if (direct != null && direct.isNotEmpty) return direct;
    final fragment = uri.fragment;
    if (fragment.isEmpty) return null;
    final fragUri = Uri.parse('http://localhost$fragment');
    final token = fragUri.queryParameters['token'];
    return (token == null || token.isEmpty) ? null : token;
  }

  Future<void> _submit() async {
    final errs = <String, String>{};
    if (_password.text.length < 6) {
      errs['pw'] = 'Password must be at least 6 characters';
    }
    if (_password.text != _confirm.text) {
      errs['confirm'] = 'Passwords do not match';
    }
    setState(() {
      _passwordError = errs['pw'];
      _confirmError = errs['confirm'];
      _formError = null;
    });
    if (errs.isNotEmpty) return;

    setState(() => _submitting = true);
    try {
      await AuthRepository.resetPassword(
        token: _token!,
        newPassword: _password.text,
      );
      if (!mounted) return;
      setState(() => _done = true);
      await Future<void>.delayed(const Duration(milliseconds: 2500));
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    } catch (e) {
      if (mounted) setState(() => _formError = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.pageTop, Colors.white, AppColors.pageBottom],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _buildCard(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandDeep.withValues(alpha: 0.08),
            blurRadius: 60,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.emerald, AppColors.emeraldDark],
                ),
              ),
              child: const Icon(Icons.lock_reset, size: 28, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Create a new password',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _done
                ? 'Your password has been updated. Redirecting to login...'
                : 'Set the password you\'ll use to sign in to your portal.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textBody),
          ),
          const SizedBox(height: 24),
          if (_token == null || _token!.isEmpty) ...[
            _invalidLink(),
          ] else if (_done) ...[
            const Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppColors.emerald,
            ),
            const SizedBox(height: 12),
            const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.emerald,
                ),
              ),
            ),
          ] else ...[
            _form(),
          ],
        ],
      ),
    );
  }

  Widget _invalidLink() {
    return Column(
      children: [
        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
        const SizedBox(height: 12),
        const Text(
          'Invalid reset link',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textStrong,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'This link is missing or malformed. Please request a new one.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.textBody),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context)
                .pushNamedAndRemoveUntil('/login', (_) => false),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Back to login',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'New password',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            color: AppColors.textStrong,
          ),
        ),
        const SizedBox(height: 6),
        AuthTextField(
          controller: _password,
          icon: Icons.lock_outline,
          hintText: 'At least 6 characters',
          obscureText: !_showPassword,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() => _passwordError = null),
          trailing: IconButton(
            padding: EdgeInsets.zero,
            iconSize: 18,
            color: AppColors.textHint,
            onPressed: () => setState(() => _showPassword = !_showPassword),
            icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
          ),
        ),
        AuthErrorText(_passwordError),
        const SizedBox(height: 14),
        const Text(
          'Confirm password',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            color: AppColors.textStrong,
          ),
        ),
        const SizedBox(height: 6),
        AuthTextField(
          controller: _confirm,
          icon: Icons.lock_outline,
          hintText: 'Re-enter your password',
          obscureText: !_showPassword,
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() => _confirmError = null),
          onSubmit: _submit,
        ),
        AuthErrorText(_confirmError),
        if (_formError != null) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFE2DF)),
            ),
            child: Text(
              _formError!,
              style: const TextStyle(fontSize: 12, color: AppColors.error),
            ),
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor:
                  AppColors.primary.withValues(alpha: 0.7),
              foregroundColor: Colors.white,
              elevation: 6,
              shadowColor: AppColors.primary.withValues(alpha: 0.25),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Set password'),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
