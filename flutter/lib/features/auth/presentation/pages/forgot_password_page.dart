import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../widgets/auth_inputs.dart';

/// Lets a staff member request a password-set link by entering their email.
///
/// Mirrors the website's `/forgot-password` flow and calls the same backend
/// endpoint (`POST /api/doctor/forgot-password`).
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _email = TextEditingController();

  bool _submitting = false;
  bool _sent = false;
  String? _emailError;
  String? _formError;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  static final RegExp _emailPattern = RegExp(r'^\S+@\S+\.\S+$');

  Future<void> _submit() async {
    final email = _email.text.trim();
    final errs = <String, String>{};
    if (!_emailPattern.hasMatch(email)) {
      errs['email'] = 'Enter a valid email address';
    }
    setState(() {
      _emailError = errs['email'];
      _formError = null;
    });
    if (errs.isNotEmpty) return;

    setState(() => _submitting = true);
    try {
      await AuthRepository.forgotPassword(email: email);
      if (!mounted) return;
      setState(() => _sent = true);
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
          Text(
            _sent ? 'Check your inbox' : 'Reset your password',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _sent
                ? 'If an account exists for ${_email.text.trim()}, a password-set link has been sent to it.'
                : 'Enter your account email and we\'ll send you a secure link to create a new password.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textBody),
          ),
          const SizedBox(height: 24),
          if (_sent)
            Column(
              children: [
                const Icon(
                  Icons.mark_email_read_outlined,
                  size: 56,
                  color: AppColors.emerald,
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
                      'Back to sign in',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            )
          else
            _form(),
        ],
      ),
    );
  }

  Widget _form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Email address',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            color: AppColors.textStrong,
          ),
        ),
        const SizedBox(height: 6),
        AuthTextField(
          controller: _email,
          icon: Icons.mail_outline,
          hintText: 'doctor@hospital.com',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() => _emailError = null),
          onSubmit: _submit,
        ),
        AuthErrorText(_emailError),
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
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.7),
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
                      Text('Send reset link'),
                      SizedBox(width: 8),
                      Icon(Icons.send, size: 18),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back, size: 16),
                SizedBox(width: 6),
                Text('Back to sign in'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
