import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../admin/data/admin_models.dart';
import '../../../admin/presentation/admin_colors.dart';
import '../../../admin/presentation/widgets/admin_common.dart';
import '../../data/receptionist_models.dart';

/// Clinic analytics — live front-desk metrics, visit trend and bed occupancy.
/// Mirrors the web receptionist analytics section (reads only).
class AnalyticsTab extends StatelessWidget {
  const AnalyticsTab({
    super.key,
    required this.stats,
    required this.appointments,
    required this.beds,
  });

  final DashboardStats stats;
  final List<Appointment> appointments;
  final List<Bed> beds;

  @override
  Widget build(BuildContext context) {
    final total = beds.isEmpty ? 1 : beds.length;
    final occupied = beds.where((b) => b.status == BedStatus.occupied).length;
    final occupancy = stats.occupancyRate > 0
        ? stats.occupancyRate
        : (occupied / total * 100).round();

    final confirmed = appointments
        .where((a) => a.status.toUpperCase() == 'CONFIRMED')
        .length;
    final completed = appointments
        .where((a) => a.status.toUpperCase() == 'COMPLETED')
        .length;

    final kpis = [
      KpiCard(
        label: 'Today’s Visits',
        value: '${stats.todayVisits}',
        sub: '${stats.checkedInToday} checked in',
        icon: Icons.groups_2_rounded,
        iconBg: AdminColors.blue50,
        iconColor: AdminColors.blue,
        trend: 'Front desk traffic',
        trendUp: true,
      ),
      KpiCard(
        label: 'Total Patients',
        value: '${stats.totalPatients}',
        sub: 'in the registry',
        icon: Icons.person_add_alt_1_rounded,
        iconBg: AdminColors.purple50,
        iconColor: AdminColors.purple,
        trend: 'All-time records',
        trendUp: true,
      ),
      KpiCard(
        label: 'Bed Occupancy',
        value: '$occupancy%',
        sub: '$occupied of $total beds in use',
        icon: Icons.meeting_room_rounded,
        iconBg: AdminColors.emerald500.withOpacity(0.1),
        iconColor: AdminColors.emerald700,
        trend: '${stats.occupiedBeds} occupied',
        trendUp: true,
      ),
      KpiCard(
        label: 'Outstanding',
        value: formatMoney(stats.unpaidInvoices),
        sub: '${stats.unpaidBillings} unpaid invoices',
        icon: Icons.account_balance_wallet_rounded,
        iconBg: AdminColors.rose50,
        iconColor: AdminColors.rose,
        trend: 'Pending collections',
        trendUp: false,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const SectionHeader(
          title: 'Clinic Analytics',
          subtitle: 'Live front-desk overview',
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: 20,
            runSpacing: 20,
            children: kpis,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: AdminCard(
                padding: const EdgeInsets.all(20),
                child: _WeeklyTrend(appointments: appointments),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 2,
              child: AdminCard(
                padding: const EdgeInsets.all(20),
                child: _AppointmentMix(
                  confirmed: confirmed,
                  completed: completed,
                  scheduled:
                      appointments.length - confirmed - completed,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WeeklyTrend extends StatelessWidget {
  const _WeeklyTrend({required this.appointments});

  final List<Appointment> appointments;

  @override
  Widget build(BuildContext context) {
    final byDay = <String, int>{};
    for (final a in appointments) {
      final day = _dayLabel(a.date);
      byDay[day] = (byDay[day] ?? 0) + 1;
    }
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final counts = [for (final d in days) byDay[d] ?? 0];
    final maxCount = counts.fold<int>(1, (m, c) => c > m ? c : m);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Weekly Visits',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark)),
        const SizedBox(height: 4),
        Text('Appointments booked across the week',
            style: const TextStyle(
                fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 20),
        SizedBox(
          height: 160,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < days.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('${counts[i]}',
                          style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMid)),
                      const SizedBox(height: 4),
                      Container(
                        height:
                            (counts[i] / maxCount * 110).clamp(6, 110).toDouble(),
                        decoration: BoxDecoration(
                          color: counts[i] == maxCount && maxCount > 1
                              ? AdminColors.emerald600
                              : AdminColors.emerald500.withOpacity(0.45),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(days[i],
                          style: const TextStyle(
                              fontSize: 10.5, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _dayLabel(String iso) {
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return 'Mon';
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[parsed.weekday - 1];
  }
}

class _AppointmentMix extends StatelessWidget {
  const _AppointmentMix({
    required this.confirmed,
    required this.completed,
    required this.scheduled,
  });

  final int confirmed;
  final int completed;
  final int scheduled;

  @override
  Widget build(BuildContext context) {
    final total = (confirmed + completed + scheduled).clamp(1, 1 << 31);
    final rows = [
      ('Scheduled', scheduled, AdminColors.amber),
      ('Confirmed', confirmed, AdminColors.blue),
      ('Completed', completed, AdminColors.teal),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Appointment Mix',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark)),
        const SizedBox(height: 4),
        Text('$total total OPD visits',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 20),
        for (final (label, value, color) in rows) ...[
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.textDark)),
              ),
              Text('$value',
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: value / total,
              minHeight: 8,
              backgroundColor: AdminColors.bgSoft,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 14),
        ],
        const Divider(height: 1, color: AdminColors.border),
        const SizedBox(height: 14),
        Row(
          children: [
            const Icon(Icons.bolt_rounded,
                size: 16, color: AdminColors.ambery),
            const SizedBox(width: 8),
            Expanded(
              child: Text('${statsText()}',
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMid)),
            ),
          ],
        ),
      ],
    );
  }

  String statsText() {
    final pct = completed * 100 ~/ (confirmed + completed + scheduled).clamp(1, 1 << 31);
    return '${pct}% of OPD visits completed';
  }
}