import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'auth_inputs.dart';

class StaffLoginForm extends StatefulWidget {
  const StaffLoginForm({super.key, this.onSubmit});

  /// Called once validation passes (placeholder until the API layer exists).
  final Future<void> Function(String identifier, String password)? onSubmit;

  @override
  State<StaffLoginForm> createState() => _StaffLoginFormState();
}

class _StaffLoginFormState extends State<StaffLoginForm> {
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _submitting = false;
  bool _showPassword = false;
  String? _identifierError;
  String? _passwordError;
  String? _serverError;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final errs = <String, String>{};
    if (_identifier.text.trim().length < 3) {
      errs['id'] = 'Enter your username or email';
    }
    if (_password.text.length < 6) {
      errs['pw'] = 'Password must be at least 6 characters';
    }
    setState(() {
      _identifierError = errs['id'];
      _passwordError = errs['pw'];
      _serverError = null;
    });
    if (errs.isNotEmpty) return;

    setState(() => _submitting = true);
    try {
      if (widget.onSubmit != null) {
        await widget.onSubmit!(_identifier.text.trim(), _password.text);
      }
    } catch (e) {
      setState(() => _serverError = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Username or Email',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            color: AppColors.textStrong,
          ),
        ),
        const SizedBox(height: 6),
        AuthTextField(
          controller: _identifier,
          icon: Icons.mail_outline,
          hintText: 'username or doctor@hospital.com',
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() => _identifierError = null),
        ),
        AuthErrorText(_identifierError),
        const SizedBox(height: 14),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Password',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                color: AppColors.textStrong,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        AuthTextField(
          controller: _password,
          icon: Icons.lock_outline,
          hintText: 'Enter your password',
          obscureText: !_showPassword,
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() => _passwordError = null),
          onSubmit: _submit,
          trailing: IconButton(
            padding: EdgeInsets.zero,
            iconSize: 18,
            color: AppColors.textHint,
            onPressed: () => setState(() => _showPassword = !_showPassword),
            icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: SizedBox(
              width: 130,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context)
                        .pushNamed('/forgot-password'),
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        'Forgot password?',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentRed,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AuthErrorText(_passwordError),
        const SizedBox(height: 12),

        if (_serverError != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFE2DF)),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _serverError!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),

        SizedBox(
          width: double.infinity,
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
                      Text('Sign in'),
                      SizedBox(width: 8),
                      Icon(Icons.login, size: 18),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 14),
        const Center(
          child: Text(
            'Contact your administrator if you need access',
            style: TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
        ),
      ],
    );
  }
}