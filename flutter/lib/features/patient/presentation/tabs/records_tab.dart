import 'package:flutter/material.dart';

import '../../data/patient_models.dart';
import '../patient_colors.dart';
import '../widgets/patient_common.dart';

/// Tab 1 — My Appointments & Bills (records).
class RecordsTab extends StatelessWidget {
  const RecordsTab({
    super.key,
    required this.appointments,
    required this.invoices,
    required this.loading,
    required this.reviewedAppointmentIds,
    required this.payingAppointmentId,
    required this.onBookNew,
    required this.onEdit,
    required this.onPay,
    required this.onRate,
  });

  final List<PatientAppointment> appointments;
  final List<PatientInvoice> invoices;
  final bool loading;
  final Set<String> reviewedAppointmentIds;
  final String? payingAppointmentId;
  final VoidCallback onBookNew;
  final void Function(PatientAppointment) onEdit;
  final void Function(PatientAppointment) onPay;
  final void Function(PatientAppointment) onRate;

  int get _upcoming => appointments
      .where((a) =>
          !['COMPLETED', 'CANCELLED'].contains(a.status.toUpperCase()))
      .length;

  int get _totalBills => invoices.length;

  int get _outstanding => invoices
      .where((i) => i.paymentStatus.toUpperCase() == 'UNPAID')
      .fold(0, (sum, i) => sum + i.amount.toInt());

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, c) {
            final cards = [
              PatientStatCard(
                icon: Icons.calendar_month_rounded,
                label: 'Upcoming Appointments',
                value: loading ? '…' : '$_upcoming',
                accent: PatientColors.emeraldDark,
                soft: PatientColors.emeraldSoft,
              ),
              PatientStatCard(
                icon: Icons.science_rounded,
                label: 'Total Bills',
                value: loading ? '…' : '$_totalBills',
                accent: PatientColors.blue,
                soft: PatientColors.blueSoft,
              ),
              PatientStatCard(
                icon: Icons.credit_card_rounded,
                label: 'Outstanding Balance',
                value: loading ? '…' : 'Rs. $_outstanding',
                accent: PatientColors.rose,
                soft: PatientColors.roseSoft,
              ),
            ];
            if (c.maxWidth < 760) {
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: cards
                    .map((card) => SizedBox(
                        width: c.maxWidth, child: card))
                    .toList(),
              );
            }
            return Row(
              children: [
                for (final card in cards)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: card,
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        PatientSectionCard(
          title: 'My Appointments',
          subtitle:
              'Every consultation booked through the portal or front desk',
          action: PatientOutlineButton(
            label: 'Book new',
            icon: Icons.add_rounded,
            onPressed: onBookNew,
            compact: true,
          ),
          noPadding: true,
          child: loading
              ? const Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(
                      child: Text('Loading your appointments…',
                          style: TextStyle(
                              color: PatientColors.textMuted, fontSize: 13))),
                )
              : appointments.isEmpty
                  ? _EmptyAppointments(onBook: onBookNew)
                  : Column(
                      children: appointments.map((a) {
                        return _AppointmentRow(
                          a: a,
                          reviewed: reviewedAppointmentIds.contains(
                              a.appointmentId),
                          paying: payingAppointmentId == a.appointmentId,
                          onEdit: () => onEdit(a),
                          onPay: () => onPay(a),
                          onRate: () => onRate(a),
                        );
                      }).toList(),
                    ),
        ),
        const SizedBox(height: 20),
        PatientSectionCard(
          title: 'Bills & Invoices',
          subtitle: 'Invoices raised against your visits at the billing desk',
          noPadding: true,
          child: loading
              ? const Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(
                      child: Text('Loading your bills…',
                          style: TextStyle(
                              color: PatientColors.textMuted, fontSize: 13))),
                )
              : invoices.isEmpty
                  ? const _EmptyBills()
                  : Column(
                      children: invoices.map(_InvoiceRow.new).toList(),
                    ),
        ),
      ],
    );
  }
}

class _EmptyAppointments extends StatelessWidget {
  const _EmptyAppointments({required this.onBook});

  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(36),
      child: Column(
        children: [
          const Icon(Icons.calendar_month_rounded,
              size: 40, color: PatientColors.textFaint),
          const SizedBox(height: 10),
          const Text('No appointments yet',
              style: TextStyle(
                  color: PatientColors.textMid,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Book a slot with a doctor from the Book Appointment tab.',
              textAlign: TextAlign.center,
              style: TextStyle(color: PatientColors.textMuted, fontSize: 12)),
          const SizedBox(height: 14),
          PatientPrimaryButton(
            label: 'Book Appointment',
            icon: Icons.arrow_forward_rounded,
            compact: true,
            onPressed: onBook,
          ),
        ],
      ),
    );
  }
}

class _EmptyBills extends StatelessWidget {
  const _EmptyBills();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(36),
      child: Column(
        children: [
          Icon(Icons.credit_card_rounded,
              size: 40, color: PatientColors.textFaint),
          SizedBox(height: 10),
          Text('No bills yet',
              style: TextStyle(
                  color: PatientColors.textMid,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          Text(
              'Any invoices created at the front desk for your phone number will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: PatientColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _AppointmentRow extends StatelessWidget {
  const _AppointmentRow({
    required this.a,
    required this.reviewed,
    required this.paying,
    required this.onEdit,
    required this.onPay,
    required this.onRate,
  });

  final PatientAppointment a;
  final bool reviewed;
  final bool paying;
  final VoidCallback onEdit;
  final VoidCallback onPay;
  final VoidCallback onRate;

  @override
  Widget build(BuildContext context) {
    final status = a.status.toUpperCase();
    final isCancelled = status == 'CANCELLED';
    final isCompleted = status == 'COMPLETED';
    final isPaid = a.paymentStatus.toUpperCase() == 'PAID';

    final statusPill = PatientPill(
      label: a.status.isEmpty ? 'SCHEDULED' : a.status,
      soft: isCancelled
          ? PatientColors.roseSoft
          : isCompleted
              ? PatientColors.blueSoft
              : PatientColors.emeraldSoft,
      text: isCancelled
          ? PatientColors.roseText
          : isCompleted
              ? PatientColors.blueText
              : PatientColors.emeraldText,
      line: isCancelled
          ? PatientColors.roseLine
          : isCompleted
              ? PatientColors.blueLine
              : PatientColors.emeraldLine,
    );

    final feePill = PatientPill(
      label: 'Fee: Rs. ${a.fee.toInt()} · ${a.paymentStatus}',
      soft: isPaid ? PatientColors.emeraldSoft : PatientColors.amberSoft,
      text: isPaid ? PatientColors.emeraldText : PatientColors.amberText,
      line: isPaid ? PatientColors.emeraldLine : PatientColors.amberLine,
    );

    final canRate = status == 'CHECKED-IN' || status == 'COMPLETED';
    final showActions = status == 'SCHEDULED' || canRate;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: PatientColors.border)),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 640;
          final leading = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: PatientColors.emeraldSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: PatientColors.emeraldLine),
                ),
                child: const Icon(Icons.medical_services_rounded,
                    size: 21, color: PatientColors.emeraldDark),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        Text(a.doctorName,
                            style: const TextStyle(
                                color: PatientColors.textStrong,
                                fontSize: 15,
                                fontWeight: FontWeight.w800)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: PatientColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(6),
                            border:
                                Border.all(color: PatientColors.borderStrong),
                          ),
                          child: Text(a.appointmentId,
                              style: const TextStyle(
                                  color: PatientColors.textMuted,
                                  fontSize: 10,
                                  fontFamily: 'monospace')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(a.specialty,
                        style: const TextStyle(
                            color: PatientColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded,
                            size: 14, color: PatientColors.textHint),
                        const SizedBox(width: 5),
                        Text(a.date,
                            style: const TextStyle(
                                color: PatientColors.textMid, fontSize: 12)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text('·',
                              style: TextStyle(
                                  color: PatientColors.textFaint,
                                  fontSize: 12)),
                        ),
                        const Icon(Icons.schedule_rounded,
                            size: 14, color: PatientColors.textHint),
                        const SizedBox(width: 5),
                        Text(a.time,
                            style: const TextStyle(
                                color: PatientColors.textMid, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );

          final trailing = Column(
            crossAxisAlignment: wide
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Wrap(spacing: 6, runSpacing: 6, children: [statusPill, feePill]),
              if (showActions) ...[
                const SizedBox(height: 10),
                if (status == 'SCHEDULED')
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    PatientOutlineButton(
                      label: 'Edit Timing',
                      icon: Icons.edit_rounded,
                      compact: true,
                      onPressed: onEdit,
                    ),
                    if (!isPaid)
                      PatientPrimaryButton(
                        label: paying ? 'Starting…' : 'Pay Now',
                        icon: Icons.wallet_rounded,
                        compact: true,
                        loading: paying,
                        onPressed: paying ? () {} : onPay,
                      ),
                  ]),
                if (canRate)
                  reviewed
                      ? const PatientPill(
                          label: 'Reviewed',
                          soft: PatientColors.emeraldSoft,
                          text: PatientColors.emeraldText,
                          line: PatientColors.emeraldLine,
                        )
                      : InkWell(
                          onTap: onRate,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 11, vertical: 8),
                            decoration: BoxDecoration(
                              color: PatientColors.amberSoft,
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: PatientColors.amberLine),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star_rounded,
                                    size: 13, color: PatientColors.amber),
                                SizedBox(width: 5),
                                Text('Rate Doctor',
                                    style: TextStyle(
                                        color: PatientColors.amberText,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
              ],
            ],
          );

          if (wide) {
            return Row(
              children: [
                Expanded(child: leading),
                const SizedBox(width: 16),
                trailing,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [leading, const SizedBox(height: 12), trailing],
          );
        },
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow(this.inv);

  final PatientInvoice inv;

  @override
  Widget build(BuildContext context) {
    final isPaid = inv.paymentStatus.toUpperCase() == 'PAID';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: PatientColors.border)),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 640;
          final leading = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: PatientColors.roseSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: PatientColors.roseLine),
                ),
                child: const Icon(Icons.credit_card_rounded,
                    size: 21, color: PatientColors.rose),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        Text(inv.invoiceId,
                            style: const TextStyle(
                                color: PatientColors.textStrong,
                                fontSize: 15,
                                fontWeight: FontWeight.w800)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: PatientColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(6),
                            border:
                                Border.all(color: PatientColors.borderStrong),
                          ),
                          child: Text(inv.date,
                              style: const TextStyle(
                                  color: PatientColors.textMuted,
                                  fontSize: 10,
                                  fontFamily: 'monospace')),
                        ),
                      ],
                    ),
                    if (inv.items.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      for (final item in inv.items)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(item.description,
                                    style: const TextStyle(
                                        color: PatientColors.textBody,
                                        fontSize: 12)),
                              ),
                              const SizedBox(width: 12),
                              Text('Rs. ${item.cost.toInt()}',
                                  style: const TextStyle(
                                      color: PatientColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                    ],
                    const SizedBox(height: 6),
                    Text('Total: Rs. ${inv.amount.toInt()}',
                        style: const TextStyle(
                            color: PatientColors.textStrong,
                            fontSize: 12,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          );

          final pill = PatientPill(
            label: inv.paymentStatus,
            soft: isPaid ? PatientColors.emeraldSoft : PatientColors.roseSoft,
            text: isPaid ? PatientColors.emeraldText : PatientColors.roseText,
            line: isPaid ? PatientColors.emeraldLine : PatientColors.roseLine,
          );

          if (wide) {
            return Row(
              children: [
                Expanded(child: leading),
                const SizedBox(width: 16),
                pill,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [leading, const SizedBox(height: 10), Align(alignment: Alignment.centerLeft, child: pill)],
          );
        },
      ),
    );
  }
}
