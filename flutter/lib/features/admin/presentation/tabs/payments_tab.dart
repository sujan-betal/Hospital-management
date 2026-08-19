import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/admin_models.dart';
import '../../data/admin_repository.dart';
import '../admin_colors.dart';
import '../widgets/admin_common.dart';

class PaymentsTab extends StatefulWidget {
  const PaymentsTab({
    super.key,
    required this.settings,
    required this.onUpdateSettings,
  });

  final HospitalSettings settings;
  final Future<void> Function(Map<String, dynamic> payload) onUpdateSettings;

  @override
  State<PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends State<PaymentsTab> {
  RevenueOverview? _overview;
  List<AdminDoctor> _adminDoctors = const [];
  String? _loadError;
  bool _savingShare = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final overview = await AdminRepository.getRevenueOverview();
      if (mounted) setState(() => _overview = overview);
    } catch (e) {
      if (mounted) setState(() => _loadError = '$e');
    }
    try {
      final doctors = await AdminRepository.listAdminDoctors();
      if (mounted) setState(() => _adminDoctors = doctors);
    } catch (_) {}
  }

  Future<void> _saveShare(int pct) async {
    setState(() => _savingShare = true);
    try {
      await widget.onUpdateSettings({'doctor_share_percent': pct});
      showAdminToast(context, 'Doctor payout share updated to $pct%.');
    } catch (e) {
      showAdminToast(context, 'Failed to update share: $e');
    } finally {
      if (mounted) setState(() => _savingShare = false);
    }
  }

  Future<void> _openBankDetails(RevenueDoctor row) async {
    final adminDoctor =
        _adminDoctors.where((ad) => ad.userName == row.doctorName).firstOrNull;
    final userId = adminDoctor?.userId ?? row.doctorName;
    await showAdminModal(
      context,
      title: '${capitalize(row.doctorName)} — Bank Details',
      subtitle: 'Details used to wire the accumulated doctor payout share',
      child: _BankDetailsForm(
        doctorName: row.doctorName,
        userId: userId,
        upiId: adminDoctor?.upiId ?? '',
        onSubmit: (payload) async {
          await AdminRepository.updateDoctorBankDetails(userId, payload);
          await _load();
        },
      ),
    );
    showAdminToast(context, 'Bank details saved for ${capitalize(row.doctorName)}.');
  }

  KpiCard _kpi({
    required IconData icon,
    required String label,
    required String value,
    required String sub,
    required Color accent,
  }) =>
      KpiCard(
        icon: icon,
        label: label,
        value: value,
        sub: sub,
        iconColor: accent,
        iconBg: accent.withOpacity(0.12),
      );

  /// Responsive KPI grid: 4 columns on wide screens, 2 on medium, 1 on phones.
  Widget _kpiGrid(List<KpiCard> cards) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final cols = w >= 1100 ? 4 : (w >= 620 ? 2 : 1);
        const gap = 14.0;
        final cardWidth = (w - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final c in cards) SizedBox(width: cardWidth, child: c)],
        );
      },
    );
  }

  /// Icon + title + subtitle block used at the top of each section card,
  /// matching the web `Payments.tsx` section headers.
  Widget _cardHeader(
    IconData icon,
    String title,
    String subtitle, {
    Color accent = AdminColors.emerald500,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: accent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textBody,
                      height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_overview == null) {
      return Center(
        child: _loadError == null
            ? const CircularProgressIndicator(color: AdminColors.emerald500)
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off_rounded,
                      size: 34, color: AdminColors.rose),
                  const SizedBox(height: 10),
                  const Text('Unable to load revenue overview.',
                      style:
                          TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                  const SizedBox(height: 14),
                  AdminButton(
                    label: 'Retry',
                    icon: Icons.refresh_rounded,
                    onPressed: _load,
                  ),
                ],
              ),
      );
    }

    final o = _overview!;
    final s = o.summary;
    final pendingText = s.pending > 0
        ? '${formatMoney(s.pending)} pending payout'
        : 'All doctor shares disbursed';

    return ListView(
      padding: const EdgeInsets.all(2),
      children: [
        _kpiGrid([
          _kpi(
            icon: Icons.receipt_long_rounded,
            label: 'Total Collected',
            value: formatMoney(s.totalCollected),
            sub:
                '${s.paymentCount} confirmed payment${s.paymentCount == 1 ? '' : 's'}',
            accent: AdminColors.emerald500,
          ),
          _kpi(
            icon: Icons.savings_rounded,
            label: 'Admin Keeps',
            value: formatMoney(s.adminKeep),
            sub: '${100 - s.doctorSharePercent}% of collected fees',
            accent: AdminColors.amber,
          ),
          _kpi(
            icon: Icons.medical_services_rounded,
            label: 'Doctors Earn',
            value: formatMoney(s.doctorShare),
            sub: '${s.doctorSharePercent}% of collected fees',
            accent: AdminColors.violet,
          ),
          _kpi(
            icon: Icons.check_circle_rounded,
            label: 'Paid Out',
            value: formatMoney(s.paidOut),
            sub: pendingText,
            accent: AdminColors.blue,
          ),
        ]),
        const SizedBox(height: 18),
        _SplitCard(
          currentPercent: o.settings.doctorSharePercent,
          saving: _savingShare,
          onSave: _saveShare,
        ),
        const SizedBox(height: 18),
        _revenueCard(o),
        const SizedBox(height: 18),
        _historyCard(o),
      ],
    );
  }

  // ─────────────────── Per-doctor revenue breakup ───────────────────

  Widget _revenueCard(RevenueOverview o) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cardHeader(
            Icons.medical_services_rounded,
            'Payout by Doctor',
            'Consultation payments, admin/service deductions and the accumulated '
            'payout share per attending doctor.',
          ),
          const SizedBox(height: 14),
          if (o.doctors.isEmpty)
            _emptyBox(
                'No paid consultations yet — payments appear here once patients pay.')
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                columnWidths: const {
                  0: IntrinsicColumnWidth(),
                  1: IntrinsicColumnWidth(),
                  2: IntrinsicColumnWidth(),
                  3: IntrinsicColumnWidth(),
                  4: IntrinsicColumnWidth(),
                  5: IntrinsicColumnWidth(),
                  6: IntrinsicColumnWidth(),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: AdminColors.bgSoft),
                    children: _headerCells(
                        ['Doctor', 'Payments', 'Collected', 'Admin Keeps', 'Doctor Earns', 'Paid Out', 'Pending']),
                  ),
                  for (final d in o.doctors) _revenueRow(d),
                ],
              ),
            ),
        ],
      ),
    );
  }

  TableRow _revenueRow(RevenueDoctor d) {
    final adminDoctor =
        _adminDoctors.where((ad) => ad.userName == d.doctorName).firstOrNull;
    final hasBank = adminDoctor?.hasBankDetails ?? false;
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: AdminColors.emerald500.withOpacity(0.12),
                child: Text(
                  d.doctorName.isEmpty ? '?' : d.doctorName[0].toUpperCase(),
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AdminColors.emerald600),
                ),
              ),
              const SizedBox(width: 9),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.doctorName,
                      style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: () => _openBankDetails(d),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasBank
                              ? Icons.check_circle_rounded
                              : Icons.account_balance_wallet_rounded,
                          size: 12,
                          color:
                              hasBank ? AdminColors.emerald500 : AdminColors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hasBank ? 'Bank linked' : 'Add bank',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: hasBank
                                  ? AdminColors.emerald600
                                  : AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: _bulkCell('${d.payments}'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: _moneyCell(formatMoney(d.collected)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: _moneyCell(formatMoney(d.adminKeep)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: _moneyCell(formatMoney(d.doctorShare),
              strong: true, color: AdminColors.emerald700),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: _moneyCell(formatMoney(d.paidOut)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: d.pending > 0
              ? _pendingPill(formatMoney(d.pending))
              : const Text('—',
                  style: TextStyle(fontSize: 11, color: AppColors.textHint)),
        ),
      ],
    );
  }

  // ─────────────────── Recent paid consultations ───────────────────

  Widget _historyCard(RevenueOverview o) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cardHeader(
            Icons.receipt_long_rounded,
            'Recent Paid Consultations',
            'Latest visit fees with the admin / doctor split snapshot at '
            'payment time.',
          ),
          const SizedBox(height: 14),
          if (o.payments.isEmpty)
            _emptyBox('No payment transactions recorded yet.')
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                columnWidths: const {
                  0: IntrinsicColumnWidth(),
                  1: IntrinsicColumnWidth(),
                  2: IntrinsicColumnWidth(),
                  3: IntrinsicColumnWidth(),
                  4: IntrinsicColumnWidth(),
                  5: IntrinsicColumnWidth(),
                  6: IntrinsicColumnWidth(),
                  7: IntrinsicColumnWidth(),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: AdminColors.bgSoft),
                    children: _headerCells(
                        ['Appointment', 'Patient', 'Doctor', 'Fee', 'Split', 'Admin', 'Doctor', 'Payout']),
                  ),
                  for (final p in o.payments) _historyRow(p),
                ],
              ),
            ),
        ],
      ),
    );
  }

  TableRow _historyRow(RevenuePayment p) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            p.appointmentId.length > 10
                ? p.appointmentId.substring(0, 10).toUpperCase()
                : p.appointmentId.toUpperCase(),
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AdminColors.emerald600),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(p.patientName,
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(p.doctorName,
              style: const TextStyle(fontSize: 11.5, color: AppColors.textBody)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: _moneyCell(formatMoney(p.fee)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text('${p.doctorSharePercent}%',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMid)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: _moneyCell(formatMoney(p.adminShare)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: _moneyCell(formatMoney(p.doctorShare),
              strong: true, color: AdminColors.emerald700),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: _payoutChip(p),
        ),
      ],
    );
  }

  // ─────────────────── Shared table helpers ───────────────────

  List<Widget> _headerCells(List<String> labels) => [
        for (final l in labels)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Text(l,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMuted,
                    letterSpacing: 0.4)),
          ),
      ];

  Widget _bulkCell(String text) => Text(text,
      style: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark));

  Widget _moneyCell(String text, {bool strong = false, Color? color}) => Text(
        text,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: 12,
          fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
          color: color ?? AppColors.textDark,
        ),
      );

  Widget _payoutChip(RevenuePayment p) {
    final status = p.payoutStatus.toUpperCase();
    final paid = status.contains('PAID');
    final failed = status.contains('FAIL');
    final (bg, fg, label, icon) = paid
        ? (AdminColors.emerald500.withOpacity(0.11),
            AdminColors.emerald600, 'PAID', Icons.check_circle_rounded)
        : failed
            ? (AdminColors.rose50, AdminColors.rose, 'FAILED',
                Icons.cancel_rounded)
            : (AdminColors.amber.withOpacity(0.12), AdminColors.darkAmber,
                'PENDING', Icons.schedule_rounded);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: fg,
              )),
        ],
      ),
    );
  }

  Widget _pendingPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AdminColors.amber.withOpacity(0.12),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: AdminColors.darkAmber)),
    );
  }

  Widget _emptyBox(String message) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 26),
        child: Center(
          child: Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textHint)),
        ),
      );
}

/// Dynamic revenue split configuration — doctor share %, auto-computed admin
/// keep %, slider and a live ₹150 example. Mirrors the web `Payments.tsx`
/// "Dynamic Revenue Split" form.
class _SplitCard extends StatefulWidget {
  const _SplitCard({
    required this.currentPercent,
    required this.saving,
    required this.onSave,
  });

  final int currentPercent;
  final bool saving;
  final ValueChanged<int> onSave;

  @override
  State<_SplitCard> createState() => _SplitCardState();
}

class _SplitCardState extends State<_SplitCard> {
  late final TextEditingController _ctrl;
  late int _doctorShare;

  @override
  void initState() {
    super.initState();
    _doctorShare = widget.currentPercent;
    _ctrl = TextEditingController(text: '$_doctorShare');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _setDoctorShare(int v) {
    setState(() {
      _doctorShare = v.clamp(0, 100);
      _ctrl.text = '$_doctorShare';
    });
  }

  void _onDoctorTextChanged(String v) {
    final parsed = int.tryParse(v);
    setState(() => _doctorShare = (parsed ?? 0).clamp(0, 100));
  }

  Widget _splitLabel(String text) => Text(text,
      style: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMid));

  Widget _splitField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _splitLabel(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          onChanged: onChanged,
          decoration: InputDecoration(
            border: modalFieldBorder(),
            suffix: const Text('%',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _readOnlySplitField({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _splitLabel(label),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AdminColors.bgSubtle,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AdminColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(value,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark)),
              ),
              const Text('%',
                  style:
                      TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final doctorShare = _doctorShare;
    final adminKeep = 100 - doctorShare;
    final doctorCut = (150 * doctorShare / 100).round();
    final adminCut = 150 - doctorCut;

    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AdminColors.violet.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.percent_rounded,
                    size: 17, color: AdminColors.violet),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dynamic Revenue Split',
                        style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark)),
                    SizedBox(height: 2),
                    Text(
                        'Patient payments land in the hospital account. Set the '
                        "doctor's share and the hospital keeps the rest.",
                        style: TextStyle(
                            fontSize: 10.5,
                            color: AppColors.textBody,
                            height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 780;
              final doctorField = _splitField(
                label: 'Doctor Share (%)',
                controller: _ctrl,
                onChanged: _onDoctorTextChanged,
              );
              final adminField =
                  _readOnlySplitField(label: 'Admin Keeps (%)', value: '$adminKeep');
              final slider = Slider(
                value: doctorShare.toDouble(),
                min: 0,
                max: 100,
                divisions: 20,
                activeColor: AdminColors.emerald600,
                onChanged: widget.saving
                    ? null
                    : (v) => _setDoctorShare(v.round()),
              );
              final saveButton = AdminButton(
                label: widget.saving ? 'Saving…' : 'Save Split',
                icon: Icons.check_rounded,
                onPressed: widget.saving
                    ? null
                    : () => widget.onSave(doctorShare),
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: doctorField),
                    const SizedBox(width: 12),
                    Expanded(child: adminField),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          slider,
                          const SizedBox(height: 4),
                          saveButton,
                        ],
                      ),
                    ),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  doctorField,
                  const SizedBox(height: 12),
                  adminField,
                  const SizedBox(height: 4),
                  slider,
                  const SizedBox(height: 8),
                  saveButton,
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AdminColors.bgSubtle,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AdminColors.borderLight),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.currency_rupee_rounded,
                    size: 16, color: AdminColors.emerald600),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Example: a ₹150 consultation pays the doctor ₹$doctorCut and '
                    'keeps ₹$adminCut for the hospital. The split is snapshotted '
                    'on each payment, so changing it later only affects new payments.',
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                      color: AdminColors.emerald700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BankDetailsForm extends StatefulWidget {
  const _BankDetailsForm({
    required this.doctorName,
    required this.userId,
    required this.upiId,
    required this.onSubmit,
  });

  final String doctorName;
  final String userId;
  final String upiId;

  /// Performs the PUT call; parent re-fetches after completion.
  final Future<void> Function(Map<String, dynamic> payload) onSubmit;

  @override
  State<_BankDetailsForm> createState() => _BankDetailsFormState();
}

class _BankDetailsFormState extends State<_BankDetailsForm> {
  final _name = TextEditingController();
  final _accountNumber = TextEditingController();
  final _ifsc = TextEditingController();
  final _bankName = TextEditingController();
  late final TextEditingController _upi;

  @override
  void initState() {
    super.initState();
    _upi = TextEditingController(text: widget.upiId);
  }

  @override
  void dispose() {
    _name.dispose();
    _accountNumber.dispose();
    _ifsc.dispose();
    _bankName.dispose();
    _upi.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    try {
      await widget.onSubmit({
        'has_bank_details': true,
        'account_holder': _name.text.trim(),
        'account_number': _accountNumber.text.trim(),
        'ifsc': _ifsc.text.trim().toUpperCase(),
        'bank_name': _bankName.text.trim(),
        'upi_id': _upi.text.trim().isEmpty ? null : _upi.text.trim(),
      });
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showAdminToast(context, 'Failed to save bank details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ModalField(
          label: 'Account Holder Name',
          field: TextField(
            controller: _name,
            decoration: InputDecoration(
                border: modalFieldBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 11)),
          ),
        ),
        const SizedBox(height: 12),
        ModalField(
          label: 'Account Number',
          field: TextField(
            controller: _accountNumber,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
                border: modalFieldBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 11)),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ModalField(
                label: 'IFSC Code',
                field: TextField(
                  controller: _ifsc,
                  decoration: InputDecoration(
                      border: modalFieldBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 13, vertical: 11)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ModalField(
                label: 'Bank Name',
                field: TextField(
                  controller: _bankName,
                  decoration: InputDecoration(
                      border: modalFieldBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 13, vertical: 11)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ModalField(
          label: 'UPI ID (optional)',
          field: TextField(
            controller: _upi,
            decoration: InputDecoration(
                border: modalFieldBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 11)),
          ),
        ),
        const SizedBox(height: 18),
        AdminButton(
          label: 'Save Bank Details',
          icon: Icons.check_rounded,
          expanded: true,
          onPressed: _submit,
        ),
      ],
    );
  }
}