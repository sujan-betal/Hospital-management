import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/admin_models.dart';
import '../admin_colors.dart';
import '../widgets/admin_common.dart';
import '../widgets/admin_sidebar.dart';

/// Chief Officer Console overview — mirrors the web `Overview.tsx`.
class OverviewTab extends StatelessWidget {
  const OverviewTab({
    super.key,
    required this.beds,
    required this.admissions,
    required this.tasks,
    required this.onNavigate,
    required this.onAddAdmission,
    required this.onAddTask,
  });

  final List<Bed> beds;
  final List<Admission> admissions;
  final List<MedicalTask> tasks;
  final ValueChanged<AdminTab> onNavigate;
  final VoidCallback onAddAdmission;
  final VoidCallback onAddTask;

  @override
  Widget build(BuildContext context) {
    final occupied = beds.where((b) => b.status == BedStatus.occupied).length;
    final available = beds.where((b) => b.status == BedStatus.available).length;
    final sanitizing = beds.where((b) => b.status == BedStatus.sanitizing).length;
    final reserved = beds.where((b) => b.status == BedStatus.reserved).length;
    final total = beds.isEmpty ? 1 : beds.length;
    final occupancy = (occupied / total * 100).round();

    final activeAdmissions = admissions
        .where((a) =>
            a.status == AdmissionStatus.admitted ||
            a.status == AdmissionStatus.scheduled)
        .length;

    final dailyBilling = beds
        .where((b) => b.status == BedStatus.occupied)
        .fold<int>(0, (acc, b) => acc + b.price);

    final pendingTasks =
        tasks.where((t) => t.status != TaskStatus.completed).length;

    const weeklyData = [
      ('Mon', 45), ('Tue', 58), ('Wed', 70), ('Thu', 64),
      ('Fri', 82), ('Sat', 90), ('Sun', 52),
    ];

    final recentActivities = [
      _Activity('admission', 'Robert Downey Jr.', 'Checked into Bed ICU-101 (Critical Telemetry)', 'Just now'),
      _Activity('task', 'Staff (Nurse Maria)', 'Completed blood drawing for Emma Watson (GEN-301)', '15 mins ago'),
      _Activity('scheduled', 'Leonardo DiCaprio', 'Scheduled for elective care admission tomorrow (ICU-102)', '1 hr ago'),
      _Activity('discharge', 'Brad Pitt', 'Discharged from Bed GEN-302 (General Ward)', '2 hrs ago'),
      _Activity('emergency', 'Staff (ER Team)', 'Dispatched Nurse Sarah to ICU-101 for telemetry BP check', '4 hrs ago'),
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeroBanner(
            occupancy: occupancy,
            onAddAdmission: onAddAdmission,
            onAddTask: onAddTask,
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final cards = [
                KpiCard(
                  label: 'Bed Occupancy',
                  value: '$occupancy%',
                  sub: '$occupied of $total Beds occupied',
                  icon: Icons.meeting_room_rounded,
                  iconBg: AdminColors.emerald500.withOpacity(0.1),
                  iconColor: AppColors.emeraldDark,
                  trend: '+1.8% from yesterday',
                  trendUp: true,
                ),
                KpiCard(
                  label: 'Daily Ward Yield',
                  value: formatMoney(dailyBilling),
                  sub: 'Active inpatient care rates',
                  icon: Icons.credit_card_rounded,
                  iconBg: AdminColors.ambery.withOpacity(0.1),
                  iconColor: const Color(0xFF7C5A14),
                  trend: 'Adjusted for ICU charges',
                  trendUp: true,
                ),
                KpiCard(
                  label: 'Admitted Inpatients',
                  value: '$activeAdmissions',
                  sub: 'Receiving inpatient therapies',
                  icon: Icons.people_alt_rounded,
                  iconBg: AdminColors.blue50,
                  iconColor: AdminColors.blue,
                  trend: '3 discharges expected today',
                  trendUp: true,
                ),
                KpiCard(
                  label: 'Clinical Task Backlog',
                  value: '$pendingTasks Orders',
                  sub: 'Nursing, lab tests, pharmacy',
                  icon: Icons.assignment_rounded,
                  iconBg: AdminColors.rose50,
                  iconColor: AdminColors.rose,
                  trend: '1 emergency lab order',
                  trendUp: false,
                ),
              ];
              return Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  for (var i = 0; i < cards.length; i++)
                    SizedBox(
                      width: constraints.maxWidth >= 1100
                          ? (constraints.maxWidth - 60) / 4
                          : constraints.maxWidth >= 700
                              ? (constraints.maxWidth - 20) / 2
                              : constraints.maxWidth,
                      child: cards[i],
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 960;
              final chart = _WeeklyChart(
                  weeklyData: weeklyData,
                  onOpenAdmissions: () => onNavigate(AdminTab.admissions));
              final allocations = _BedAllocations(
                occupied: occupied,
                available: available,
                sanitizing: sanitizing,
                reserved: reserved,
                total: total,
                onManage: () => onNavigate(AdminTab.beds),
              );
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: chart),
                    const SizedBox(width: 24),
                    Expanded(child: allocations),
                  ],
                );
              }
              return Column(
                children: [chart, const SizedBox(height: 24), allocations],
              );
            },
          ),
          const SizedBox(height: 28),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 960;
              final feed = _ActivityFeed(activities: recentActivities);
              final orders = _PendingOrders(
                tasks: tasks,
                pendingCount: pendingTasks,
                onReview: () => onNavigate(AdminTab.tasks),
              );
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: feed),
                    const SizedBox(width: 24),
                    Expanded(child: orders),
                  ],
                );
              }
              return Column(
                children: [feed, const SizedBox(height: 24), orders],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Activity {
  const _Activity(this.type, this.patient, this.detail, this.time);
  final String type;
  final String patient;
  final String detail;
  final String time;
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.occupancy,
    required this.onAddAdmission,
    required this.onAddTask,
  });

  final int occupancy;
  final VoidCallback onAddAdmission;
  final VoidCallback onAddTask;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B2B26), Color(0xFF0D3831), Color(0xFF12463E)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x1A0B2B26), blurRadius: 24, offset: Offset(0, 6)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -60,
            top: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AdminColors.emerald500.withOpacity(0.12),
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              final titleCol = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AdminColors.emerald500.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AdminColors.emerald500.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite_rounded, size: 12, color: Color(0xFF34D399)),
                        SizedBox(width: 5),
                        Text('Clinic Status: Fully Operational',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF34D399))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Chief Officer Console',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5)),
                  const SizedBox(height: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Text(
                      'ICU telemetry links are active. Total bed occupancy is at $occupancy%. '
                      'Outpatient scheduling is operating at normal latency, and attending staff '
                      'directories are fully synchronized.',
                      style: const TextStyle(fontSize: 13, color: Color(0xB3FFFFFF), height: 1.5),
                    ),
                  ),
                ],
              );

              final buttons = Row(
                children: [
                  AdminButton(
                    label: 'Admit Patient',
                    icon: Icons.add_rounded,
                    onPressed: onAddAdmission,
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: onAddTask,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0x26FFFFFF)),
                      backgroundColor: const Color(0x1AFFFFFF),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.assignment_outlined, size: 16, color: Color(0xFF34D399)),
                    label: const Text('Order Lab/Rx',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ],
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: titleCol),
                    const SizedBox(width: 24),
                    buttons,
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titleCol,
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      AdminButton(
                        label: 'Admit Patient',
                        icon: Icons.add_rounded,
                        onPressed: onAddAdmission,
                      ),
                      OutlinedButton(
                        onPressed: onAddTask,
                        child: const Text('Order Lab/Rx'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.weeklyData, required this.onOpenAdmissions});

  final List<(String, int)> weeklyData;
  final VoidCallback onOpenAdmissions;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Weekly Patient Admissions',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                    SizedBox(height: 3),
                    Text('Total inpatient check-ins recorded daily',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              InkWell(
                onTap: onOpenAdmissions,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Text('Admissions Log',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AdminColors.emerald600)),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_outward_rounded, size: 14, color: AdminColors.emerald600),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weeklyData.map((d) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: FractionallySizedBox(
                            alignment: Alignment.bottomCenter,
                            heightFactor: d.$2 / 100,
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [AdminColors.emerald600, AdminColors.emerald500],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(d.$1,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AdminColors.bgSoft),
          const SizedBox(height: 12),
          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              const _LegendDot(color: AdminColors.emerald600, label: 'General/Pediatric Care'),
              const _LegendDot(color: Color(0xFFE8BA60), label: 'ICU / Critical Surges'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textBody)),
      ],
    );
  }
}

class _BedAllocations extends StatelessWidget {
  const _BedAllocations({
    required this.occupied,
    required this.available,
    required this.sanitizing,
    required this.reserved,
    required this.total,
    required this.onManage,
  });

  final int occupied;
  final int available;
  final int sanitizing;
  final int reserved;
  final int total;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    double pct(int n) => total == 0 ? 0 : (n / total * 100);
    final rows = [
      (AdminColors.emerald600, 'Beds Occupied', occupied, pct(occupied)),
      (const Color(0xFF60A5FA), 'Beds Available (Ready)', available, pct(available)),
      (const Color(0xFFFBBF24), 'Under Sanitization', sanitizing, pct(sanitizing)),
      (const Color(0xFFF43F5E), 'Out of Service / Reserved', reserved, pct(reserved)),
    ];

    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Real-time Bed Allocations',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          const SizedBox(height: 3),
          const Text('Attended ward beds and room sanitation logs',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  for (final r in rows)
                    Expanded(
                      flex: r.$4.round() == 0 ? 1 : r.$4.round(),
                      child: Container(color: r.$1, height: 12),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (final r in rows) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: r.$1, shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(r.$2,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textMid)),
                  ),
                  Text('${r.$3} (${r.$4.round()}%)',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          AdminGhostButton(
            label: 'Manage Ward Allocations',
            onPressed: onManage,
          ),
        ],
      ),
    );
  }
}

class _ActivityFeed extends StatelessWidget {
  const _ActivityFeed({required this.activities});

  final List<_Activity> activities;

  Color _colorFor(String type) => switch (type) {
        'admission' => AdminColors.teal,
        'discharge' => AdminColors.blue,
        'scheduled' => AdminColors.purple,
        'emergency' => AdminColors.rose,
        _ => AdminColors.ambery,
      };

  Color _bgFor(String type) => switch (type) {
        'admission' => AdminColors.teal50,
        'discharge' => AdminColors.blue50,
        'scheduled' => AdminColors.purple50,
        'emergency' => AdminColors.rose50,
        _ => AdminColors.amber50,
      };

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Live Clinical Activity Feed',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          const SizedBox(height: 3),
          const Text('Patient status logs, admissions, and telemetry triggers',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 14),
          for (var i = 0; i < activities.length; i++) ...[
            _ActivityRow(
              type: activities[i].type,
              color: _colorFor(activities[i].type),
              bg: _bgFor(activities[i].type),
              patient: activities[i].patient,
              detail: activities[i].detail,
              time: activities[i].time,
            ),
            if (i != activities.length - 1)
              const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.type,
    required this.color,
    required this.bg,
    required this.patient,
    required this.detail,
    required this.time,
  });

  final String type;
  final Color color;
  final Color bg;
  final String patient;
  final String detail;
  final String time;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
                child: Icon(Icons.bolt_rounded, size: 15, color: color),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Container(width: 2, color: AdminColors.border),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(style: const TextStyle(fontSize: 12, color: AppColors.textBody), children: [
                        TextSpan(text: patient, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark)),
                        TextSpan(text: '  $detail'),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(time,
                      style: const TextStyle(fontSize: 10.5, color: AppColors.textHint, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingOrders extends StatelessWidget {
  const _PendingOrders({
    required this.tasks,
    required this.pendingCount,
    required this.onReview,
  });

  final List<MedicalTask> tasks;
  final int pendingCount;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Pending Lab & Rx Orders',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              ),
              Pill(
                label: '$pendingCount Pending',
                bg: AdminColors.rose50,
                fg: AdminColors.rose,
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final task in tasks.take(3)) ...[
            _TaskTile(task: task),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 8),
          AdminGhostButton(
            label: 'Review Medical Orders',
            onPressed: onReview,
          ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task});

  final MedicalTask task;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminColors.bgSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bed ${task.bedId} · ${capitalize(task.type.name)}',
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AdminColors.emerald600, letterSpacing: 0.4)),
                const SizedBox(height: 3),
                Text(task.task,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                const SizedBox(height: 3),
                Text('Attendant: ${task.assignedTo}',
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _PriorityPill(priority: task.priority),
        ],
      ),
    );
  }
}

class _PriorityPill extends StatelessWidget {
  const _PriorityPill({required this.priority});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (priority) {
      TaskPriority.emergency => (AdminColors.rose50, AdminColors.rose),
      TaskPriority.high => (AdminColors.amber50, const Color(0xFFD97706)),
      TaskPriority.medium => (AdminColors.blue50, AdminColors.blue),
      TaskPriority.low => (AdminColors.bgSoft, AppColors.textMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withOpacity(0.25)),
      ),
      child: Text(capitalize(priority.name),
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: fg, letterSpacing: 0.3)),
    );
  }
}