import 'package:flutter/material.dart';

import '../patient_colors.dart';

/// KPI stat card used on the records tab (mirrors the white metric cards).
class PatientStatCard extends StatelessWidget {
  const PatientStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    this.soft,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final Color? soft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PatientColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: PatientColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: (soft ?? accent).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 22, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: PatientColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1)),
                const SizedBox(height: 5),
                Text(value,
                    style: const TextStyle(
                        color: PatientColors.textStrong,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded status pill (mirrors `bg-*-50 text-*-700 border-*-200`).
class PatientPill extends StatelessWidget {
  const PatientPill({
    super.key,
    required this.label,
    required this.soft,
    required this.text,
    required this.line,
  });

  final String label;
  final Color soft;
  final Color text;
  final Color line;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: line),
      ),
      child: Text(label.toUpperCase(),
          style: TextStyle(
              color: text, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
    );
  }
}

/// Dark-green primary action button (mirrors `bg-[#12463E]`).
class PatientPrimaryButton extends StatelessWidget {
  const PatientPrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.loading = false,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool loading;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loading ? null : onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 16,
            vertical: compact ? 9 : 12),
        decoration: BoxDecoration(
          color: PatientColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            else
              Icon(icon, size: compact ? 14 : 16, color: Colors.white),
            if (loading) const SizedBox(width: 8),
            if (!loading) ...[
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 11 : 12,
                      fontWeight: FontWeight.w700)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Light outlined secondary button.
class PatientOutlineButton extends StatelessWidget {
  const PatientOutlineButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 14,
            vertical: compact ? 9 : 11),
        decoration: BoxDecoration(
          color: PatientColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: PatientColors.borderStrong),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 13 : 15, color: PatientColors.primary),
            const SizedBox(width: 7),
            Text(label,
                style: TextStyle(
                    color: PatientColors.primary,
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

/// White section card with an optional header (title + subtitle + action).
class PatientSectionCard extends StatelessWidget {
  const PatientSectionCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.action,
    this.noPadding = false,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? action;
  final bool noPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PatientColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: PatientColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              color: const Color(0xFFEEF4F1).withValues(alpha: 0.4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title!,
                            style: const TextStyle(
                                color: PatientColors.textStrong,
                                fontSize: 16,
                                fontWeight: FontWeight.w800)),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(subtitle!,
                              style: const TextStyle(
                                  color: PatientColors.textBody, fontSize: 12)),
                        ],
                      ],
                    ),
                  ),
                  if (action != null) action!,
                ],
              ),
            ),
          Padding(
            padding: noPadding
                ? EdgeInsets.zero
                : const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Star row used for doctor ratings and the review modal.
class PatientStars extends StatelessWidget {
  const PatientStars({
    super.key,
    required this.rating,
    this.size = 14,
    this.showValue = false,
  });

  final double rating;
  final double size;
  final bool showValue;

  @override
  Widget build(BuildContext context) {
    final rounded = rating.round().clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Padding(
            padding: const EdgeInsets.only(right: 1),
            child: Icon(
              i <= rounded ? Icons.star_rounded : Icons.star_border_rounded,
              size: size,
              color: i <= rounded
                  ? PatientColors.amber
                  : const Color(0xFFD7E2DC),
            ),
          ),
        if (showValue) ...[
          const SizedBox(width: 5),
          Text(rating.toStringAsFixed(1),
              style: const TextStyle(
                  color: PatientColors.textStrong,
                  fontSize: 12,
                  fontWeight: FontWeight.w800)),
        ],
      ],
    );
  }
}

/// Empty-state column used inside patient section cards.
class PatientEmpty extends StatelessWidget {
  const PatientEmpty({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: PatientColors.surfaceAlt,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 30, color: PatientColors.textHint),
          ),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: PatientColors.textMuted,
                  fontSize: 12.5,
                  height: 1.5)),
        ],
      ),
    );
  }
}

/// Floating snack-bar helper for success/error notices.
void showPatientToast(BuildContext context, String message,
    {bool error = false}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            error ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            size: 18,
            color: Colors.white,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      backgroundColor:
          error ? PatientColors.roseText : PatientColors.emeraldDark,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: Duration(seconds: error ? 5 : 6),
    ),
  );
}
