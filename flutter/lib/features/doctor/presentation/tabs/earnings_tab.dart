import 'package:flutter/material.dart';

import '../../data/doctor_models.dart';
import '../../data/doctor_repository.dart';
import '../doctor_colors.dart';
import '../widgets/doctor_common.dart';

class EarningsTab extends StatefulWidget {
  const EarningsTab({super.key});

  @override
  State<EarningsTab> createState() => _EarningsTabState();
}

class _EarningsTabState extends State<EarningsTab> {
  DoctorEarnings? _earnings;
  bool _loading = true;
  bool _saving = false;
  String? _bankMsg;
  bool _bankError = false;

  // Bank form controllers
  final _holder = TextEditingController();
  final _account = TextEditingController();
  final _ifsc = TextEditingController();
  final _bankName = TextEditingController();
  final _upi = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _holder.dispose();
    _account.dispose();
    _ifsc.dispose();
    _bankName.dispose();
    _upi.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final e = await DoctorRepository.getEarnings();
      if (!mounted) return;
      setState(() {
        _earnings = e;
        _holder.text = e.bank.accountHolder;
        _account.text = e.bank.accountNumber;
        _ifsc.text = e.bank.ifsc;
        _bankName.text = e.bank.bankName;
        _upi.text = e.bank.upiId;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveBank() async {
    setState(() {
      _saving = true;
      _bankMsg = null;
    });
    final payload = DoctorBankDetails(
      accountHolder: _holder.text.trim(),
      accountNumber: _account.text.trim(),
      ifsc: _ifsc.text.trim().toUpperCase(),
      bankName: _bankName.text.trim(),
      upiId: _upi.text.trim(),
      hasBankDetails: false,
    );
    try {
      await DoctorRepository.updateBankDetails(payload);
      if (!mounted) return;
      setState(() {
        _bankMsg = 'Bank details saved. Payouts will be sent to this account.';
        _bankError = false;
      });
      _load();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _bankMsg = 'Failed to save bank details: $e';
        _bankError = true;
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _fmt(num v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    final digits = s.replaceAll('-', '');
    for (var i = 0; i < digits.length; i++) {
      final fromEnd = digits.length - i;
      if (i > 0 && fromEnd % 3 == 0) buf.write(',');
      buf.write(digits[i]);
    }
    return v < 0 ? '-$buf' : buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final summary = _earnings?.summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_bankMsg != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: (_bankError ? DoctorColors.rose : DoctorColors.emerald)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: (_bankError ? DoctorColors.rose : DoctorColors.emerald)
                      .withOpacity(0.2)),
            ),
            child: Text(_bankMsg!,
                style: TextStyle(
                    color: _bankError
                        ? DoctorColors.rose
                        : DoctorColors.emeraldLight,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 16),
        ],
        const Text('Consultation Earnings',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text(
            'Your share of every confirmed OPD payment. Disbursed automatically to your bank when RazorpayX payouts are enabled.',
            style: TextStyle(color: DoctorColors.textBody, fontSize: 11.5)),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: DoctorStatCard(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Total Earned',
                value: 'Rs. ${_fmt(summary?.totalEarned ?? 0)}',
                accent: DoctorColors.emerald,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DoctorStatCard(
                icon: Icons.check_circle_rounded,
                label: 'Paid Out',
                value: 'Rs. ${_fmt(summary?.paidOut ?? 0)}',
                accent: DoctorColors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DoctorStatCard(
                icon: Icons.schedule_rounded,
                label: 'Pending Payout',
                value: 'Rs. ${_fmt(summary?.pending ?? 0)}',
                accent: DoctorColors.amber,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _bankCard(),
        const SizedBox(height: 18),
        _historyCard(),
      ],
    );
  }

  // ─────────────────────────── Bank details ───────────────────────────

  Widget _bankCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: DoctorColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: DoctorColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_rounded,
                  size: 20, color: DoctorColors.emeraldLight),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Payout Bank Account',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      _earnings?.bank.hasBankDetails == true
                          ? 'Details saved — payouts will be sent to this account.'
                          : 'Add your bank details to receive your consultation share.',
                      style: const TextStyle(
                          color: DoctorColors.textBody, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: DoctorColors.border),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: DoctorColors.emerald),
                  ),
                  SizedBox(width: 12),
                  Text('Loading earnings...',
                      style: TextStyle(
                          color: DoctorColors.textBody,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            )
          else
            LayoutBuilder(
              builder: (context, c) {
                final twoCol = c.maxWidth >= 720;
                final fields = [
                  _field('Account Holder Name', _holder,
                      'Full name as on bank account'),
                  _field('Account Number', _account,
                      '9–18 digit account number'),
                  _field('IFSC Code', _ifsc, '11 chars, e.g. HDFC0001234',
                      uppercase: true),
                  _field('Bank Name', _bankName, 'e.g. HDFC Bank'),
                  _field('UPI ID (optional)', _upi, 'name@bank',
                      full: true),
                ];
                return Column(
                  children: [
                    if (twoCol)
                      for (var i = 0; i < fields.length; i += 2) ...[
                        if (i != 0) const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: fields[i]),
                            if (i + 1 < fields.length)
                              Padding(
                                padding: const EdgeInsets.only(left: 14),
                                child: Expanded(child: fields[i + 1]),
                              )
                            else
                              const SizedBox(width: 14),
                          ],
                        ),
                      ]
                    else
                      for (final f in fields) ...[
                        if (fields.indexOf(f) != 0) const SizedBox(height: 14),
                        f,
                      ],
                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _saveBank,
                        icon: _saving
                            ? const SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save_rounded, size: 15),
                        label: const Text('Save Bank Details'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DoctorColors.emerald,
                          disabledBackgroundColor:
                              DoctorColors.emerald.withOpacity(0.5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                              fontSize: 11.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller,
    String hint, {
    bool uppercase = false,
    bool full = false,
  }) {
    final input = TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 12.5),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: DoctorColors.textFaint),
        filled: true,
        fillColor: DoctorColors.canvas,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DoctorColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DoctorColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DoctorColors.emerald),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: DoctorColors.emeraldLight,
                fontSize: 11.5,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        input,
      ],
    );
  }

  // ─────────────────────────── Payment history ───────────────────────────

  Widget _historyCard() {
    final payments = _earnings?.payments ?? const <DoctorEarningPayment>[];
    return Container(
      decoration: BoxDecoration(
        color: DoctorColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: DoctorColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            decoration: const BoxDecoration(
              color: DoctorColors.surfaceDeep,
              border: Border(bottom: BorderSide(color: DoctorColors.border)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Payment History',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                      SizedBox(height: 3),
                      Text(
                          'Confirmed consultation payments & payout status',
                          style: TextStyle(
                              color: DoctorColors.textBody, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (payments.isEmpty)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Text(
                'No confirmed payments yet — your share appears here after patients pay.',
                textAlign: TextAlign.center,
                style: TextStyle(color: DoctorColors.textFaint, fontSize: 12),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 900),
                child: Column(
                  children: [
                    _histHeader(),
                    ...payments.map(_histRow),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _histHeader() {
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
          _Cell(flex: 3, child: Text('APPOINTMENT', style: style)),
          _Cell(flex: 3, child: Text('PATIENT', style: style)),
          _Cell(flex: 2, child: Text('DATE', style: style)),
          _Cell(flex: 2, child: Text('FEE', style: style)),
          _Cell(flex: 2, child: Text('SPLIT', style: style)),
          _Cell(flex: 2, child: Text('YOUR SHARE', style: style)),
          _Cell(flex: 3, child: Text('PAYOUT', style: style)),
        ],
      ),
    );
  }

  Widget _histRow(DoctorEarningPayment p) {
    final (payoutColor, payoutLabel) = switch (p.payoutStatus) {
      'PAID' => (DoctorColors.emerald,
          'Paid ${p.payoutDate.isNotEmpty ? p.payoutDate.substring(0, 10) : ''}'),
      'FAILED' => (DoctorColors.rose, 'Failed'),
      _ => (DoctorColors.amber, 'Pending'),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: DoctorColors.border)),
      ),
      child: Row(
        children: [
          _Cell(
            flex: 3,
            child: Text(p.appointmentId,
                style: const TextStyle(
                    color: DoctorColors.emeraldLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace')),
          ),
          _Cell(
            flex: 3,
            child: Text(p.patientName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700)),
          ),
          _Cell(
            flex: 2,
            child: Text(p.date,
                style: const TextStyle(
                    color: DoctorColors.textBody, fontSize: 12)),
          ),
          _Cell(
            flex: 2,
            child: Text('Rs. ${_fmt(p.fee)}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
          _Cell(
            flex: 2,
            child: Text('${p.doctorSharePercent}%',
                style: const TextStyle(
                    color: DoctorColors.textBody, fontSize: 12)),
          ),
          _Cell(
            flex: 2,
            child: Text('Rs. ${_fmt(p.doctorShare)}',
                style: const TextStyle(
                    color: DoctorColors.emeraldLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
          _Cell(
            flex: 3,
            child: Align(
              alignment: Alignment.centerLeft,
              child: DoctorPill(
                label: payoutLabel,
                color: payoutColor,
                pulse: p.payoutStatus == 'PENDING',
              ),
            ),
          ),
        ],
      ),
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
