import 'package:flutter/material.dart';

import '../../data/doctor_models.dart';
import '../doctor_colors.dart';
import '../widgets/doctor_common.dart';

class PrescriptionsTab extends StatelessWidget {
  const PrescriptionsTab({
    super.key,
    required this.prescriptions,
    required this.onNew,
  });

  final List<DoctorPrescription> prescriptions;
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
                  Text('Active Patient Prescriptions',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text(
                      'Write digital prescriptions directly dispatchable to the hospital pharmacy',
                      style: TextStyle(
                          color: DoctorColors.textBody, fontSize: 11.5)),
                ],
              ),
            ),
            DoctorPrimaryButton(
              label: 'New Prescription',
              icon: Icons.add_rounded,
              onPressed: onNew,
            ),
          ],
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, c) {
            final twoCol = c.maxWidth >= 760;
            final cards = prescriptions.map((p) => _PrescriptionCard(p: p));
            if (!twoCol) {
              return Column(
                  children: [
                    for (final card in cards) ...[
                      card,
                      const SizedBox(height: 14),
                    ],
                  ]);
            }
            return GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.05,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: cards.toList(),
            );
          },
        ),
      ],
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  const _PrescriptionCard({required this.p});

  final DoctorPrescription p;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.patientName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text('Prescribed on: ${p.date}',
                        style: const TextStyle(
                            color: DoctorColors.textBody, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: DoctorColors.surfaceDeep,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: DoctorColors.border),
                ),
                child: Text('ID: ${p.id}',
                    style: const TextStyle(
                        color: DoctorColors.textFaint,
                        fontSize: 10,
                        fontFamily: 'monospace')),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: DoctorColors.border),
          const SizedBox(height: 12),
          const Text('MEDICINES & SCHEDULE',
              style: TextStyle(
                  color: DoctorColors.textBody,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2)),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final med in p.medicines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: DoctorColors.surfaceDeep.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: DoctorColors.border.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(med.name,
                                    style: const TextStyle(
                                        color: DoctorColors.emeraldLight,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text(med.dosage,
                                    style: const TextStyle(
                                        color: DoctorColors.textBody,
                                        fontSize: 11)),
                              ],
                            ),
                          ),
                          Text(med.duration,
                              style: const TextStyle(
                                  color: DoctorColors.textFaint,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (p.notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DoctorColors.emerald.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: DoctorColors.emerald.withOpacity(0.12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SPECIAL ADVICE',
                      style: TextStyle(
                          color: DoctorColors.emeraldLight,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Text(p.notes,
                      style: TextStyle(
                          color: DoctorColors.emeraldLight.withOpacity(0.9),
                          fontSize: 11.5,
                          height: 1.4)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
