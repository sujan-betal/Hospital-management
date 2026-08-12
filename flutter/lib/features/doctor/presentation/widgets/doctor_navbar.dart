import 'dart:async';

import 'package:flutter/material.dart';

import '../doctor_colors.dart';

/// Top workspace bar with a live clock and an "On Duty" status pill.
class DoctorNavbar extends StatefulWidget {
  const DoctorNavbar({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  State<DoctorNavbar> createState() => _DoctorNavbarState();
}

class _DoctorNavbarState extends State<DoctorNavbar> {
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
        color: DoctorColors.surface,
        border: Border(bottom: BorderSide(color: DoctorColors.border)),
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
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4)),
                const SizedBox(height: 3),
                Text(widget.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: DoctorColors.textBody, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF12463E).withOpacity(0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: DoctorColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    size: 15, color: DoctorColors.emeraldLight),
                const SizedBox(width: 7),
                Text(_now,
                    style: const TextStyle(
                        color: DoctorColors.emeraldLight,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: DoctorColors.emerald.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DoctorColors.emerald.withOpacity(0.2)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 8, color: DoctorColors.emeraldLight),
                SizedBox(width: 7),
                Text('On Duty',
                    style: TextStyle(
                        color: DoctorColors.emeraldLight,
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
