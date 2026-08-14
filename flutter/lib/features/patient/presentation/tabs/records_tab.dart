import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../admin/presentation/admin_colors.dart';
import '../../../admin/presentation/widgets/admin_common.dart';
import '../../data/patient_models.dart';

/// "My Appointments & Bills" — metrics, appointment timeline with reschedule /
/// pay / review actions, and the invoice ledger. All rows come from the
/// `/api/patient/appointments`, `/api/patient/invoices` and `/api/patient/reviews`.
class RecordsTab extends StatefulWidget {
  const RecordsTab({
    super.key,
    required this.profile,
    required this.appointments,
    required this.invoices,
    required this.reviews,
    required this.onReschedule,
    required this.onPayNow,
    required this.onSubmitReview,
    required this.onBookNew,
  });

  final PatientProfile profile;
  final List<PatientAppointment> appointments;
  final List<PatientInvoice> invoices;
  final List<PatientReview> reviews;
  final Future<void> Function(
      PatientAppointment appt, String date, String time) onReschedule;
  final Future<void> Function(PatientAppointment appt) onPayNow;
  final Future<void> Function(
      PatientAppointment appt, int rating, String comment) onSubmitReview;
  final VoidCallback onBookNew;

  @override
  State<RecordsTab> createState() => _RecordsTabState();
}

class _RecordsTabState extends State<RecordsTab> {
  int get _upcoming => widget.appointments
      .where((a) => !['COMPLETED', 'CANCELLED'].contains(a.status.toUpperCase()))
      .length;

  int get _outstanding => widget.invoices
      .where((i) => i.paymentStatus.toUpperCase() == 'UNPAID')
      .fold(0, (sum, i) => sum + i.amount);

  Set<String> get _reviewedIds =>
      widget.reviews.map((r) => r.appointmentId).toSet();

  Future<void> _openReschedule(PatientAppointment appt) async {
    final dateCtrl = TextEditingController(text: appt.date);
    final timeCtrl = TextEditingController(text: appt.time);
    final ok = await showAdminModal<bool>(
      context,
      title: 'Reschedule Appointment',
      subtitle: 'Pick a new date & time with ${appt.doctorName}',
      child: StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> pickDate() async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.tryParse(appt.date) ?? now,
              firstDate: now.subtract(const Duration(days: 1)),
              lastDate: now.add(const Duration(days: 365)),
            );
            if (picked != null) {
              setModalState(() => dateCtrl.text = _fmtDate(picked));
            }
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ModalField(
                label: 'Date *',
                field: TextField(
                  controller: dateCtrl,
                  readOnly: true,
                  onTap: pickDate,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'YYYY-MM-DD',
                    suffixIcon: const Icon(Icons.calendar_today_rounded, size: 16),
                    border: modalFieldBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ModalField(
                label: 'Time *',
                field: TextField(
                  controller: timeCtrl,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                      hintText: '10:30 AM', border: modalFieldBorder()),
                ),
              ),
              const SizedBox(height: 20),
              AdminButton(
                label: 'Save New Timing',
                icon: Icons.check_rounded,
                onPressed: () async {
                  if (dateCtrl.text.trim().isEmpty || timeCtrl.text.trim().isEmpty) {
                    showAdminToast(context, 'Please choose a date and a time');
                    return;
                  }
                  Navigator.of(context).pop(true);
                  await widget.onReschedule(
                      appt, dateCtrl.text.trim(), timeCtrl.text.trim());
                },
              ),
            ],
          );
        },
      ),
    );
    if (ok == true && mounted) {}
  }

  String _fmtDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  Future<void> _openReview(PatientAppointment appt) async {
    var rating = 0;
    final commentCtrl = TextEditingController();
    final ok = await showAdminModal<bool>(
      context,
      title: 'Rate Your Doctor',
      subtitle: 'How was your visit with ${appt.doctorName}?',
      child: StatefulBuilder(
        builder: (context, setModalState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return IconButton(
                  onPressed: () => setModalState(() => rating = i + 1),
                  icon: Icon(
                    i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 30,
                    color: i < rating ? const Color(0xFFFBBF24) : AdminColors.borderLight,
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            ModalField(
              label: 'Comment (optional)',
              field: TextField(
                controller: commentCtrl,
                maxLines: 3,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                    hintText: 'Share your experience…', border: modalFieldBorder()),
              ),
            ),
            const SizedBox(height: 20),
            AdminButton(
              label: 'Submit Review',
              icon: Icons.send_rounded,
              onPressed: () async {
                if (rating < 1) {
                  showAdminToast(context, 'Please select a star rating');
                  return;
                }
                Navigator.of(context).pop(true);
                await widget.onSubmitReview(
                    appt, rating, commentCtrl.text.trim());
              },
            ),
          ],
        ),
      ),
    );
    if (ok == true && mounted) {}
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _metrics(),
        const SizedBox(height: 20),
        _appointmentsCard(),
        const SizedBox(height: 20),
        _invoicesCard(),
      ],
    );
  }

  Widget _metrics() {
    final cards = [
      (
        label: 'Upcoming Appointments',
        value: '$_upcoming',
        icon: Icons.calendar_month_rounded,
        bg: AdminColors.bgSubtle,
        fg: AdminColors.emerald600,
      ),
      (
        label: 'Total Bills',
        value: '${widget.invoices.length}',
        icon: Icons.science_rounded,
        bg: AdminColors.blue50,
        fg: AdminColors.blue,
      ),
      (
        label: 'Outstanding Balance',
        value: 'Rs. $_outstanding',
        icon: Icons.credit_card_rounded,
        bg: AdminColors.rose50,
        fg: AdminColors.rose,
      ),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final columns = c.maxWidth >= 800 ? 3 : 1;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: columns == 1 ? 3.2 : 2.4,
          children: [
            for (final card in cards)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AdminColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AdminColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: card.bg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(card.icon, size: 21, color: card.fg),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(card.label.toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                  color: AppColors.textMuted)),
                          const SizedBox(height: 5),
                          Text(card.value,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textDark)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _appointmentsCard() {
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('My Appointments',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark)),
                      SizedBox(height: 3),
                      Text(
                          'Every consultation booked through the portal or front desk',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: widget.onBookNew,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Book new',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.emeraldDark,
                    side: BorderSide(color: AdminColors.borderLight),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AdminColors.border),
          if (widget.appointments.isEmpty)
            const AdminEmpty(
              message: 'No appointments yet. Book a slot with a doctor.',
              icon: Icons.event_available_rounded,
            )
          else
            for (var i = 0; i < widget.appointments.length; i++) ...[
              _AppointmentRow(
                appointment: widget.appointments[i],
                reviewed: _reviewedIds.contains(widget.appointments[i].appointmentId),
                onReschedule: _openReschedule,
                onPayNow: widget.onPayNow,
                onReview: _openReview,
              ),
              if (i != widget.appointments.length - 1)
                const Divider(height: 1, color: AdminColors.border),
            ],
        ],
      ),
    );
  }

  Widget _invoicesCard() {
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bills & Invoices',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark)),
                SizedBox(height: 3),
                Text('Invoices raised against your visits at the billing desk',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          const Divider(height: 1, color: AdminColors.border),
          if (widget.invoices.isEmpty)
            const AdminEmpty(
              message: 'No bills yet. Any invoice created at the front desk will appear here.',
              icon: Icons.credit_card_rounded,
            )
          else
            for (var i = 0; i < widget.invoices.length; i++) ...[
              _InvoiceRow(invoice: widget.invoices[i]),
              if (i != widget.invoices.length - 1)
                const Divider(height: 1, color: AdminColors.border),
            ],
        ],
      ),
    );
  }
}

class _AppointmentRow extends StatelessWidget {
  const _AppointmentRow({
    required this.appointment,
    required this.reviewed,
    required this.onReschedule,
    required this.onPayNow,
    required this.onReview,
  });

  final PatientAppointment appointment;
  final bool reviewed;
  final ValueChanged<PatientAppointment> onReschedule;
  final ValueChanged<PatientAppointment> onPayNow;
  final ValueChanged<PatientAppointment> onReview;

  (Color, Color) get _statusColors {
    switch (appointment.status.toUpperCase()) {
      case 'COMPLETED':
        return (AdminColors.blue50, AdminColors.blue);
      case 'CANCELLED':
        return (AdminColors.rose50, AdminColors.rose);
      default:
        return (AdminColors.teal50, AdminColors.teal);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (statusBg, statusFg) = _statusColors;
    final isScheduled = appointment.status.toUpperCase() == 'SCHEDULED';
    final isVisited = ['CHECKED-IN', 'COMPLETED'].contains(appointment.status.toUpperCase());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AdminColors.bgSubtle,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.medical_services_rounded,
                    color: AdminColors.emerald600, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(appointment.doctorName,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark)),
                        ),
                        const SizedBox(width: 8),
                        Text(appointment.appointmentId,
                            style: const TextStyle(
                                fontSize: 10,
                                fontFamily: 'monospace',
                                color: AppColors.textHint)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(appointment.specialty,
                        style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.emeraldDark)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 12, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Text('${appointment.date} · ${appointment.time}',
                            style: const TextStyle(
                                fontSize: 11.5, color: AppColors.textBody)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Pill(label: appointment.status, bg: statusBg, fg: statusFg),
                  const SizedBox(height: 6),
                  Pill(
                    label: appointment.isPaid
                        ? 'Fee: Rs. ${appointment.fee} · PAID'
                        : 'Fee: Rs. ${appointment.fee} · ${appointment.paymentStatus}',
                    bg: appointment.isPaid
                        ? AdminColors.teal50
                        : AdminColors.amber50,
                    fg: appointment.isPaid
                        ? AdminColors.teal
                        : AdminColors.darkAmber,
                  ),
                ],
              ),
            ],
          ),
          if (isScheduled || isVisited) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (isScheduled) ...[
                  _actionChip(
                    icon: Icons.edit_calendar_rounded,
                    label: 'Edit Timing',
                    bg: AdminColors.bgSoft,
                    fg: AppColors.emeraldDark,
                    onTap: () => onReschedule(appointment),
                  ),
                  if (!appointment.isPaid)
                    _actionChip(
                      icon: Icons.wallet_rounded,
                      label: 'Pay Now',
                      bg: AppColors.emeraldDark,
                      fg: Colors.white,
                      onTap: () => onPayNow(appointment),
                    ),
                ],
                if (isVisited)
                  if (reviewed)
                    _actionChip(
                      icon: Icons.check_circle_rounded,
                      label: 'Reviewed',
                      bg: AdminColors.teal50,
                      fg: AdminColors.teal,
                      onTap: null,
                    )
                  else
                    _actionChip(
                      icon: Icons.star_rounded,
                      label: 'Rate Doctor',
                      bg: AdminColors.amber50,
                      fg: AdminColors.darkAmber,
                      onTap: () => onReview(appointment),
                    ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionChip({
    required IconData icon,
    required String label,
    required Color bg,
    required Color fg,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow({required this.invoice});

  final PatientInvoice invoice;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AdminColors.rose50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.receipt_long_rounded,
                color: AdminColors.rose, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(invoice.invoiceId,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark)),
                    const SizedBox(width: 8),
                    Text(invoice.date,
                        style: const TextStyle(
                            fontSize: 10.5,
                            fontFamily: 'monospace',
                            color: AppColors.textHint)),
                  ],
                ),
                if (invoice.items.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  for (final item in invoice.items)
                    Row(
                      children: [
                        Expanded(
                          child: Text(item.description,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textBody)),
                        ),
                        Text('Rs. ${item.cost}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.emeraldDark)),
                      ],
                    ),
                ],
                const SizedBox(height: 6),
                Text('Total: Rs. ${invoice.amount}',
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Pill(
            label: invoice.paymentStatus,
            bg: invoice.isPaid ? AdminColors.teal50 : AdminColors.rose50,
            fg: invoice.isPaid ? AdminColors.teal : AdminColors.rose,
          ),
        ],
      ),
    );
  }
}
