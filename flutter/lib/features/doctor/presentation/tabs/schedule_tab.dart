import 'package:flutter/material.dart';

import '../../data/doctor_models.dart';
import '../doctor_colors.dart';
import '../widgets/doctor_common.dart';

class ScheduleTab extends StatelessWidget {
  const ScheduleTab({
    super.key,
    required this.appointments,
    required this.onUpdateStatus,
    required this.onLogConsultation,
    required this.onRx,
    required this.onLab,
  });

  final List<DoctorAppointment> appointments;
  final void Function(String id, String status) onUpdateStatus;
  final VoidCallback onLogConsultation;
  final void Function(DoctorAppointment) onRx;
  final void Function(DoctorAppointment) onLab;

  @override
  Widget build(BuildContext context) {
    final waiting = appointments.where((a) => a.status == 'waiting').length;
    final inConsult = appointments
        .where((a) => a.status == 'in-consultation')
        .length;
    final completed = appointments.where((a) => a.status == 'completed').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, c) {
            final cardWidth = c.maxWidth >= 860
                ? (c.maxWidth - 12 * 3) / 4
                : c.maxWidth;
            final cards = [
              DoctorStatCard(
                icon: Icons.calendar_month_rounded,
                label: 'Total Scheduled',
                value: '${appointments.length}',
                accent: DoctorColors.blue,
              ),
              DoctorStatCard(
                icon: Icons.hourglass_top_rounded,
                label: 'Waiting List',
                value: '$waiting',
                accent: DoctorColors.amber,
                pulse: true,
              ),
              DoctorStatCard(
                icon: Icons.monitor_heart_rounded,
                label: 'In Consultation',
                value: '$inConsult',
                accent: DoctorColors.emerald,
              ),
              DoctorStatCard(
                icon: Icons.check_circle_rounded,
                label: 'Completed Visits',
                value: '$completed',
                accent: DoctorColors.emeraldLight,
              ),
            ];
            if (c.maxWidth < 860) {
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: cards
                    .map((c) => SizedBox(width: cardWidth, child: c))
                    .toList(),
              );
            }
            return Row(
              children: [
                for (final card in cards)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: card,
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        Container(
          decoration: BoxDecoration(
            color: DoctorColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: DoctorColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                decoration: const BoxDecoration(
                  color: DoctorColors.surfaceDeep,
                  border: Border(
                    bottom: BorderSide(color: DoctorColors.border),
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Daily Queue & Triaging',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                          SizedBox(height: 3),
                          Text(
                              'Real-time status updates from Front Desk OPD registry',
                              style: TextStyle(
                                  color: DoctorColors.textBody, fontSize: 11)),
                        ],
                      ),
                    ),
                    DoctorPrimaryButton(
                      label: 'Log Consultation',
                      icon: Icons.add_rounded,
                      onPressed: onLogConsultation,
                    ),
                  ],
                ),
              ),
              ...appointments.map((a) => _QueueRow(
                    a: a,
                    onCallIn: () => onUpdateStatus(a.id, 'in-consultation'),
                    onFinalize: () => onUpdateStatus(a.id, 'completed'),
                    onRx: () => onRx(a),
                    onLab: () => onLab(a),
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({
    required this.a,
    required this.onCallIn,
    required this.onFinalize,
    required this.onRx,
    required this.onLab,
  });

  final DoctorAppointment a;
  final VoidCallback onCallIn;
  final VoidCallback onFinalize;
  final VoidCallback onRx;
  final VoidCallback onLab;

  @override
  Widget build(BuildContext context) {
    final typeColor = a.type == 'Emergency'
        ? DoctorColors.rose
        : a.type == 'Follow-up'
            ? DoctorColors.blue
            : DoctorColors.emerald;

    final statusPill = switch (a.status) {
      'waiting' => const DoctorPill(
          label: 'Waiting Check-in', color: DoctorColors.amber),
      'in-consultation' => const DoctorPill(
          label: 'Active Care', color: DoctorColors.blue, pulse: true),
      _ => const DoctorPill(label: 'Checked Out', color: DoctorColors.emerald),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: DoctorColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF12463E).withOpacity(0.4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: DoctorColors.borderAccent),
            ),
            child: Text(a.initials,
                style: const TextStyle(
                    color: DoctorColors.emeraldLight,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    Text(a.patientName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    Text('${a.age} Y/O · ${a.gender}',
                        style: const TextStyle(
                            color: DoctorColors.textBody, fontSize: 11)),
                    DoctorPill(label: a.type, color: typeColor),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Chief complaint:',
                        style: TextStyle(
                            color: DoctorColors.emeraldLight,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(a.symptoms,
                          style: const TextStyle(
                              color: DoctorColors.textBody, fontSize: 11.5)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  children: [
                    _meta(Icons.schedule_rounded, 'Slot: ${a.time}'),
                    _meta(Icons.tag_rounded, 'ID: ${a.id}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              statusPill,
              const SizedBox(height: 10),
              if (a.status == 'waiting')
                _action('Call In', DoctorColors.blue, onCallIn)
              else if (a.status == 'in-consultation')
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _outlineAction('Rx', onRx),
                    const SizedBox(width: 6),
                    _outlineAction('Lab', onLab),
                    const SizedBox(width: 6),
                    _action('Finalize', DoctorColors.emerald, onFinalize),
                  ],
                )
              else
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: DoctorColors.emerald.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: DoctorColors.emerald.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.check_rounded,
                      size: 16, color: DoctorColors.emeraldLight),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: DoctorColors.textFaint),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(
                  color: DoctorColors.textFaint,
                  fontSize: 11,
                  fontFamily: 'monospace')),
        ],
      );

  Widget _action(String label, Color color, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ),
      );

  Widget _outlineAction(String label, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: DoctorColors.primary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: DoctorColors.borderAccent),
          ),
          child: Text(label,
              style: const TextStyle(
                  color: DoctorColors.emeraldLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ),
      );
}
