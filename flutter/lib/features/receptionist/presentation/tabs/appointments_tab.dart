import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../admin/presentation/admin_colors.dart';
import '../../../admin/presentation/widgets/admin_common.dart';
import '../../data/receptionist_models.dart';

/// OPD scheduler — table of appointments with book / check-in / complete /
/// cancel actions (all backed by /api/receptionist/appointments).
class AppointmentsTab extends StatefulWidget {
  const AppointmentsTab({
    super.key,
    required this.appointments,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
  });

  final List<Appointment> appointments;
  final Future<bool> Function(Map<String, dynamic> payload) onAdd;
  final Future<void> Function(Appointment appt, Map<String, dynamic> payload)
      onUpdate;
  final Future<void> Function(Appointment appt) onDelete;

  @override
  State<AppointmentsTab> createState() => _AppointmentsTabState();
}

class _AppointmentsTabState extends State<AppointmentsTab> {
  String _filter = 'ALL';

  List<Appointment> get _filtered => _filter == 'ALL'
      ? widget.appointments
      : widget.appointments.where((a) => a.status == _filter).toList();

  Future<void> _openBook() async {
    final ok = await showAdminModal<bool>(
      context,
      title: 'Book OPD Appointment',
      subtitle: 'Reserve a patient slot with a doctor',
      child: _BookForm(onSubmit: widget.onAdd),
    );
    if (ok == true && mounted) {
      showAdminToast(context, 'Appointment booked');
    }
  }

  Future<void> _transition(Appointment appt, String newStatus) async {
    await widget.onUpdate(appt, {'status': newStatus});
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        SectionHeader(
          title: 'OPD Appointments',
          subtitle: '${widget.appointments.length} appointments on record',
          action: AdminButton(
            label: 'Book Appointment',
            icon: Icons.event_available_rounded,
            onPressed: _openBook,
          ),
        ),
        const SizedBox(height: 16),
        SegmentedFilter(
          options: const ['ALL', 'SCHEDULED', 'CHECKED-IN', 'COMPLETED', 'CANCELLED'],
          selected: _filter,
          onChanged: (v) => setState(() => _filter = v),
        ),
        const SizedBox(height: 16),
        if (_filtered.isEmpty)
          const AdminEmpty(message: 'No appointments in this view.')
        else
          AdminCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < _filtered.length; i++) ...[
                  _AppointmentTile(
                    appointment: _filtered[i],
                    onChangeStatus: _transition,
                    onDelete: widget.onDelete,
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

class _AppointmentTile extends StatelessWidget {
  const _AppointmentTile({
    required this.appointment,
    required this.onChangeStatus,
    required this.onDelete,
  });

  final Appointment appointment;
  final Future<void> Function(Appointment, String) onChangeStatus;
  final Future<void> Function(Appointment) onDelete;

  (Color, Color) get _statusColors {
    switch (appointment.status) {
      case 'COMPLETED':
        return (AdminColors.teal50, AdminColors.teal);
      case 'CHECKED-IN':
        return (AdminColors.blue50, AdminColors.blue);
      case 'CANCELLED':
        return (AdminColors.rose50, AdminColors.rose);
      default:
        return (AdminColors.amber50, AdminColors.darkAmber);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _statusColors;
    final showActions = appointment.status != 'CANCELLED' &&
        appointment.status != 'COMPLETED';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AdminColors.bgSubtle,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  appointment.date.split('-').last,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  appointment.time,
                  style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.patientName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${appointment.doctorName} · ${appointment.specialty}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  appointment.patientPhone.isEmpty
                      ? appointment.date
                      : appointment.patientPhone,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textHint),
                ),
              ],
            ),
          ),
          Pill(label: appointment.status, bg: bg, fg: fg),
          if (showActions) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Check in',
              onPressed: appointment.status == 'SCHEDULED'
                  ? () => onChangeStatus(appointment, 'CHECKED-IN')
                  : null,
              icon: const Icon(Icons.check_circle_outline_rounded,
                  color: AdminColors.teal, size: 20),
            ),
            IconButton(
              tooltip: 'Complete',
              onPressed: appointment.status == 'CHECKED-IN'
                  ? () => onChangeStatus(appointment, 'COMPLETED')
                  : null,
              icon: const Icon(Icons.done_all_rounded,
                  color: AdminColors.blue, size: 20),
            ),
            IconButton(
              tooltip: 'Cancel',
              onPressed: () =>
                  onChangeStatus(appointment, 'CANCELLED'),
              icon: const Icon(Icons.cancel_rounded,
                  color: AdminColors.rose, size: 20),
            ),
            IconButton(
              tooltip: 'Delete',
              onPressed: () => onDelete(appointment),
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.textFaint, size: 20),
            ),
          ],
        ],
      ),
    );
  }
}

class _BookForm extends StatefulWidget {
  const _BookForm({required this.onSubmit});

  final Future<bool> Function(Map<String, dynamic> payload) onSubmit;

  @override
  State<_BookForm> createState() => _BookFormState();
}

class _BookFormState extends State<_BookForm> {
  final _patient = TextEditingController();
  final _phone = TextEditingController();
  final _doctor = TextEditingController();
  final _date = TextEditingController();
  final _time = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _patient.dispose();
    _phone.dispose();
    _doctor.dispose();
    _date.dispose();
    _time.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_patient.text.trim().isEmpty ||
        _doctor.text.trim().isEmpty ||
        _date.text.trim().isEmpty ||
        _time.text.trim().isEmpty) {
      setState(() => _error = 'Patient, doctor, date and time are required.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final ok = await widget.onSubmit({
      'patient_name': _patient.text.trim(),
      'patient_phone': _phone.text.trim(),
      'doctor_name': _doctor.text.trim(),
      'date': _date.text.trim(),
      'time': _time.text.trim(),
    });
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          label: 'Patient phone',
          field: TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            style: const TextStyle(fontSize: 14),
            decoration:
                InputDecoration(hintText: 'Phone', border: modalFieldBorder()),
          ),
        ),
        const SizedBox(height: 14),
        ModalField(
          label: 'Doctor name *',
          field: TextField(
            controller: _doctor,
            style: const TextStyle(fontSize: 14),
            decoration:
                InputDecoration(hintText: 'Dr. Gregory House', border: modalFieldBorder()),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: ModalField(
                label: 'Date *',
                field: TextField(
                  controller: _date,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                      hintText: '2026-08-20', border: modalFieldBorder()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ModalField(
                label: 'Time *',
                field: TextField(
                  controller: _time,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                      hintText: '10:30 AM', border: modalFieldBorder()),
                ),
              ),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!,
              style: const TextStyle(fontSize: 12, color: AdminColors.rose)),
        ],
        const SizedBox(height: 20),
        AdminButton(
          label: _saving ? 'Booking…' : 'Book Appointment',
          icon: Icons.check_rounded,
          onPressed: _saving ? null : _submit,
        ),
      ],
    );
  }
}