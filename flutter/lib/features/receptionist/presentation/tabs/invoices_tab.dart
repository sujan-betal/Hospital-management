import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../admin/presentation/admin_colors.dart';
import '../../../admin/presentation/widgets/admin_common.dart';
import '../../data/receptionist_models.dart';

/// Billing console — invoices with create + mark-paid actions
/// (GET/POST/PUT /api/receptionist/invoices).
class InvoicesTab extends StatefulWidget {
  const InvoicesTab({
    super.key,
    required this.invoices,
    required this.onCreate,
    required this.onMarkPaid,
  });

  final List<Invoice> invoices;
  final Future<bool> Function(Map<String, dynamic> payload) onCreate;
  final Future<void> Function(Invoice invoice) onMarkPaid;

  @override
  State<InvoicesTab> createState() => _InvoicesTabState();
}

class _InvoicesTabState extends State<InvoicesTab> {
  String _filter = 'ALL';

  List<Invoice> get _filtered {
    if (_filter == 'ALL') return widget.invoices;
    final wantPaid = _filter == 'PAID';
    return widget.invoices.where((i) => i.isPaid == wantPaid).toList();
  }

  Future<void> _openCreate() async {
    final ok = await showAdminModal<bool>(
      context,
      title: 'Create Invoice',
      subtitle: 'Itemize charges for a patient visit',
      child: _InvoiceForm(onSubmit: widget.onCreate),
    );
    if (ok == true && mounted) {
      showAdminToast(context, 'Invoice created');
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalUnpaid = widget.invoices
        .where((i) => !i.isPaid)
        .fold<int>(0, (sum, i) => sum + i.amount);

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        SectionHeader(
          title: 'Billing & Invoices',
          subtitle: '${widget.invoices.length} invoices · ${formatMoney(totalUnpaid)} outstanding',
          action: AdminButton(
            label: 'Create Invoice',
            icon: Icons.post_add_rounded,
            onPressed: _openCreate,
          ),
        ),
        const SizedBox(height: 16),
        SegmentedFilter(
          options: const ['ALL', 'PAID', 'UNPAID'],
          selected: _filter,
          onChanged: (v) => setState(() => _filter = v),
        ),
        const SizedBox(height: 16),
        if (_filtered.isEmpty)
          const AdminEmpty(message: 'No invoices in this view.')
        else
          AdminCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < _filtered.length; i++) ...[
                  _InvoiceTile(
                    invoice: _filtered[i],
                    onMarkPaid: widget.onMarkPaid,
                  ),
                  if (i != _filtered.length - 1)
                    const Divider(height: 1, color: AdminColors.border),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  const _InvoiceTile({required this.invoice, required this.onMarkPaid});

  final Invoice invoice;
  final Future<void> Function(Invoice) onMarkPaid;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AdminColors.bgSubtle,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              invoice.isPaid
                  ? Icons.check_circle_rounded
                  : Icons.schedule_rounded,
              color: invoice.isPaid ? AdminColors.emerald600 : AdminColors.amber,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      invoice.invoiceId,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Pill(
                      label: invoice.insuranceStatus,
                      bg: AdminColors.purple50,
                      fg: AdminColors.purple,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${invoice.patientName} · ${invoice.date}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 3),
                Text(
                  invoice.items
                      .map((e) => '${e.description} (${formatMoney(e.cost)})')
                      .join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textHint),
                ),
              ],
            ),
          ),
          Text(
            formatMoney(invoice.amount),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(width: 12),
          if (!invoice.isPaid)
            AdminGhostButton(
              label: 'Mark Paid',
              onPressed: () => onMarkPaid(invoice),
            )
          else
            Pill(label: 'PAID', bg: AdminColors.teal50, fg: AdminColors.teal),
        ],
      ),
    );
  }
}

class _InvoiceForm extends StatefulWidget {
  const _InvoiceForm({required this.onSubmit});

  final Future<bool> Function(Map<String, dynamic> payload) onSubmit;

  @override
  State<_InvoiceForm> createState() => _InvoiceFormState();
}

class _InvoiceFormState extends State<_InvoiceForm> {
  final _patient = TextEditingController();
  final _date = TextEditingController();
  final _items = <InvoiceItem>[];
  final _desc = TextEditingController();
  final _cost = TextEditingController();
  String _insurance = 'UNINSURED';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _patient.dispose();
    _date.dispose();
    _desc.dispose();
    _cost.dispose();
    super.dispose();
  }

  void _addItem() {
    final desc = _desc.text.trim();
    final cost = int.tryParse(_cost.text.trim());
    if (desc.isEmpty || cost == null || cost < 0) return;
    setState(() {
      _items.add(InvoiceItem(description: desc, cost: cost));
      _desc.clear();
      _cost.clear();
    });
  }

  Future<void> _submit() async {
    if (_patient.text.trim().isEmpty || _items.isEmpty) {
      setState(() =>
          _error = 'Patient name and at least one line item are required.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final ok = await widget.onSubmit({
      'patient_name': _patient.text.trim(),
      'date': _date.text.trim().isEmpty ? _today() : _date.text.trim(),
      'items': _items.map((e) => e.toJson()).toList(),
      'insurance_status': _insurance,
      'payment_status': 'UNPAID',
    });
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _saving = false);
    }
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final total = _items.fold<int>(0, (s, e) => s + e.cost);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ModalField(
          label: 'Patient name *',
          field: TextField(
            controller: _patient,
            style: const TextStyle(fontSize: 14),
            decoration:
                InputDecoration(hintText: 'Patient name', border: modalFieldBorder()),
          ),
        ),
        const SizedBox(height: 14),
        ModalField(
          label: 'Date',
          field: TextField(
            controller: _date,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
                hintText: '${_today()} (default)', border: modalFieldBorder()),
          ),
        ),
        const SizedBox(height: 14),
        ModalField(
          label: 'Insurance status',
          field: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
                border: Border.all(color: AdminColors.border),
                borderRadius: BorderRadius.circular(10)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _insurance,
                isExpanded: true,
                style:
                    const TextStyle(fontSize: 14, color: AppColors.textDark),
                items: ['UNINSURED', 'COVERED']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _insurance = v ?? _insurance),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Line items',
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textMid)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _desc,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                    hintText: 'Description', border: modalFieldBorder()),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _cost,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                    hintText: 'Cost', border: modalFieldBorder()),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              onPressed: _addItem,
              style: IconButton.styleFrom(backgroundColor: AppColors.primary),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_items.isEmpty)
          Text('No items added yet.',
              style: TextStyle(fontSize: 12, color: AppColors.textHint))
        else ...[
          for (final item in _items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(item.description,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textDark)),
                  ),
                  Text(formatMoney(item.cost),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          const Divider(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text('Total',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
              ),
              Text(formatMoney(total),
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark)),
            ],
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!,
              style: const TextStyle(fontSize: 12, color: AdminColors.rose)),
        ],
        const SizedBox(height: 20),
        AdminButton(
          label: _saving ? 'Creating…' : 'Create Invoice',
          icon: Icons.check_rounded,
          onPressed: _saving ? null : _submit,
        ),
      ],
    );
  }
}