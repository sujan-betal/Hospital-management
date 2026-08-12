import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Branded icon-leading text field matching the website's inputs.
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.icon,
    required this.hintText,
    this.controller,
    this.obscureText = false,
    this.textInputAction,
    this.keyboardType,
    this.onChanged,
    this.trailing,
    this.enabled = true,
    this.onSubmit,
  });

  final IconData icon;
  final String hintText;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final Widget? trailing;
  final bool enabled;
  final VoidCallback? onSubmit;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: widget.enabled ? 1 : 0.6,
        child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.inputBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _focused ? AppColors.primary : AppColors.inputBorder,
            width: _focused ? 1.5 : 1,
          ),
          boxShadow: _focused
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 14, right: 8),
              child: Icon(
                widget.icon,
                size: 18,
                color: _focused ? AppColors.primary : AppColors.textBody,
              ),
            ),
            Expanded(
              child: TextField(
                controller: widget.controller,
                enabled: widget.enabled,
                obscureText: widget.obscureText,
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction,
                onChanged: widget.onChanged,
                onSubmitted: (_) => widget.onSubmit?.call(),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 14,
                  ),
                  isDense: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textDark,
                ),
              ),
            ),
            if (widget.trailing != null) widget.trailing!,
            const SizedBox(width: 8),
          ],
        ),
        ),
      ),
    );
  }
}

/// Error message line with a leading dot (website error style).
class AuthErrorText extends StatelessWidget {
  const AuthErrorText(this.message, {super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 2),
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
              message!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}