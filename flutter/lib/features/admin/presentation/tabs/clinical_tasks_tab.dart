import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/admin_models.dart';
import '../../data/admin_repository.dart';
import '../admin_colors.dart';
import '../widgets/admin_common.dart';

const _nurses = [
  'Nurse Sarah Jenkins',
  'Nurse David Vance',
  'Nurse Maria Gomez',
  'Nurse John Doe',
  'Nurse Chloe Adams',
];

class ClinicalTasksTab extends StatefulWidget {
  const ClinicalTasksTab({
    super.key,
    required this.tasks,
    required this.onAdd,
    required this.onUpdate,
    this.openCreateSignal = 0,
  });

  final List<MedicalTask> tasks;
  final ValueChanged<MedicalTask> onAdd;
  final ValueChanged<MedicalTask> onUpdate;
  final int openCreateSignal;

  @override
  State<ClinicalTasksTab> createState() => _ClinicalTasksTabState();
}

class _ClinicalTasksTabState extends State<ClinicalTasksTab> {
  String _search = '';
  String _typeFilter = 'all';

  final _bedCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  TaskPriority _priority = TaskPriority.medium;
  TaskType _type = TaskType.nursing;
  String _assignee = 'Nurse Sarah Jenkins';

  @override
  void initState() {
    super.initState();
    if (widget.openCreateSignal > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openCreate());
    }
  }

  @override
  void dispose() {
    _bedCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  List<MedicalTask> get _filtered {
    return widget.tasks.where((t) {
      final q = _search.toLowerCase();
      final okSearch = q.isEmpty ||
          t.bedId.toLowerCase().contains(q) ||
          t.task.toLowerCase().contains(q) ||
          t.assignedTo.toLowerCase().contains(q);
      final okType = _typeFilter == 'all' || t.type.name == _typeFilter;
      return okSearch && okType;
    }).toList();
  }

  void _openCreate() {
    showAdminModal(context,
        title: 'Dispatch Care Request',
        subtitle: 'Create nursing orders, lab tests, or sanitization tasks',
        child: StatefulBuilder(
          builder: (context, setLocal) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ModalField(
                        label: 'Bed ID / Allocation',
                        field: TextField(
                          controller: _bedCtrl,
                          decoration: InputDecoration(hintText: 'e.g. ICU-101', border: modalFieldBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ModalField(
                        label: 'Clinical Category',
                        field: DropdownButtonFormField<String>(
                          value: _type.name,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 'nursing', child: Text('Nursing Orders')),
                            DropdownMenuItem(value: 'labTest', child: Text('Laboratory Test')),
                            DropdownMenuItem(value: 'pharmacy', child: Text('Pharmacy Delivery')),
                            DropdownMenuItem(value: 'sanitization', child: Text('Ward Sanitization')),
                          ],
                          onChanged: (v) => setLocal(() => _type = taskTypeFromApi(v ?? 'nursing')),
                          decoration: InputDecoration(border: modalFieldBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ModalField(
                  label: 'Order specifications / details',
                  field: TextField(
                    controller: _descCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'e.g. Administer 10ml Epinephrine and check telemetry BP levels…',
                      border: modalFieldBorder(),
                      hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.textHint),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ModalField(
                        label: 'Priority Level',
                        field: DropdownButtonFormField<String>(
                          value: _priority.name,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 'low', child: Text('Low Priority')),
                            DropdownMenuItem(value: 'medium', child: Text('Medium Priority')),
                            DropdownMenuItem(value: 'high', child: Text('High Priority')),
                            DropdownMenuItem(value: 'emergency', child: Text('EMERGENCY')),
                          ],
                          onChanged: (v) => setLocal(() => _priority = taskPriorityFromApi(v ?? 'medium')),
                          decoration: InputDecoration(border: modalFieldBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ModalField(
                        label: 'Assign Nurse Member',
                        field: DropdownButtonFormField<String>(
                          value: _assignee,
                          isExpanded: true,
                          items: _nurses.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                          onChanged: (v) => setLocal(() => _assignee = v ?? _assignee),
                          decoration: InputDecoration(border: modalFieldBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: AdminGhostButton(
                        label: 'Cancel',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AdminButton(
                        label: 'Dispatch Staff',
                        onPressed: () {
                          if (_bedCtrl.text.trim().isEmpty || _descCtrl.text.trim().isEmpty) {
                            showAdminToast(context, 'Bed ID and order details are required.');
                            return;
                          }
                          final now = TimeOfDay.fromDateTime(DateTime.now());
                          final task = MedicalTask(
                            id: 'TSK-${1000 + DateTime.now().millisecondsSinceEpoch % 9000}',
                            bedId: _bedCtrl.text.trim(),
                            task: _descCtrl.text.trim(),
                            priority: _priority,
                            assignedTo: _assignee,
                            status: TaskStatus.pending,
                            type: _type,
                            timestamp: '${now.hourOfPeriod}:${now.minute.toString().padLeft(2, '0')} ${now.period.name == 'am' ? 'AM' : 'PM'}',
                          );
                          widget.onAdd(task);
                          Navigator.of(context).pop();
                          showAdminToast(context, 'Order ${task.id} dispatched.');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ));
  }

  @override
  Widget build(BuildContext context) {
    final pending = widget.tasks.where((t) => t.status == TaskStatus.pending).length;
    final active = widget.tasks.where((t) => t.status == TaskStatus.inProgress).length;
    final completed = widget.tasks.where((t) => t.status == TaskStatus.completed).length;

    return ListView(
      padding: const EdgeInsets.all(2),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth >= 900 ? 3 : 1;
            final width = (constraints.maxWidth - (cols - 1) * 16) / cols;
            final cards = [
              KpiCard(
                label: 'Clinical backlog',
                value: '$pending pending',
                sub: 'Requires immediate attention',
                icon: Icons.schedule_rounded,
                iconBg: AdminColors.rose50,
                iconColor: AdminColors.rose,
              ),
              KpiCard(
                label: 'In Treatment Process',
                value: '$active in progress',
                sub: 'Attending nurses active',
                icon: Icons.person_rounded,
                iconBg: AdminColors.bgSubtle,
                iconColor: AdminColors.emerald600,
              ),
              KpiCard(
                label: 'Resolved Orders Today',
                value: '$completed complete',
                sub: 'High efficiency turnover',
                icon: Icons.check_circle_rounded,
                iconBg: AdminColors.emerald500.withOpacity(0.08),
                iconColor: AdminColors.emerald600,
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
          const AdminEmpty(message: 'No orders match your filter settings.')
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= 1300
                  ? 3
                  : constraints.maxWidth >= 760
                      ? 2
                      : 1;
              final width = (constraints.maxWidth - (cols - 1) * 20) / cols;
              return Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  for (final t in _filtered)
                    SizedBox(width: width, child: _TaskCard(task: t, onUpdate: widget.onUpdate)),
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
          final isWide = constraints.maxWidth >= 960;
          final search = AdminSearchField(
            hint: 'Search orders by Bed ID, Nurse, details…',
            value: _search,
            onChanged: (v) => setState(() => _search = v),
          );
          final actions = Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SegmentedFilter(
                options: ['all', 'nursing', 'labTest', 'pharmacy', 'sanitization'],
                selected: _typeFilter,
                onChanged: (v) => setState(() => _typeFilter = v),
              ),
              AdminButton(
                label: 'Dispatch Order',
                icon: Icons.add_rounded,
                onPressed: _openCreate,
              ),
            ],
          );
          if (isWide) {
            return Row(
              children: [
                SizedBox(width: 320, child: search),
                const Spacer(),
                actions,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [search, const SizedBox(height: 12), actions],
          );
        },
      ),
    );
  }
}

(IconData, Color) _taskTypeMeta(TaskType t) => switch (t) {
      TaskType.nursing => (Icons.monitor_heart_rounded, AdminColors.emerald600),
      TaskType.labTest => (Icons.description_rounded, AdminColors.blue),
      TaskType.pharmacy => (Icons.medical_services_rounded, AdminColors.purple),
      TaskType.sanitization => (Icons.build_rounded, const Color(0xFFD97706)),
    };

(Color, Color) _priorityColors(TaskPriority p) => switch (p) {
      TaskPriority.emergency => (AdminColors.rose100, AdminColors.rose),
      TaskPriority.high => (AdminColors.amber50, const Color(0xFFD97706)),
      TaskPriority.medium => (AdminColors.blue50, AdminColors.blue),
      TaskPriority.low => (AdminColors.bgSoft, AppColors.textMuted),
    };

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task, required this.onUpdate});

  final MedicalTask task;
  final ValueChanged<MedicalTask> onUpdate;

  @override
  Widget build(BuildContext context) {
    final (priBg, priFg) = _priorityColors(task.priority);
    final (typeIcon, typeColor) = _taskTypeMeta(task.type);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.border),
        boxShadow: const [BoxShadow(color: Color(0x0A0B2B26), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(task.id.toUpperCase(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppColors.textMuted)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: priBg, borderRadius: BorderRadius.circular(7), border: Border.all(color: priFg.withOpacity(0.3))),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (task.priority == TaskPriority.emergency) ...[
                      const Icon(Icons.warning_amber_rounded, size: 11, color: AdminColors.rose),
                      const SizedBox(width: 3),
                    ],
                    Text(capitalize(task.priority.name),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: priFg)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AdminColors.bgSubtle,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: AdminColors.borderLight),
                ),
                child: Icon(typeIcon, size: 17, color: typeColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bed ${task.bedId}',
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                    const SizedBox(height: 3),
                    Text(task.task,
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textBody, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AdminColors.bgSoft),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Attending Nurse',
                        style: TextStyle(fontSize: 9.5, color: AppColors.textMuted)),
                    const SizedBox(height: 3),
                    Text(task.assignedTo,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                  ],
                ),
              ),
              _statusAction(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusAction() {
    if (task.status == TaskStatus.pending) {
      return _solidBtn('Start Care', () => onUpdate(task.copyWith(status: TaskStatus.inProgress)));
    }
    if (task.status == TaskStatus.inProgress) {
      return _solidBtn('Resolve', () => onUpdate(task.copyWith(status: TaskStatus.completed)));
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AdminColors.emerald500.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AdminColors.emerald500.withOpacity(0.3)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 13, color: AdminColors.emerald600),
          SizedBox(width: 4),
          Text('Resolved',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AdminColors.emerald600)),
        ],
      ),
    );
  }

  Widget _solidBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AdminColors.emerald600,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white)),
      ),
    );
  }
}