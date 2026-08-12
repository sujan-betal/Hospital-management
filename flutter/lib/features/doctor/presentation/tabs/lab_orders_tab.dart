import 'package:flutter/material.dart';

import '../../data/doctor_models.dart';
import '../doctor_colors.dart';
import '../widgets/doctor_common.dart';

class LabOrdersTab extends StatelessWidget {
  const LabOrdersTab({
    super.key,
    required this.orders,
    required this.onNew,
  });

  final List<DoctorLabOrder> orders;
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
                  Text('Clinical Pathology & Diagnostic Orders',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text('Telemetry status, labs, imaging and diagnostic requests',
                      style: TextStyle(
                          color: DoctorColors.textBody, fontSize: 11.5)),
                ],
              ),
            ),
            DoctorPrimaryButton(
              label: 'Request Diagnostics',
              icon: Icons.add_rounded,
              onPressed: onNew,
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          decoration: BoxDecoration(
            color: DoctorColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: DoctorColors.border),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 820),
              child: Column(
                children: [
                  _header(),
                  ...orders.map((o) => _row(o)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _header() {
    const style = TextStyle(
        color: DoctorColors.textBody,
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 1);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: DoctorColors.surfaceDeep,
        border: Border(bottom: BorderSide(color: DoctorColors.border)),
      ),
      child: const Row(
        children: [
          _Cell(flex: 2, child: Text('ORDER ID', style: style)),
          _Cell(flex: 3, child: Text('PATIENT NAME', style: style)),
          _Cell(flex: 5, child: Text('REQUIRED DIAGNOSTICS', style: style)),
          _Cell(flex: 2, child: Text('PRIORITY', style: style)),
          _Cell(flex: 2, child: Text('STATUS', style: style)),
          _Cell(flex: 4, child: Text('RESULTS REFERENCE', style: style)),
        ],
      ),
    );
  }

  Widget _row(DoctorLabOrder o) {
    final priorityColor = switch (o.priority) {
      'stat' => DoctorColors.rose,
      'urgent' => DoctorColors.amber,
      _ => DoctorColors.blue,
    };
    final statusColor = switch (o.status) {
      'completed' => DoctorColors.emerald,
      'processing' => DoctorColors.blue,
      _ => DoctorColors.textFaint,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: DoctorColors.border)),
      ),
      child: Row(
        children: [
          _Cell(
            flex: 2,
            child: Text(o.id,
                style: const TextStyle(
                    color: DoctorColors.emeraldLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace')),
          ),
          _Cell(
            flex: 3,
            child: Text(o.patientName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700)),
          ),
          _Cell(
            flex: 5,
            child: Text(o.testType,
                style: const TextStyle(
                    color: DoctorColors.textBody,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ),
          _Cell(
            flex: 2,
            child: DoctorPill(
                label: o.priority, color: priorityColor, pulse: o.priority == 'stat'),
          ),
          _Cell(
            flex: 2,
            child: DoctorPill(label: o.status, color: statusColor),
          ),
          _Cell(flex: 4, child: _results(o)),
        ],
      ),
    );
  }

  Widget _results(DoctorLabOrder o) {
    if (o.results == null) {
      return const Text('Results pending processing...',
          style: TextStyle(
              color: DoctorColors.textFaint,
              fontSize: 11.5,
              fontStyle: FontStyle.italic));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(o.results!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white, fontSize: 11.5, fontStyle: FontStyle.italic)),
        if (o.abnormalFlag)
          const SizedBox(height: 6)
        else
          const SizedBox.shrink(),
        if (o.abnormalFlag)
          const DoctorPill(
            label: 'CRITICAL VALUE',
            color: DoctorColors.rose,
            pulse: true,
          ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.flex, required this.child});

  final int flex;
  final Widget child;

  @override
  Widget build(BuildContext context) => Expanded(flex: flex, child: child);
}
