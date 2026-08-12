import 'package:flutter/material.dart';

import '../../data/doctor_models.dart';
import '../doctor_colors.dart';
import '../widgets/doctor_common.dart';

class ConsultationsTab extends StatelessWidget {
  const ConsultationsTab({
    super.key,
    required this.consultations,
    required this.onNew,
  });

  final List<DoctorConsultation> consultations;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Consultation Room & History',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text(
                      'Review diagnostic history, patient records, and activate remote consultation calls',
                      style: TextStyle(
                          color: DoctorColors.textBody, fontSize: 11.5)),
                ],
              ),
            ),
            DoctorPrimaryButton(
              label: 'Start Diagnosis Notes',
              icon: Icons.add_rounded,
              onPressed: onNew,
            ),
          ],
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, c) {
            if (c.maxWidth >= 900) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(flex: 1, child: _TelehealthPanel()),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: _HistoryList(consultations: consultations)),
                ],
              );
            }
            return Column(
              children: [
                const _TelehealthPanel(),
                const SizedBox(height: 16),
                _HistoryList(consultations: consultations),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _TelehealthPanel extends StatelessWidget {
  const _TelehealthPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 520,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DoctorColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: DoctorColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Telehealth Interface',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: DoctorColors.surfaceDeep,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: DoctorColors.border),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle,
                        size: 7, color: DoctorColors.emerald),
                    SizedBox(width: 6),
                    Text('LIVE FEED',
                        style: TextStyle(
                            color: DoctorColors.textBody,
                            fontSize: 9,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: DoctorColors.canvas,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DoctorColors.border),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: DoctorColors.surface.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: DoctorColors.border),
                      ),
                      child: const Text('Patient: Robert Downey Jr.',
                          style: TextStyle(
                              color: Colors.white, fontSize: 10)),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: DoctorColors.surface.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: DoctorColors.border),
                      ),
                      child: const Text('Dr. House (You)',
                          style: TextStyle(
                              color: DoctorColors.emeraldLight,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.videocam_rounded,
                            size: 46, color: DoctorColors.borderAccent),
                        SizedBox(height: 10),
                        Text('Virtual telehealth room initialized.',
                            style: TextStyle(
                                color: DoctorColors.textBody, fontSize: 11.5)),
                        SizedBox(height: 4),
                        Text('Channel: TLS-256 AES Sec',
                            style: TextStyle(
                                color: DoctorColors.textFaint,
                                fontSize: 10,
                                fontFamily: 'monospace')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _panelButton(
            label: 'Start Video Consultation',
            icon: Icons.videocam_rounded,
            filled: true,
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _panelButton(
            label: 'Mute Audio / Standby',
            icon: Icons.mic_off_rounded,
            filled: false,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _panelButton({
    required String label,
    required IconData icon,
    required bool filled,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled ? DoctorColors.primary : DoctorColors.surfaceDeep,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: filled
                  ? DoctorColors.borderAccent
                  : DoctorColors.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: filled ? Colors.white : DoctorColors.textBody),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      color: filled ? Colors.white : DoctorColors.textBody,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.consultations});

  final List<DoctorConsultation> consultations;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Historical Patient Diagnoses',
            style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        for (final c in consultations) ...[
          _HistoryCard(c: c),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.c});

  final DoctorConsultation c;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DoctorColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DoctorColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.patientName,
                        style: const TextStyle(
                            color: DoctorColors.emeraldLight,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('Date of session: ${c.date}',
                        style: const TextStyle(
                            color: DoctorColors.textBody, fontSize: 10.5)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: DoctorColors.surfaceDeep,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: DoctorColors.border),
                ),
                child: Text('REF: ${c.id}',
                    style: const TextStyle(
                        color: DoctorColors.textFaint,
                        fontSize: 10,
                        fontFamily: 'monospace')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: DoctorColors.border),
          const SizedBox(height: 12),
          _label('DIAGNOSIS / SYMPTOMS SUMMARY', DoctorColors.emeraldLight),
          const SizedBox(height: 5),
          Text(c.diagnosis,
              style: const TextStyle(
                  color: Colors.white, fontSize: 12, height: 1.45)),
          const SizedBox(height: 12),
          _label('TREATMENT & INTERVENTION PLAN', DoctorColors.textBody),
          const SizedBox(height: 5),
          Text(c.treatmentPlan,
              style: const TextStyle(
                  color: Colors.white, fontSize: 12, height: 1.45)),
          if (c.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DoctorColors.canvas,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DoctorColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SESSION TRANSCRIPT NOTES',
                      style: TextStyle(
                          color: DoctorColors.textFaint,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(c.notes,
                      style: const TextStyle(
                          color: DoctorColors.textBody,
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                          height: 1.45)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _label(String text, Color color) => Text(text,
      style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1));
}
