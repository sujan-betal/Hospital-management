import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/admin_models.dart';
import '../admin_colors.dart';
import '../widgets/admin_common.dart';

class AttendingDoctorsTab extends StatefulWidget {
  const AttendingDoctorsTab({super.key, required this.doctors});

  final List<Doctor> doctors;

  @override
  State<AttendingDoctorsTab> createState() => _AttendingDoctorsTabState();
}

class _AttendingDoctorsTabState extends State<AttendingDoctorsTab> {
  String _search = '';
  String _statusFilter = 'all';

  List<Doctor> get _filtered {
    return widget.doctors.where((d) {
      final q = _search.toLowerCase();
      final okSearch = q.isEmpty ||
          d.name.toLowerCase().contains(q) ||
          d.specialty.toLowerCase().contains(q);
      final okStatus = _statusFilter == 'all' ||
          _doctorStatusLabel(d.status) == _statusFilter;
      return okSearch && okStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.doctors.length;
    final onDuty = widget.doctors.where((d) => d.status == DoctorStatus.onDuty).length;
    final onCall = widget.doctors.where((d) => d.status == DoctorStatus.onCall).length;
    final patientLoad =
        widget.doctors.fold<int>(0, (acc, d) => acc + d.activePatients);
    final avgLoad = total == 0 ? 0 : patientLoad / total;

    return ListView(
      padding: const EdgeInsets.all(2),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth >= 900
                ? 3
                : constraints.maxWidth >= 600
                    ? 2
                    : 1;
            final width = (constraints.maxWidth - (cols - 1) * 16) / cols;
            final cards = [
              KpiCard(
                label: 'Medical Staff Directory',
                value: '$total Physicians',
                sub: 'Credentials verified',
                icon: Icons.medical_services_rounded,
              ),
              KpiCard(
                label: 'Currently On Shift',
                value: '$onDuty On Duty',
                sub: '$onCall on backup call',
                icon: Icons.schedule_rounded,
                iconBg: AdminColors.blue50,
                iconColor: AdminColors.blue,
              ),
              KpiCard(
                label: 'Active Clinical Load',
                value: '$patientLoad Patients',
                sub: 'Avg ${avgLoad.toStringAsFixed(1)} patients per physician',
                icon: Icons.group_rounded,
                iconBg: AdminColors.rose50,
                iconColor: AdminColors.rose,
              ),
            ];
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (var i = 0; i < cards.length; i++)
                  SizedBox(width: width, child: cards[i]),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        _filterBar(),
        const SizedBox(height: 20),
        if (_filtered.isEmpty)
          const AdminEmpty(message: 'No doctors match your filter settings.')
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= 1200
                  ? 3
                  : constraints.maxWidth >= 760
                      ? 2
                      : 1;
              final width = (constraints.maxWidth - (cols - 1) * 20) / cols;
              return Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  for (final d in _filtered)
                    SizedBox(width: width, child: _DoctorCard(doctor: d)),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _filterBar() {
    return AdminCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 700;
          final search = AdminSearchField(
            hint: 'Search doctors by Name, Specialty…',
            value: _search,
            onChanged: (v) => setState(() => _search = v),
          );
          final filter = SegmentedFilter(
            options: ['all', 'On Duty', 'On Call', 'Off Duty'],
            selected: _statusFilter,
            onChanged: (v) => setState(() => _statusFilter = v),
          );
          if (isWide) {
            return Row(
              children: [
                SizedBox(width: 320, child: search),
                const Spacer(),
                filter,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerLeft, child: filter),
            ],
          );
        },
      ),
    );
  }
}

String _doctorStatusLabel(DoctorStatus s) => switch (s) {
      DoctorStatus.onDuty => 'On Duty',
      DoctorStatus.onCall => 'On Call',
      DoctorStatus.offDuty => 'Off Duty',
    };

class _DoctorCard extends StatelessWidget {
  const _DoctorCard({required this.doctor});

  final Doctor doctor;

  (Color, Color, IconData) get _statusMeta => switch (doctor.status) {
        DoctorStatus.onDuty => (AdminColors.emerald500.withOpacity(0.08), AdminColors.emerald700, Icons.trending_up_rounded),
        DoctorStatus.onCall => (AdminColors.amber50, const Color(0xFFD97706), Icons.phone_in_talk_rounded),
        DoctorStatus.offDuty => (const Color(0xFFF3F4F6), const Color(0xFF6B7280), Icons.coffee_outlined),
      };

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = _statusMeta;
    return AdminCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doctor.id.toUpperCase(),
                        style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppColors.textMuted)),
                    const SizedBox(height: 3),
                    Text(doctor.name,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                  ],
                ),
              ),
              Pill(
                label: doctor.status.name.split('_').join(' '),
                bg: bg,
                fg: fg,
                icon: icon,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.mail_outline_rounded, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 7),
              Expanded(
                child: Text(doctor.email,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textBody)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.phone_outlined, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 7),
              Text(doctor.phone,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textBody)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AdminColors.bgSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AdminColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.work_history_rounded, size: 15, color: AdminColors.emerald600),
                const SizedBox(width: 7),
                const Text('Attendant:',
                    style: TextStyle(fontSize: 11.5, color: AppColors.textMid)),
                const Spacer(),
                Text(doctor.specialty,
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AdminColors.bgSoft),
          const SizedBox(height: 12),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Patient Load',
                      style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  const SizedBox(height: 2),
                  Text('${doctor.activePatients} Active',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textDark)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: AdminColors.bgSubtle,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AdminColors.borderLight),
                ),
                child: const Text('Shift active',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AdminColors.emerald600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}