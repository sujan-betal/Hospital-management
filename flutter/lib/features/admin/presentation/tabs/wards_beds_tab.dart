import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/admin_models.dart';
import '../admin_colors.dart';
import '../widgets/admin_common.dart';

const _commonWards = ['ICU', 'Emergency', 'General Ward', 'Pediatrics', 'Maternity'];
const _nursesList = [
  'Nurse Sarah Jenkins',
  'Nurse David Vance',
  'Nurse Maria Gomez',
  'Nurse John Doe',
  'Nurse Chloe Adams',
];

class WardsAndBedsTab extends StatefulWidget {
  const WardsAndBedsTab({
    super.key,
    required this.beds,
    required this.loading,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
  });

  final List<Bed> beds;
  final bool loading;
  final Future<bool> Function(Bed bed) onAdd;
  final Future<void> Function(Bed bed) onUpdate;
  final Future<bool> Function(String bedId) onDelete;

  @override
  State<WardsAndBedsTab> createState() => _WardsAndBedsTabState();
}

class _WardsAndBedsTabState extends State<WardsAndBedsTab> {
  String _statusFilter = 'all';
  String _wardFilter = 'all';
  String _search = '';

  Bed? _editing;
  int _editPrice = 0;
  BedStatus _editStatus = BedStatus.available;
  String _editNurse = '';

  bool _submitting = false;
  final _newId = TextEditingController();
  final _newWard = TextEditingController(text: 'General Ward');
  int _newFloor = 1;
  int _newPrice = 150;
  String _newNurse = 'Nurse Sarah Jenkins';
  String _newEquipment = '';
  BedStatus _newStatus = BedStatus.available;

  @override
  void dispose() {
    _newId.dispose();
    _newWard.dispose();
    super.dispose();
  }

  List<String> get _knownWards {
    final set = <String>{..._commonWards};
    for (final b in widget.beds) {
      set.add(b.ward);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<Bed> get _filtered {
    return widget.beds.where((b) {
      final okStatus =
          _statusFilter == 'all' || b.status.name == _statusFilter;
      final okWard = _wardFilter == 'all' || b.ward == _wardFilter;
      final q = _search.toLowerCase();
      final okSearch = q.isEmpty ||
          b.id.toLowerCase().contains(q) ||
          (b.patient?.toLowerCase().contains(q) ?? false) ||
          b.assignedNurse.toLowerCase().contains(q);
      return okStatus && okWard && okSearch;
    }).toList();
  }

  void _openEdit(Bed bed) {
    _editing = bed;
    _editPrice = bed.price;
    _editStatus = bed.status;
    _editNurse = bed.assignedNurse;
    _showEditModal();
  }

  Future<bool> _saveEdit() async {
    if (_editing == null) return false;
    final updated = _editing!.copyWith(
      price: _editPrice,
      status: _editStatus,
      assignedNurse: _editNurse,
      patient: _editStatus != BedStatus.occupied ? null : _editing!.patient,
    );
    await widget.onUpdate(updated);
    showAdminToast(context, '${updated.ward} bed ${updated.id} saved.');
    return true;
  }

  Future<bool> _submitAdd() async {
    if (_newId.text.trim().isEmpty || _newWard.text.trim().isEmpty) return false;
    setState(() => _submitting = true);
    final ok = await widget.onAdd(Bed(
      id: _newId.text.trim().toUpperCase(),
      ward: _newWard.text.trim(),
      status: _newStatus,
      price: _newPrice,
      floor: _newFloor,
      assignedNurse: _newNurse,
      equipment: _newEquipment
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      patient: _newStatus == BedStatus.occupied ? 'Pending' : null,
    ));
    if (mounted) {
      setState(() {
        _submitting = false;
        if (ok) {
          _newId.clear();
          _newWard.text = 'General Ward';
          _newFloor = 1;
          _newPrice = 150;
          _newNurse = 'Nurse Sarah Jenkins';
          _newEquipment = '';
          _newStatus = BedStatus.available;
        }
      });
    }
    return ok;
  }

  Future<void> _delete(String id) async {
    final ok = await showAdminConfirm(context,
        title: 'Delete bed $id?',
        message: 'Deleting this bed cannot be undone.');
    if (ok) await widget.onDelete(id);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.all(2),
        children: [
          _filterBar(),
          const SizedBox(height: 20),
          if (widget.loading)
            const AdminLoader(message: 'Loading beds…')
          else if (_filtered.isEmpty)
            const AdminEmpty(
                message:
                    'No beds match your filter settings.\nTry adjusting your parameters.')
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final cols = constraints.maxWidth >= 1500
                    ? 4
                    : constraints.maxWidth >= 1080
                        ? 3
                        : constraints.maxWidth >= 700
                            ? 2
                            : 1;
                final width =
                    (constraints.maxWidth - (cols - 1) * 20) / cols;
                return Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: [
                    for (final bed in _filtered)
                      SizedBox(width: width, child: _BedCard(bed: bed, onEdit: () => _openEdit(bed), onDelete: () => _delete(bed.id))),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _filterBar() {
    return AdminCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final left = AdminSearchField(
            hint: 'Search by Bed ID, Patient, Nurse…',
            value: _search,
            onChanged: (v) => setState(() => _search = v),
          );
          final right = Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AdminButton(
                label: 'Add Bed',
                icon: Icons.add_rounded,
                onPressed: _showAddModal,
              ),
              SegmentedFilter(
                options: ['all', 'available', 'occupied', 'sanitizing', 'reserved'],
                selected: _statusFilter,
                onChanged: (v) => setState(() => _statusFilter = v),
              ),
              _wardDropdown(),
            ],
          );
          if (isWide) {
            return Row(
              children: [
                SizedBox(width: 320, child: left),
                const Spacer(),
                right,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              left,
              const SizedBox(height: 12),
              right,
            ],
          );
        },
      ),
    );
  }

  Widget _wardDropdown() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AdminColors.bgSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminColors.borderLight),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _wardFilter,
          isDense: true,
          borderRadius: BorderRadius.circular(10),
          dropdownColor: Colors.white,
          icon: const Icon(Icons.filter_list_rounded, size: 18, color: AppColors.textMuted),
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textDark),
          items: [
            const DropdownMenuItem(value: 'all', child: Text('All Wards')),
            for (final w in _knownWards) DropdownMenuItem(value: w, child: Text(w)),
          ],
          onChanged: (v) => setState(() => _wardFilter = v ?? 'all'),
        ),
      ),
    );
  }

  void _showEditModal() {
    if (_editing == null) return;
    final bed = _editing!;
    showAdminModal(context,
        title: 'Update Bed ${bed.id}',
        subtitle: '${bed.ward} Ward',
        child: StatefulBuilder(
          builder: (context, setLocal) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ModalField(
                  label: 'Bed Occupancy Status',
                  field: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 3.2,
                    children: BedStatus.values.map((s) {
                      final isSel = s == _editStatus;
                      final (icon, label) = _statusMeta(s);
                      return GestureDetector(
                        onTap: () => setLocal(() => _editStatus = s),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSel ? AdminColors.emerald500.withOpacity(0.08) : Colors.white,
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(
                              color: isSel ? AdminColors.emerald600 : AdminColors.borderLight,
                              width: isSel ? 1.6 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(icon, size: 14, color: isSel ? AdminColors.emerald600 : AppColors.textMuted),
                              const SizedBox(width: 5),
                              Text(capitalize(label),
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                      color: isSel ? AdminColors.emerald700 : AppColors.textBody)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                ModalField(
                  label: 'Daily Charge (Rs.)',
                  field: TextField(
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: '$_editPrice'),
                    onChanged: (v) => _editPrice = int.tryParse(v) ?? 0,
                    decoration: InputDecoration(
                      border: modalFieldBorder(),
                      focusedBorder: modalFieldBorder(),
                      prefixIcon: const Icon(Icons.credit_card_rounded, size: 18, color: AppColors.textMuted),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ModalField(
                  label: 'Assigned Nurse',
                  field: DropdownButtonFormField<String>(
                    value: _editNurse,
                    isExpanded: true,
                    items: _nursesList.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                    onChanged: (v) => setLocal(() => _editNurse = v ?? ''),
                    decoration: InputDecoration(border: modalFieldBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                  ),
                ),
                if (bed.status == BedStatus.occupied && bed.patient != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AdminColors.emerald500.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AdminColors.emerald500.withOpacity(0.25)),
                    ),
                    child: Text('Attended Inpatient\n${bed.patient} (Under clinical observations)',
                        style: const TextStyle(fontSize: 12, color: AppColors.textStrong, fontWeight: FontWeight.w600)),
                  ),
                ],
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
                        label: 'Save Changes',
                        onPressed: () async {
                          final ok = await _saveEdit();
                          if (ok) Navigator.of(context).pop();
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

  void _showAddModal() {
    showAdminModal(context,
        title: 'Add New Bed',
        subtitle: 'Register a bed and assign it to a ward',
        child: StatefulBuilder(
          builder: (context, setLocal) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ModalField(
                  label: 'Bed ID',
                  field: TextField(
                    controller: _newId,
                    decoration: InputDecoration(hintText: 'e.g. ICU-103', border: modalFieldBorder(), hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.textHint), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                  ),
                ),
                const SizedBox(height: 14),
                ModalField(
                  label: 'Ward',
                  field: TextField(
                    controller: _newWard,
                    decoration: InputDecoration(hintText: 'Select or type a new ward name', border: modalFieldBorder(), hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.textHint), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                  ),
                  hint: 'Pick an existing ward or type a new one to create it.',
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ModalField(
                        label: 'Floor',
                        field: TextField(
                          controller: TextEditingController(text: '$_newFloor'),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => _newFloor = int.tryParse(v) ?? 1,
                          decoration: InputDecoration(border: modalFieldBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ModalField(
                        label: 'Daily Charge (Rs.)',
                        field: TextField(
                          controller: TextEditingController(text: '$_newPrice'),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => _newPrice = int.tryParse(v) ?? 0,
                          decoration: InputDecoration(border: modalFieldBorder(), prefixIcon: const Icon(Icons.credit_card_rounded, size: 16, color: AppColors.textMuted), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ModalField(
                  label: 'Bed Occupancy Status',
                  field: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 3.2,
                    children: BedStatus.values.map((s) {
                      final isSel = s == _newStatus;
                      final (icon, label) = _statusMeta(s);
                      return GestureDetector(
                        onTap: () => setLocal(() => _newStatus = s),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSel ? AdminColors.emerald500.withOpacity(0.08) : Colors.white,
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(
                              color: isSel ? AdminColors.emerald600 : AdminColors.borderLight,
                              width: isSel ? 1.6 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(icon, size: 14, color: isSel ? AdminColors.emerald600 : AppColors.textMuted),
                              const SizedBox(width: 5),
                              Text(capitalize(label),
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                      color: isSel ? AdminColors.emerald700 : AppColors.textBody)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),
                ModalField(
                  label: 'Assigned Nurse',
                  field: DropdownButtonFormField<String>(
                    value: _newNurse,
                    isDense: true,
                    items: _nursesList.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                    onChanged: (v) => setLocal(() => _newNurse = v ?? _newNurse),
                    decoration: InputDecoration(border: modalFieldBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                  ),
                ),
                const SizedBox(height: 14),
                ModalField(
                  label: 'Equipment (comma separated)',
                  field: TextField(
                    onChanged: (v) => _newEquipment = v,
                    decoration: InputDecoration(hintText: 'Ventilator, Cardiac Monitor', border: modalFieldBorder(), hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.textHint), prefixIcon: const Icon(Icons.build_circle_outlined, size: 16, color: AppColors.textMuted), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                  ),
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
                        label: _submitting ? 'Adding…' : 'Add Bed',
                        onPressed: _submitting ? null : () async {
                          final ok = await _submitAdd();
                          if (ok) Navigator.of(context).pop();
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

  (IconData, String) _statusMeta(BedStatus s) => switch (s) {
        BedStatus.available => (Icons.check_circle_rounded, 'available'),
        BedStatus.occupied => (Icons.person_rounded, 'occupied'),
        BedStatus.sanitizing => (Icons.cleaning_services_rounded, 'sanitizing'),
        BedStatus.reserved => (Icons.shield_outlined, 'reserved'),
      };
}

class _BedCard extends StatelessWidget {
  const _BedCard({required this.bed, required this.onEdit, required this.onDelete});

  final Bed bed;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  (Color, Color) get _statusColors => switch (bed.status) {
        BedStatus.available => (AdminColors.blue50, AdminColors.blue),
        BedStatus.occupied => (AdminColors.emerald500.withOpacity(0.07), AdminColors.emerald700),
        BedStatus.sanitizing => (AdminColors.amber50, const Color(0xFFD97706)),
        BedStatus.reserved => (AdminColors.rose50, AdminColors.rose),
      };

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _statusColors;
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
                    Text('FLOOR ${bed.floor}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: AppColors.textMuted)),
                    const SizedBox(height: 3),
                    Text(bed.id,
                        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.textDark)),
                  ],
                ),
              ),
              Pill(
                label: bed.status.name,
                bg: bg,
                fg: fg,
                icon: _statusIcon,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('${bed.ward} Ward',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textMid)),
          const SizedBox(height: 10),
          if (bed.status == BedStatus.occupied && bed.patient != null)
            _MiniChip(
              icon: Icons.person_rounded,
              color: AdminColors.emerald600,
              text: 'Patient: ${bed.patient}',
            ),
          if (bed.status == BedStatus.sanitizing)
            _MiniChip(
              icon: Icons.cleaning_services_rounded,
              color: const Color(0xFFD97706),
              text: 'Cleaner: ${bed.assignedNurse}',
            ),
          const SizedBox(height: 12),
          Text('EQUIPMENT',
              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: AppColors.textMuted)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final eq in bed.equipment)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AdminColors.bgSubtle,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(eq,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textBody)),
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
                    const Text('Daily Rate',
                        style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    Text(formatMoney(bed.price),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textStrong)),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
                tooltip: 'Delete bed',
                style: IconButton.styleFrom(
                  backgroundColor: AdminColors.rose50,
                  foregroundColor: AdminColors.rose,
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 17),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onEdit,
                visualDensity: VisualDensity.compact,
                tooltip: 'Edit bed',
                style: IconButton.styleFrom(
                  backgroundColor: AdminColors.bgSubtle,
                  foregroundColor: AppColors.textStrong,
                ),
                icon: const Icon(Icons.edit_rounded, size: 17),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData get _statusIcon => switch (bed.status) {
        BedStatus.available => Icons.check_circle_rounded,
        BedStatus.occupied => Icons.person_rounded,
        BedStatus.sanitizing => Icons.cleaning_services_rounded,
        BedStatus.reserved => Icons.shield_outlined,
      };
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 7),
          Expanded(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AdminColors.emerald700)),
          ),
        ],
      ),
    );
  }
}