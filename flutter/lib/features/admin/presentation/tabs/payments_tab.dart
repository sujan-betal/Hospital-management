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
    required Color accent,
  }) =>
      KpiCard(
        icon: icon,
        label: label,
        value: value,
        sub: 'last 30 days',
        iconColor: accent,
        iconBg: accent.withOpacity(0.12),
      );

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
    final wired = o.doctors.fold<int>(0, (a, d) => a + d.paidOut);

    return ListView(
      padding: const EdgeInsets.all(2),
      children: [
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _kpi(
              icon: Icons.receipt_long_rounded,
              label: 'Payment Count',
              value: '${s.paymentCount}',
              accent: AdminColors.emerald500,
            ),
            _kpi(
              icon: Icons.payments_rounded,
              label: 'Total Collected',
              value: formatMoney(s.totalCollected),
              accent: AdminColors.blue,
            ),
            _kpi(
              icon: Icons.savings_rounded,
              label: 'Admin Keep',
              value: formatMoney(s.adminKeep),
              accent: AdminColors.amber,
            ),
            _kpi(
              icon: Icons.share_rounded,
              label: 'Doctor Share',
              value: '${s.doctorSharePercent}%',
              accent: AdminColors.violet,
            ),
            _kpi(
              icon: Icons.hourglass_bottom_rounded,
              label: 'Paid Out',
              value: formatMoney(s.paidOut),
              accent: AdminColors.blue,
            ),
            _kpi(
              icon: Icons.access_time_rounded,
              label: 'Pending',
              value: formatMoney(s.pending),
              accent: AdminColors.rose,
            ),
            _kpi(
              icon: Icons.currency_rupee_rounded,
              label: 'Payouts Wired',
              value: formatMoney(wired),
              accent: AdminColors.teal,
            ),
          ],
        ),
        const SizedBox(height: 18),
        _ShareCard(
          currentPercent: o.settings.doctorSharePercent,
          saving: _savingShare,
          onSave: _saveShare,
        ),
        const SizedBox(height: 18),
        AdminCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Per-Doctor Revenue Breakup',
                  style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark)),
              const SizedBox(height: 4),
              const Text(
                  'Real-time consultation payments, admin/service deductions, doctor payout accumulation.',
                  style:
                      TextStyle(fontSize: 10.5, color: AppColors.textBody)),
              const SizedBox(height: 14),
              _revenueTable(o),
            ],
          ),
        ),
        const SizedBox(height: 18),
        AdminCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Payment Transactions',
                  style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark)),
              const SizedBox(height: 4),
              const Text('Outstanding visit fees and settlement trail.',
                  style:
                      TextStyle(fontSize: 10.5, color: AppColors.textBody)),
              const SizedBox(height: 14),
              _historyTable(o),
            ],
          ),
        ),
      ],
    );
  }

  Widget _revenueTable(RevenueOverview o) {
    if (o.doctors.isEmpty) {
      return _emptyBox('No doctor revenue recorded yet.');
    }
    return Table(
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: IntrinsicColumnWidth(),
        2: IntrinsicColumnWidth(),
        3: IntrinsicColumnWidth(),
        4: IntrinsicColumnWidth(),
        5: IntrinsicColumnWidth(),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: const BoxDecoration(color: AdminColors.bgSubtle),
          children: _headerCells(
              ['Doctor', 'Status', 'Payments', 'Collected', 'Admin Income', 'Doctor Payout']),
        ),
        ...o.doctors.map(
          (d) {
            final adminDoctor =
                _adminDoctors.where((ad) => ad.userName == d.doctorName).firstOrNull;
            final hasBank = adminDoctor?.hasBankDetails ?? false;
            return TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: AdminColors.emerald500.withOpacity(0.12),
                        child: Text(
                          d.doctorName.isEmpty
                              ? '?'
                              : d.doctorName[0].toUpperCase(),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AdminColors.emerald600),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Text(d.doctorName,
                          style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasBank
                            ? Icons.check_circle_rounded
                            : Icons.remove_circle_outline_rounded,
                        size: 14,
                        color: hasBank ? AdminColors.emerald500 : AdminColors.amber,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        hasBank ? 'Bank linked' : 'No bank',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: hasBank
                                ? AdminColors.emerald600
                                : AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: _bulkCell('${d.payments}'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: _bulkCell(formatMoney(d.collected)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: _bulkCell(formatMoney(d.adminKeep)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _bulkCell(formatMoney(d.doctorShare)),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Set bank details',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.account_balance_wallet_rounded,
                            size: 16, color: AppColors.textMuted),
                        onPressed: () => _openBankDetails(d),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _historyTable(RevenueOverview o) {
    if (o.payments.isEmpty) {
      return _emptyBox('No payment transactions recorded yet.');
    }
    return Table(
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: FlexColumnWidth(),
        2: IntrinsicColumnWidth(),
        3: IntrinsicColumnWidth(),
        4: IntrinsicColumnWidth(),
        5: IntrinsicColumnWidth(),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: const BoxDecoration(color: AdminColors.bgSubtle),
          children: _headerCells(
              ['Appointment', 'Patient', 'Doctor', 'Fee', 'Doctor Share', 'Status']),
        ),
        ...o.payments.map(
          (p) => TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
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
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Text(p.patientName,
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Text(p.doctorName,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textBody)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: _bulkCell(formatMoney(p.fee)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: _bulkCell(formatMoney(p.doctorShare)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: _payoutChip(p),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _headerCells(List<String> labels) => labels
      .map((l) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Text(l,
                style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMuted,
                    letterSpacing: 0.3)),
          ))
      .toList();

  Widget _bulkCell(String text) => Text(text,
      style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark));

  Widget _payoutChip(RevenuePayment p) {
    final paid = p.payoutStatus.toUpperCase().contains('PAID');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: paid
            ? AdminColors.emerald500.withOpacity(0.11)
            : AdminColors.amber.withOpacity(0.12),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        paid ? 'PAID OUT' : 'PENDING',
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: paid ? AdminColors.emerald600 : AdminColors.darkAmber,
        ),
      ),
    );
  }

  Widget _emptyBox(String message) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 22),
        child: Center(
          child: Text(message,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textHint)),
        ),
      );
}

class _ShareCard extends StatefulWidget {
  const _ShareCard({
    required this.currentPercent,
    required this.saving,
    required this.onSave,
  });

  final int currentPercent;
  final bool saving;
  final ValueChanged<int> onSave;

  @override
  State<_ShareCard> createState() => _ShareCardState();
}

class _ShareCardState extends State<_ShareCard> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: '${widget.currentPercent}');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AdminColors.violet.withOpacity(0.13),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.percent_rounded,
                size: 18, color: AdminColors.violet),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Doctor Payout Share',
                    style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark)),
                Text(
                    'Percentage of every consultation kept aside for the attending doctor.',
                    style:
                        TextStyle(fontSize: 10.5, color: AppColors.textBody)),
              ],
            ),
          ),
          SizedBox(
            width: 130,
            child: TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: modalFieldBorder(),
                suffix: const Text('%', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          AdminButton(
            label: widget.saving ? 'Saving…' : 'Update',
            icon: Icons.check_rounded,
            onPressed: widget.saving
                ? null
                : () => widget.onSave(int.tryParse(_ctrl.text) ?? widget.currentPercent),
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