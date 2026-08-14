import 'package:flutter/material.dart';

import '../../data/patient_models.dart';
import '../patient_colors.dart';
import 'patient_common.dart';

/// Wraps a modal body in the light portal chrome used by the web app.
Future<T?> showPatientModal<T>({
  required BuildContext context,
  required String title,
  required String subtitle,
  required IconData icon,
  required Color iconBg,
  required Color iconColor,
  required Widget child,
}) {
  return showDialog<T>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (context) => Dialog(
      backgroundColor: PatientColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: PatientColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: iconBg.withValues(alpha: 0.6)),
                    ),
                    child: Icon(icon, size: 20, color: iconColor),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                color: PatientColors.textStrong,
                                fontSize: 15,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: PatientColors.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded,
                        color: PatientColors.textBody, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(color: PatientColors.border),
              const SizedBox(height: 14),
              Flexible(child: SingleChildScrollView(child: child)),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Confirmation dialog (sign out, etc.) mirroring the web's modal buttons.
Future<bool> showPatientConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool danger = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (context) => Dialog(
      backgroundColor: PatientColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: PatientColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (danger ? PatientColors.rose : PatientColors.emerald)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                        danger
                            ? Icons.warning_amber_rounded
                            : Icons.logout_rounded,
                        size: 20,
                        color: danger
                            ? PatientColors.rose
                            : PatientColors.emeraldDark),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            color: PatientColors.textStrong,
                            fontSize: 15,
                            fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(message,
                  style: const TextStyle(
                      color: PatientColors.textMuted, fontSize: 12)),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: PatientColors.textBody,
                        side: const BorderSide(color: PatientColors.borderStrong),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: danger
                            ? const Color(0xFFE11D48)
                            : PatientColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(confirmLabel,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return result ?? false;
}

/// Reschedule an appointment (date + slot picker) — mirrors the web modal.
class RescheduleModalBody extends StatefulWidget {
  const RescheduleModalBody({
    super.key,
    required this.doctorName,
    required this.initialDate,
    required this.initialTime,
    required this.today,
    required this.bookedTimes,
    required this.onSave,
    required this.saving,
  });

  final String doctorName;
  final String initialDate;
  final String initialTime;
  final String today;
  final Set<String> bookedTimes;
  final Future<bool> Function(String date, String time) onSave;
  final bool saving;

  @override
  State<RescheduleModalBody> createState() => _RescheduleModalBodyState();
}

class _RescheduleModalBodyState extends State<RescheduleModalBody> {
  late String _date;
  late String _time;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
    _time = widget.initialTime;
  }

  bool _isTaken(String slot) {
    if (_date != widget.today) return false;
    final already = widget.initialDate == widget.today && widget.initialTime == slot;
    return widget.bookedTimes.contains(slot) && !already;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Date',
            style: TextStyle(
                color: PatientColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.parse(_date),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 180)),
            );
            if (picked != null) {
              setState(() {
                _date = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
              });
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: PatientColors.surfaceDeep,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: PatientColors.borderStrong),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded,
                    size: 16, color: PatientColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_date,
                      style: const TextStyle(
                          color: PatientColors.textStrong, fontSize: 13)),
                ),
                const Icon(Icons.arrow_drop_down_rounded,
                    color: PatientColors.textBody),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Preferred Time',
            style: TextStyle(
                color: PatientColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: patientSlots.map((slot) {
            final isCurrent = slot == _time;
            final taken = _isTaken(slot);
            return InkWell(
              onTap: taken ? null : () => setState(() => _time = slot),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? PatientColors.primary
                      : taken
                          ? PatientColors.surfaceAlt
                          : PatientColors.surfaceDeep,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: isCurrent
                          ? PatientColors.primary
                          : PatientColors.borderStrong),
                ),
                child: Text(slot,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                        color: isCurrent
                            ? Colors.white
                            : taken
                                ? PatientColors.textHint
                                : PatientColors.textStrong)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: PatientColors.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: PatientColors.borderStrong),
          ),
          child: Row(
            children: [
              const Icon(Icons.shield_rounded,
                  size: 16, color: PatientColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Rescheduling to $_date at $_time.',
                  style: const TextStyle(
                      color: PatientColors.textBody, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel',
                  style: TextStyle(
                      color: PatientColors.textBody, fontSize: 12)),
            ),
            const SizedBox(width: 8),
            PatientPrimaryButton(
              label: 'Save New Time',
              icon: Icons.edit_rounded,
              loading: widget.saving,
              onPressed: () async {
                final ok = await widget.onSave(_date, _time);
                if (ok && mounted) Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// Rate a doctor after a visit (stars + optional comment).
class RateDoctorModalBody extends StatefulWidget {
  const RateDoctorModalBody({
    super.key,
    required this.doctorName,
    required this.specialty,
    required this.onSubmit,
    required this.submitting,
  });

  final String doctorName;
  final String specialty;
  final Future<bool> Function(int rating, String comment) onSubmit;
  final bool submitting;

  @override
  State<RateDoctorModalBody> createState() => _RateDoctorModalBodyState();
}

class _RateDoctorModalBodyState extends State<RateDoctorModalBody> {
  int _rating = 0;
  final _comment = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('How was your visit?',
            style: TextStyle(
                color: PatientColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 1; i <= 5; i++)
              InkWell(
                onTap: () => setState(() => _rating = i),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Icon(
                    i <= _rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 34,
                    color: i <= _rating
                        ? PatientColors.amber
                        : const Color(0xFFE8ECEB),
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Text(_rating > 0 ? '$_rating/5' : '—',
                style: const TextStyle(
                    color: PatientColors.textStrong,
                    fontSize: 14,
                    fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Share your feedback (optional)',
            style: TextStyle(
                color: PatientColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        TextField(
          controller: _comment,
          maxLines: 4,
          maxLength: 2000,
          decoration: InputDecoration(
            hintText: 'e.g. The doctor was very patient and explained everything clearly…',
            hintStyle: const TextStyle(color: PatientColors.textHint, fontSize: 12),
            counterText: '',
            filled: true,
            fillColor: PatientColors.surfaceDeep,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: PatientColors.borderStrong),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: PatientColors.borderStrong),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: PatientColors.primary),
            ),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 14, color: PatientColors.rose),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(_error!,
                      style: const TextStyle(
                          color: PatientColors.roseText, fontSize: 11)),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel',
                  style: TextStyle(
                      color: PatientColors.textBody, fontSize: 12)),
            ),
            const SizedBox(width: 8),
            PatientPrimaryButton(
              label: 'Submit Review',
              icon: Icons.star_rounded,
              loading: widget.submitting,
              onPressed: () async {
                if (_rating < 1) {
                  setState(() => _error =
                      'Please select a star rating before submitting.');
                  return;
                }
                setState(() => _error = null);
                final ok = await widget.onSubmit(_rating, _comment.text.trim());
                if (ok && mounted) Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ],
    );
  }
}
