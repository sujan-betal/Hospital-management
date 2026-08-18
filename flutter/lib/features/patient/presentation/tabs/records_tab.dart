import 'package:flutter/material.dart';

import '../../data/patient_models.dart';
import '../patient_colors.dart';
import '../widgets/patient_common.dart';
import '../widgets/patient_modals.dart';

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
    required this.today,
    required this.bookedSlots,
    required this.onReschedule,
    required this.onPayNow,
    required this.onSubmitReview,
    required this.onBookNew,
  });

  final PatientProfile profile;
  final List<PatientAppointment> appointments;
  final List<PatientInvoice> invoices;
  final List<PatientReview> reviews;
  final String today;
  final List<BookedSlot> bookedSlots;
  final Future<bool> Function(
      PatientAppointment appt, String date, String time) onReschedule;
  final Future<void> Function(PatientAppointment appt) onPayNow;
  final Future<bool> Function(
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

  Set<String> _doctorBookedTimes(String doctorName) => {
        for (final s in widget.bookedSlots)
          if (s.doctorName == doctorName) s.time,
      };

  Future<void> _openReschedule(PatientAppointment appt) async {
    var saving = false;
    await showPatientModal<void>(
      context: context,
      title: 'Reschedule Appointment',
      subtitle: 'Pick a new date & time with ${appt.doctorName}',
      icon: Icons.edit_calendar_rounded,
      iconBg: PatientColors.emeraldSoft,
      iconColor: PatientColors.emeraldDark,
      child: StatefulBuilder(
        builder: (context, setModalState) => RescheduleModalBody(
          doctorName: appt.doctorName,
          initialDate: appt.date,
          initialTime: appt.time,
          today: widget.today,
          bookedTimes: _doctorBookedTimes(appt.doctorName),
          saving: saving,
          onSave: (date, time) async {
            setModalState(() => saving = true);
            final ok = await widget.onReschedule(appt, date, time);
            if (mounted) setModalState(() => saving = false);
            return ok;
          },
        ),
      ),
    );
  }

  Future<void> _openReview(PatientAppointment appt) async {
    var submitting = false;
    await showPatientModal<void>(
      context: context,
      title: 'Rate Your Doctor',
      subtitle: 'How was your visit with ${appt.doctorName}?',
      icon: Icons.star_rounded,
      iconBg: PatientColors.amberSoft,
      iconColor: PatientColors.amberText,
      child: StatefulBuilder(
        builder: (context, setModalState) => RateDoctorModalBody(
          doctorName: appt.doctorName,
          specialty: appt.specialty,
          submitting: submitting,
          onSubmit: (rating, comment) async {
            setModalState(() => submitting = true);
            final ok = await widget.onSubmitReview(appt, rating, comment);
            if (mounted) setModalState(() => submitting = false);
            return ok;
          },
        ),
      ),
    );
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
    return LayoutBuilder(
      builder: (context, c) {
        final columns = c.maxWidth >= 800 ? 3 : 1;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: columns == 1 ? 3.4 : 2.2,
          children: [
            PatientStatCard(
              label: 'Upcoming Appointments',
              value: '$_upcoming',
              icon: Icons.calendar_month_rounded,
              accent: PatientColors.emerald,
              soft: PatientColors.emeraldSoft,
            ),
            PatientStatCard(
              label: 'Total Bills',
              value: '${widget.invoices.length}',
              icon: Icons.science_rounded,
              accent: PatientColors.blue,
              soft: PatientColors.blueSoft,
            ),
            PatientStatCard(
              label: 'Outstanding Balance',
              value: 'Rs. $_outstanding',
              icon: Icons.credit_card_rounded,
              accent: PatientColors.rose,
              soft: PatientColors.roseSoft,
            ),
          ],
        );
      },
    );
  }

  Widget _appointmentsCard() {
    return PatientSectionCard(
      title: 'My Appointments',
      subtitle: 'Every consultation booked through the portal or front desk',
      action: PatientOutlineButton(
        label: 'Book new',
        icon: Icons.add_rounded,
        compact: true,
        onPressed: widget.onBookNew,
      ),
      noPadding: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(height: 1, color: PatientColors.border),
          if (widget.appointments.isEmpty)
            const PatientEmpty(
              message:
                  'No appointments yet. Book a slot with a doctor from the Book Appointment tab.',
              icon: Icons.event_available_rounded,
            )
          else
            for (var i = 0; i < widget.appointments.length; i++) ...[
              _AppointmentRow(
                appointment: widget.appointments[i],
                reviewed:
                    _reviewedIds.contains(widget.appointments[i].appointmentId),
                onReschedule: _openReschedule,
                onPayNow: widget.onPayNow,
                onReview: _openReview,
              ),
              if (i != widget.appointments.length - 1)
                const Divider(height: 1, color: PatientColors.border),
            ],
        ],
      ),
    );
  }

  Widget _invoicesCard() {
    return PatientSectionCard(
      title: 'Bills & Invoices',
      subtitle: 'Invoices raised against your visits at the billing desk',
      noPadding: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(height: 1, color: PatientColors.border),
          if (widget.invoices.isEmpty)
            const PatientEmpty(
              message:
                  'No bills yet. Any invoice created at the front desk will appear here.',
              icon: Icons.credit_card_rounded,
            )
          else
            for (var i = 0; i < widget.invoices.length; i++) ...[
              _InvoiceRow(invoice: widget.invoices[i]),
              if (i != widget.invoices.length - 1)
                const Divider(height: 1, color: PatientColors.border),
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

  (Color, Color, Color) get _statusColors {
    switch (appointment.status.toUpperCase()) {
      case 'COMPLETED':
        return (PatientColors.blueSoft, PatientColors.blueText, PatientColors.blueLine);
      case 'CANCELLED':
        return (PatientColors.roseSoft, PatientColors.roseText, PatientColors.roseLine);
      default:
        return (
          PatientColors.emeraldSoft,
          PatientColors.emeraldText,
          PatientColors.emeraldLine
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final (statusSoft, statusText, statusLine) = _statusColors;
    final isScheduled = appointment.status.toUpperCase() == 'SCHEDULED';
    final isVisited =
        ['CHECKED-IN', 'COMPLETED'].contains(appointment.status.toUpperCase());

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
                  color: PatientColors.emeraldSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: PatientColors.emeraldLine),
                ),
                child: const Icon(Icons.medical_services_rounded,
                    color: PatientColors.emeraldDark, size: 22),
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
                                  color: PatientColors.textStrong)),
                        ),
                        const SizedBox(width: 8),
                        Text(appointment.appointmentId,
                            style: const TextStyle(
                                fontSize: 10,
                                fontFamily: 'monospace',
                                color: PatientColors.textHint)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(appointment.specialty,
                        style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: PatientColors.emeraldDark)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 12, color: PatientColors.textHint),
                        const SizedBox(width: 4),
                        Text('${appointment.date} · ${appointment.time}',
                            style: const TextStyle(
                                fontSize: 11.5, color: PatientColors.textBody)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  PatientPill(
                    label: appointment.status,
                    soft: statusSoft,
                    text: statusText,
                    line: statusLine,
                  ),
                  const SizedBox(height: 6),
                  PatientPill(
                    label: appointment.isPaid
                        ? 'Fee: Rs. ${appointment.fee} · PAID'
                        : 'Fee: Rs. ${appointment.fee} · ${appointment.paymentStatus}',
                    soft: appointment.isPaid
                        ? PatientColors.emeraldSoft
                        : PatientColors.amberSoft,
                    text: appointment.isPaid
                        ? PatientColors.emeraldText
                        : PatientColors.amberText,
                    line: appointment.isPaid
                        ? PatientColors.emeraldLine
                        : PatientColors.amberLine,
                  ),
                ],
              ),
            ],
          ),
          if (isScheduled || isVisited) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (isScheduled) ...[
                  _actionChip(
                    icon: Icons.edit_calendar_rounded,
                    label: 'Edit Timing',
                    bg: PatientColors.surfaceAlt,
                    fg: PatientColors.primary,
                    onTap: () => onReschedule(appointment),
                  ),
                  if (!appointment.isPaid)
                    _actionChip(
                      icon: Icons.wallet_rounded,
                      label: 'Pay Now',
                      bg: PatientColors.primary,
                      fg: Colors.white,
                      onTap: () => onPayNow(appointment),
                    ),
                ],
                if (isVisited)
                  if (reviewed)
                    _actionChip(
                      icon: Icons.check_circle_rounded,
                      label: 'Reviewed',
                      bg: PatientColors.emeraldSoft,
                      fg: PatientColors.emeraldText,
                      onTap: null,
                    )
                  else
                    _actionChip(
                      icon: Icons.star_rounded,
                      label: 'Rate Doctor',
                      bg: PatientColors.amberSoft,
                      fg: PatientColors.amberText,
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
              color: PatientColors.roseSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: PatientColors.roseLine),
            ),
            child: const Icon(Icons.receipt_long_rounded,
                color: PatientColors.rose, size: 22),
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
                            color: PatientColors.textStrong)),
                    const SizedBox(width: 8),
                    Text(invoice.date,
                        style: const TextStyle(
                            fontSize: 10.5,
                            fontFamily: 'monospace',
                            color: PatientColors.textHint)),
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
                                  fontSize: 12, color: PatientColors.textBody)),
                        ),
                        Text('Rs. ${item.cost}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: PatientColors.emeraldDark)),
                      ],
                    ),
                ],
                const SizedBox(height: 6),
                Text('Total: Rs. ${invoice.amount}',
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: PatientColors.textStrong)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PatientPill(
            label: invoice.paymentStatus,
            soft: invoice.isPaid
                ? PatientColors.emeraldSoft
                : PatientColors.roseSoft,
            text: invoice.isPaid
                ? PatientColors.emeraldText
                : PatientColors.roseText,
            line: invoice.isPaid
                ? PatientColors.emeraldLine
                : PatientColors.roseLine,
          ),
        ],
      ),
    );
  }
}