import 'package:flutter/material.dart';

import '../../../../core/widgets/panel_scaffold.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../admin/data/admin_models.dart';
import '../../../admin/presentation/widgets/admin_common.dart';
import '../../../admin/presentation/admin_colors.dart';
import '../../data/receptionist_models.dart';
import '../../data/receptionist_repository.dart';
import '../tabs/analytics_tab.dart';
import '../tabs/appointments_tab.dart';
import '../tabs/beds_tab.dart';
import '../tabs/invoices_tab.dart';
import '../tabs/registry_tab.dart';

enum ReceptionistTab {
  registry('Patient Registry', Icons.badge_outlined),
  appointments('OPD Appointments', Icons.calendar_month_rounded),
  beds('Ward & Beds', Icons.meeting_room_rounded),
  invoices('Billing & Invoices', Icons.receipt_long_rounded),
  analytics('Clinic Analytics', Icons.insights_rounded);

  const ReceptionistTab(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Front desk console — real patient registry, OPD scheduling, ward/bed
/// status, billing and analytics. Mirrors the web receptionist dashboard.
class ReceptionistDashboardPage extends StatefulWidget {
  const ReceptionistDashboardPage({super.key});

  @override
  State<ReceptionistDashboardPage> createState() =>
      _ReceptionistDashboardPageState();
}

class _ReceptionistDashboardPageState extends State<ReceptionistDashboardPage> {
  ReceptionistTab _current = ReceptionistTab.registry;
  bool _loading = true;

  List<PatientRecord> _patients = const [];
  List<Appointment> _appointments = const [];
  List<Bed> _beds = const [];
  List<Invoice> _invoices = const [];
  DashboardStats _stats = const DashboardStats();

  late final String _userName;
  late final String _userEmail;

  @override
  void initState() {
    super.initState();
    final user = AuthRepository.cachedUser;
    _userName = (user?['user_name'] ?? user?['name'] ?? 'Receptionist') as String;
    _userEmail = (user?['email'] ?? 'frontdesk@aura.care') as String;
    _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      final results = await Future.wait([
        ReceptionistRepository.listPatients(),
        ReceptionistRepository.listAppointments(),
        ReceptionistRepository.listBeds(),
        ReceptionistRepository.listInvoices(),
        ReceptionistRepository.getDashboard(),
      ]);
      if (!mounted) return;
      setState(() {
        _patients = results[0] as List<PatientRecord>;
        _appointments = results[1] as List<Appointment>;
        _beds = results[2] as List<Bed>;
        _invoices = results[3] as List<Invoice>;
        _stats = results[4] as DashboardStats;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showAdminToast(context, 'Failed to load receptionist data: $e');
    }
  }

  // ---- Patients ---------------------------------------------------------

  Future<bool> _registerPatient(Map<String, dynamic> payload) async {
    try {
      final created = await ReceptionistRepository.createPatient(payload);
      if (mounted) setState(() => _patients = [..._patients, created]);
      return true;
    } catch (e) {
      if (mounted) showAdminToast(context, 'Failed to register patient: $e');
      return false;
    }
  }

  // ---- Appointments ------------------------------------------------------

  Future<bool> _bookAppointment(Map<String, dynamic> payload) async {
    try {
      final created = await ReceptionistRepository.bookAppointment(payload);
      if (mounted) setState(() => _appointments = [..._appointments, created]);
      return true;
    } catch (e) {
      if (mounted) showAdminToast(context, 'Failed to book appointment: $e');
      return false;
    }
  }

  Future<void> _updateAppointment(
      Appointment appt, Map<String, dynamic> payload) async {
    try {
      final updated =
          await ReceptionistRepository.updateAppointment(appt.id, payload);
      if (!mounted) return;
      setState(() {
        _appointments = [
          for (final a in _appointments)
            if (a.id == updated.id) updated else a,
        ];
      });
    } catch (e) {
      if (mounted) showAdminToast(context, 'Failed to update appointment: $e');
    }
  }

  Future<void> _deleteAppointment(Appointment appt) async {
    final ok = await showAdminConfirm(context,
        title: 'Delete appointment?',
        message:
            'Cancel ${appt.patientName}\'s appointment with ${appt.doctorName}?',
        confirmLabel: 'Delete');
    if (!ok || !mounted) return;
    try {
      await ReceptionistRepository.deleteAppointment(appt.id);
      if (mounted) {
        setState(() =>
            _appointments = _appointments.where((a) => a.id != appt.id).toList());
      }
    } catch (e) {
      if (mounted) showAdminToast(context, 'Failed to delete appointment: $e');
    }
  }

  // ---- Beds ---------------------------------------------------------------

  Future<void> _updateBed(Bed bed, Map<String, dynamic> payload) async {
    try {
      final updated = await ReceptionistRepository.updateBedStatus(bed.id, payload);
      if (!mounted) return;
      setState(() {
        _beds = [for (final b in _beds) if (b.id == updated.id) updated else b];
      });
    } catch (e) {
      if (mounted) showAdminToast(context, 'Failed to update bed: $e');
    }
  }

  // ---- Invoices -----------------------------------------------------------

  Future<bool> _createInvoice(Map<String, dynamic> payload) async {
    try {
      final created = await ReceptionistRepository.createInvoice(payload);
      if (mounted) setState(() => _invoices = [..._invoices, created]);
      return true;
    } catch (e) {
      if (mounted) showAdminToast(context, 'Failed to create invoice: $e');
      return false;
    }
  }

  Future<void> _markInvoicePaid(Invoice invoice) async {
    try {
      final updated = await ReceptionistRepository.updateInvoice(invoice.id, {
        'payment_status': 'PAID',
      });
      if (!mounted) return;
      setState(() {
        _invoices = [
          for (final i in _invoices) if (i.id == updated.id) updated else i,
        ];
      });
    } catch (e) {
      if (mounted) showAdminToast(context, 'Failed to mark invoice paid: $e');
    }
  }

  // ---- Sign out -----------------------------------------------------------

  Future<void> _signOut() async {
    final ok = await showAdminConfirm(
      context,
      title: 'Sign out of Front Desk?',
      message: 'You will be returned to the login screen.',
      confirmLabel: 'Sign Out',
      danger: false,
    );
    if (!ok || !mounted) return;
    await AuthRepository.clearSession();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PanelScaffold(
      sectionLabel: 'Front Desk',
      tabs: [
        for (final t in ReceptionistTab.values) PanelTab(t.label, t.icon),
      ],
      current: _current.index,
      userName: _userName,
      userEmail: _userEmail,
      roleLabel: 'Receptionist',
      onSelect: (i) => setState(() => _current = ReceptionistTab.values[i]),
      onSignOut: _signOut,
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AdminColors.emerald600),
      );
    }
    return _tabFor(_current);
  }

  Widget _tabFor(ReceptionistTab tab) {
    switch (tab) {
      case ReceptionistTab.registry:
        return RegistryTab(
          patients: _patients,
          onAdd: _registerPatient,
        );
      case ReceptionistTab.appointments:
        return AppointmentsTab(
          appointments: _appointments,
          onAdd: _bookAppointment,
          onUpdate: _updateAppointment,
          onDelete: _deleteAppointment,
        );
      case ReceptionistTab.beds:
        return BedsTab(
          beds: _beds,
          onUpdate: _updateBed,
        );
      case ReceptionistTab.invoices:
        return InvoicesTab(
          invoices: _invoices,
          onCreate: _createInvoice,
          onMarkPaid: _markInvoicePaid,
        );
      case ReceptionistTab.analytics:
        return AnalyticsTab(
          stats: _stats,
          appointments: _appointments,
          beds: _beds,
        );
    }
  }
}