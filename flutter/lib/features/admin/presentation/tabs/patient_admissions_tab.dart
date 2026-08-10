import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/admin_models.dart';
import '../../data/admin_repository.dart';
import '../admin_colors.dart';
import '../widgets/admin_common.dart';

const _wardRates = <String, int>{
  'General Ward': 150,
  'ICU': 850,
  'Emergency': 400,
  'Pediatrics': 200,
  'Maternity': 300,
};

class PatientAdmissionsTab extends StatefulWidget {
  const PatientAdmissionsTab({
    super.key,
    required this.admissions,
    required this.rooms,
    required this.onAdd,
    required this.onUpdate,
    this.openCreateSignal = 0,
  });

  final List<Admission> admissions;
  final List<Bed> rooms;
  final ValueChanged<Admission> onAdd;
  final ValueChanged<Admission> onUpdate;
  final int openCreateSignal;

  @override
  State<PatientAdmissionsTab> createState() => _PatientAdmissionsTabState();
}

class _PatientAdmissionsTabState extends State<PatientAdmissionsTab> {
  String _search = '';
  String _statusFilter = 'all';

  final _name = TextEditingController();
  final _age = TextEditingController(text: '30');
  String _gender = 'Male';
  String _wardType = 'General Ward';
  final _email = TextEditingController();
  final _phone = TextEditingController();
  String _admitDate = DateTime.now().toIso8601String().split('T').first;
  String _dischargeDate =
      DateTime.now().add(const Duration(days: 3)).toIso8601String().split('T').first;
  String _bedId = 'Pending';
  String _insurance = 'covered';

  @override
  void initState() {
    super.initState();
    if (widget.openCreateSignal > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openCreate());
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  List<Admission> get _filtered {
    return widget.admissions.where((a) {
      final q = _search.toLowerCase();
      final okSearch = q.isEmpty ||
          a.patientName.toLowerCase().contains(q) ||
          a.id.toLowerCase().contains(q) ||
          a.bedId.toLowerCase().contains(q);
      final okStatus = _statusFilter == 'all' || a.status.name == _statusFilter;
      return okSearch && okStatus;
    }).toList();
  }

  void _openCreate() {
    showAdminModal(context,
        title: 'Create Inpatient Admission',
        subtitle: 'Register new clinical intake and allocate ward space',
        child: StatefulBuilder(
          builder: (context, setLocal) {
            final estimated = _estimate();
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: ModalField(
                          label: 'Patient Full Name',
                          field: TextField(
                            controller: _name,
                            decoration: InputDecoration(hintText: 'e.g. John Miller', border: modalFieldBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ModalField(
                          label: 'Age',
                          field: TextField(
                            controller: _age,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(border: modalFieldBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ModalField(
                          label: 'Gender',
                          field: _select(['Male', 'Female', 'Other'], _gender, (v) => setLocal(() => _gender = v)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ModalField(
                          label: 'Ward Category',
                          field: _select(_wardRates.keys.toList(), _wardType, (v) => setLocal(() => _wardType = v), labeler: (w) => '$w (Rs. ${_wardRates[w]}/day)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ModalField(
                          label: 'Email Address',
                          field: TextField(
                            controller: _email,
                            decoration: InputDecoration(hintText: 'patient@mail.com', border: modalFieldBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ModalField(
                          label: 'Contact Number',
                          field: TextField(
                            controller: _phone,
                            decoration: InputDecoration(hintText: '+1 (555) 012-3456', border: modalFieldBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ModalField(
                          label: 'Admission Date',
                          field: TextField(
                            controller: TextEditingController(text: _admitDate),
                            onChanged: (v) => _admitDate = v,
                            decoration: InputDecoration(hintText: 'YYYY-MM-DD', border: modalFieldBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ModalField(
                          label: 'Expected Discharge',
                          field: TextField(
                            controller: TextEditingController(text: _dischargeDate),
                            onChanged: (v) => _dischargeDate = v,
                            decoration: InputDecoration(hintText: 'YYYY-MM-DD', border: modalFieldBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ModalField(
                          label: 'Bed Allocation',
                          field: DropdownButtonFormField<String>(
                            value: _bedId,
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem(value: 'Pending', child: Text('Keep Pending (Auto-assign on arrival)')),
                              for (final r in widget.rooms.where((r) => r.ward == _wardType && r.status == BedStatus.available))
                                DropdownMenuItem(value: r.id, child: Text('${r.id} (Floor ${r.floor} - Ready)')),
                            ],
                            onChanged: (v) => setLocal(() => _bedId = v ?? 'Pending'),
                            decoration: InputDecoration(border: modalFieldBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ModalField(
                          label: 'Insurance Status',
                          field: _select(['covered', 'pending', 'uninsured'], _insurance, (v) => setLocal(() => _insurance = v),
                              labeler: (v) => switch (v) {
                                    'covered' => 'Insured (Full Coverage)',
                                    'pending' => 'Pre-authorization Pending',
                                    _ => 'Uninsured (Self Pay)',
                                  }),
                        ),
                      ),
                    ],
                  ),
                  if (estimated != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AdminColors.emerald500.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AdminColors.emerald500.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Estimated Hospitalization Charges',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textStrong)),
                                const SizedBox(height: 2),
                                const Text('Standard daily ward calculations apply.',
                                    style: TextStyle(fontSize: 10, color: AppColors.emeraldDark)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(formatMoney(estimated.$1),
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textStrong)),
                              Text('estimated · ${estimated.$2} day(s) @ ${_wardRates[_wardType]}',
                                  style: const TextStyle(fontSize: 9.5, color: AppColors.emeraldDark)),
                            ],
                          ),
                        ],
                      ),
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
                          label: 'Confirm intake',
                          onPressed: _create,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ));
  }

  (int, int)? _estimate() {
    final start = DateTime.tryParse(_admitDate);
    final end = DateTime.tryParse(_dischargeDate);
    if (start == null || end == null) return null;
    final days = (end.difference(start).inDays).abs().clamp(1, 3650);
    final rate = _wardRates[_wardType] ?? 150;
    return (rate * days, days);
  }

  void _create() {
    if (_name.text.trim().isEmpty) {
      showAdminToast(context, 'Patient name is required.');
      return;
    }
    final rate = _wardRates[_wardType] ?? 150;
    final days = _estimate()?.$2 ?? 1;
    final adm = Admission(
      id: 'ADM-${1000 + DateTime.now().millisecondsSinceEpoch % 9000}',
      patientName: _name.text.trim(),
      patientAge: int.tryParse(_age.text) ?? 30,
      patientGender: _gender,
      wardType: _wardType,
      bedId: _bedId,
      admitDate: _admitDate,
      dischargeDate: _dischargeDate,
      billingAmount: rate * days,
      status: AdmissionStatus.admitted,
      insuranceStatus: insuranceStatusFromApi(_insurance),
      patientEmail: _email.text.trim().isEmpty
          ? '${_name.text.trim().toLowerCase().replaceAll(' ', '')}@hospital.com'
          : _email.text.trim(),
      patientPhone: _phone.text.trim().isEmpty ? '+1 (555) 000-0000' : _phone.text.trim(),
    );
    widget.onAdd(adm);
    Navigator.of(context).pop();
    showAdminToast(context, 'Admission ${adm.id} created.');
  }

  Widget _select(List<String> options, String value, ValueChanged<String> onChanged, {String Function(String)? labeler}) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      items: options.map((o) => DropdownMenuItem(value: o, child: Text(labeler != null ? labeler(o) : o))).toList(),
      onChanged: (v) => onChanged(v ?? value),
      decoration: InputDecoration(border: modalFieldBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(2),
      children: [
        _filterBar(),
        const SizedBox(height: 20),
        _AdmissionTable(admissions: _filtered, rooms: widget.rooms, onAction: _handleAction),
      ],
    );
  }

  void _handleAction(Admission adm, String action) {
    if (action == 'admit') {
      final available = widget.rooms
          .where((r) => r.ward == adm.wardType && r.status == BedStatus.available)
          .toList();
      final bedId = available.isNotEmpty ? available.first.id : 'GEN-302';
      widget.onUpdate(adm.copyWith(status: AdmissionStatus.admitted, bedId: bedId));
      showAdminToast(context, '${adm.patientName} admitted to $bedId.');
    } else if (action == 'discharge') {
      widget.onUpdate(adm.copyWith(status: AdmissionStatus.discharged));
      showAdminToast(context, '${adm.patientName} discharged.');
    } else {
      widget.onUpdate(adm.copyWith(status: AdmissionStatus.cancelled));
      showAdminToast(context, 'Admission ${adm.id} cancelled.');
    }
  }

  Widget _filterBar() {
    return AdminCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final search = AdminSearchField(
            hint: 'Search admissions by Patient, ADM ID…',
            value: _search,
            onChanged: (v) => setState(() => _search = v),
          );
          final actions = Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SegmentedFilter(
                options: ['all', 'admitted', 'scheduled', 'discharged', 'cancelled'],
                selected: _statusFilter,
                onChanged: (v) => setState(() => _statusFilter = v),
              ),
              AdminButton(
                label: 'Admit Patient',
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

(Color, Color) _admissionStatusColors(AdmissionStatus s) => switch (s) {
      AdmissionStatus.admitted => (AdminColors.emerald500.withOpacity(0.08), AdminColors.emerald700),
      AdmissionStatus.scheduled => (AdminColors.blue50, AdminColors.blue),
      AdmissionStatus.discharged => (const Color(0xFFF3F4F6), const Color(0xFF6B7280)),
      AdmissionStatus.cancelled => (AdminColors.rose50, AdminColors.rose),
    };

(Color, Color) _insuranceColors(InsuranceStatus s) => switch (s) {
      InsuranceStatus.covered => (AdminColors.emerald500.withOpacity(0.08), AdminColors.emerald600),
      InsuranceStatus.pending => (AdminColors.amber50, const Color(0xFFD97706)),
      InsuranceStatus.uninsured => (AdminColors.rose50, AdminColors.rose),
    };

class _AdmissionTable extends StatelessWidget {
  const _AdmissionTable({
    required this.admissions,
    required this.rooms,
    required this.onAction,
  });

  final List<Admission> admissions;
  final List<Bed> rooms;
  final void Function(Admission adm, String action) onAction;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 760;
          if (!isWide) {
            return Column(
              children: [
                for (var i = 0; i < admissions.length; i++) ...[
                  _AdmissionCard(adm: admissions[i], onAction: onAction),
                  if (i != admissions.length - 1)
                    const Divider(height: 1, color: AdminColors.border),
                ],
                if (admissions.isEmpty)
                  const AdminEmpty(message: 'No patient admission records match your query.'),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _headerRow(),
              for (final adm in admissions)
                _dataRow(adm),
              if (admissions.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: AdminEmpty(message: 'No patient admission records match your query.'),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _headerRow() {
    const children = [
      _Cell('Admission ID', flex: 1),
      _Cell('Patient Details', flex: 2),
      _Cell('Ward Category', flex: 1.2),
      _Cell('Bed #', flex: 0.9),
      _Cell('Hospitalization Dates', flex: 1.8),
      _Cell('Treatment Bill', flex: 1.4),
      _Cell('Status', flex: 1),
      _Cell('Actions', flex: 1.4, alignRight: true),
    ];
    return Container(
      color: AdminColors.bgSoft,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: children),
    );
  }

  Widget _dataRow(Admission adm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AdminColors.bgSoft))),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(adm.id,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AdminColors.emerald600)),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(adm.patientName,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text('${adm.patientAge} yrs · ${adm.patientGender} · ${adm.patientPhone}',
                    style: const TextStyle(fontSize: 10, color: AppColors.textBody)),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(adm.wardType,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMid)),
          ),
          Expanded(
            flex: 1,
            child: _bedChip(adm.bedId),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Text(adm.admitDate,
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(adm.dischargeDate,
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textDark)),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Text(formatMoney(adm.billingAmount),
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                const SizedBox(width: 6),
                _insurancePill(adm.insuranceStatus),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: _statusPill(adm.status),
          ),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (adm.status == AdmissionStatus.scheduled)
                  _actionButton('Admit Inpatient', solid: true, onTap: () => onAction(adm, 'admit')),
                if (adm.status == AdmissionStatus.admitted)
                  _actionButton('Discharge', solid: true, blue: true, onTap: () => onAction(adm, 'discharge')),
                if (adm.status != AdmissionStatus.cancelled && adm.status != AdmissionStatus.discharged)
                  _actionButton('Cancel', danger: true, onTap: () => onAction(adm, 'cancel')),
                if (adm.status == AdmissionStatus.cancelled || adm.status == AdmissionStatus.discharged)
                  const Text('Archived',
                      style: TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bedChip(String bedId) {
    final pending = bedId == 'Pending';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: pending ? AdminColors.amber50 : AdminColors.bgSubtle,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(bedId,
          style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: pending ? const Color(0xFF92400E) : AppColors.textStrong)),
    );
  }

  Widget _statusPill(AdmissionStatus status) {
    final (bg, fg) = _admissionStatusColors(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999), border: Border.all(color: fg.withOpacity(0.25))),
      child: Text(capitalize(status.name),
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: fg)),
    );
  }

  Widget _insurancePill(InsuranceStatus status) {
    final (bg, fg) = _insuranceColors(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6), border: Border.all(color: fg.withOpacity(0.3))),
      child: Text(status.name.toUpperCase(),
          style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  Widget _actionButton(String label,
      {bool solid = false, bool blue = false, bool danger = false, VoidCallback? onTap}) {
    final bg = solid ? (blue ? AdminColors.blue : AdminColors.emerald600) : AdminColors.rose.withOpacity(0.08);
    final fg = solid ? Colors.white : AdminColors.rose;
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: danger ? Border.all(color: AdminColors.rose.withOpacity(0.3)) : null,
          ),
          child: Text(label,
              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: fg)),
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.text, {this.flex = 1, this.alignRight = false});

  final String text;
  final double flex;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex.toInt(),
      child: Text(text,
          textAlign: alignRight ? TextAlign.right : TextAlign.left,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.7, color: AppColors.textMuted)),
    );
  }
}

class _AdmissionCard extends StatelessWidget {
  const _AdmissionCard({required this.adm, required this.onAction});

  final Admission adm;
  final void Function(Admission adm, String action) onAction;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _admissionStatusColors(adm.status);
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(adm.id,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AdminColors.emerald600)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
                child: Text(capitalize(adm.status.name),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: fg)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(adm.patientName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          const SizedBox(height: 2),
          Text('${adm.patientAge} yrs · ${adm.patientGender} · ${adm.patientPhone}',
              style: const TextStyle(fontSize: 10.5, color: AppColors.textBody)),
          const SizedBox(height: 8),
          Text('${adm.wardType} · Bed ${adm.bedId}  ·  ${adm.admitDate} → ${adm.dischargeDate}',
              style: const TextStyle(fontSize: 11, color: AppColors.textMid)),
          const SizedBox(height: 4),
          Text('Bill ${formatMoney(adm.billingAmount)}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textStrong)),
          const SizedBox(height: 8),
          Row(
            children: [
              if (adm.status == AdmissionStatus.scheduled)
                _miniBtn('Admit', onTap: () => onAction(adm, 'admit')),
              if (adm.status == AdmissionStatus.admitted)
                _miniBtn('Discharge', blue: true, onTap: () => onAction(adm, 'discharge')),
              if (adm.status != AdmissionStatus.cancelled && adm.status != AdmissionStatus.discharged)
                _miniBtn('Cancel', danger: true, onTap: () => onAction(adm, 'cancel')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniBtn(String label, {bool blue = false, bool danger = false, VoidCallback? onTap}) {
    final bg = blue ? AdminColors.blue : (danger ? AdminColors.rose.withOpacity(0.1) : AdminColors.emerald600);
    final fg = (blue || !danger) ? Colors.white : AdminColors.rose;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: danger ? Border.all(color: AdminColors.rose.withOpacity(0.35)) : null,
          ),
          child: Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: fg)),
        ),
      ),
    );
  }
}