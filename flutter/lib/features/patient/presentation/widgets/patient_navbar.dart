import 'dart:async';

import 'package:flutter/material.dart';

import '../patient_colors.dart';

/// Top workspace bar with a live clock and the patient's phone badge.
class PatientNavbar extends StatefulWidget {
  const PatientNavbar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.phone,
  });

  final String title;
  final String subtitle;
  final String phone;

  @override
  State<PatientNavbar> createState() => _PatientNavbarState();
}

class _PatientNavbarState extends State<PatientNavbar> {
  Timer? _timer;
  late String _now;

  @override
  void initState() {
    super.initState();
    _now = _format(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = _format(DateTime.now()));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  static String _format(DateTime t) {
    final h = t.hour > 12 ? t.hour - 12 : (t.hour == 0 ? 12 : t.hour);
    final mm = t.minute.toString().padLeft(2, '0');
    final ap = t.hour >= 12 ? 'PM' : 'AM';
    return '$h:$mm $ap';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: PatientColors.surface,
        border: Border(bottom: BorderSide(color: PatientColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: PatientColors.textStrong,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4)),
                const SizedBox(height: 3),
                Text('Aura Medical Center patient portal console.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: PatientColors.textBody, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: PatientColors.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: PatientColors.borderStrong),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    size: 15, color: PatientColors.primary),
                const SizedBox(width: 7),
                Text(_now,
                    style: const TextStyle(
                        color: PatientColors.primary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: PatientColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: PatientColors.borderStrong),
            ),
            child: Row(
              children: [
                const Icon(Icons.smartphone_rounded,
                    size: 14, color: PatientColors.primary),
                const SizedBox(width: 7),
                Text(widget.phone.isEmpty ? 'Logged in via OTP' : widget.phone,
                    style: const TextStyle(
                        color: PatientColors.primary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
