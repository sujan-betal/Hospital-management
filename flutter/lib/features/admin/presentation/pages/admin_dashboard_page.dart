import 'package:flutter/material.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../data/admin_models.dart';
import '../../data/admin_repository.dart';
import '../admin_colors.dart';
import '../tabs/attending_doctors_tab.dart';
import '../tabs/clinical_tasks_tab.dart';
import '../tabs/hospital_settings_tab.dart';
import '../tabs/overview_tab.dart';
import '../tabs/patient_admissions_tab.dart';
import '../tabs/payments_tab.dart';
import '../tabs/staff_credentials_tab.dart';
import '../tabs/wards_beds_tab.dart';
import '../widgets/admin_common.dart';
import '../widgets/admin_navbar.dart';
import '../widgets/admin_sidebar.dart';

enum _LoadStage { loading, ready }

/// Chief Officer Console — fixed sidebar + top navbar + tabbed content.
/// Ports the web admin `page.tsx` shell.
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  AdminTab _current = AdminTab.overview;
  _LoadStage _stage = _LoadStage.loading;

  List<Bed> _beds = const [];
  List<Admission> _admissions = const [];
  List<MedicalTask> _tasks = const [];
  List<StaffCredential> _staff = const [];
  HospitalSettings _settings =
      HospitalSettings.fromJson(const <String, dynamic>{});

  int _admissionSignal = 0;
  int _taskSignal = 0;

  late final String _userName;
  late final String _userEmail;

  @override
  void initState() {
    super.initState();
    final user = AuthRepository.cachedUser;
    _userName = (user?['user_name'] ?? user?['name'] ?? 'Admin') as String;
    _userEmail = (user?['email'] ?? 'admin@aura.care') as String;
    _loadAll();
  }

  Future<T> _fetchOr<T>(Future<T> Function() run, T fallback) async {
    try {
      return await run();
    } catch (_) {
      return fallback;
    }
  }

  Future<void> _loadAll() async {
    final bedsF = _fetchOr(AdminRepository.listBeds, initialBeds);
    final admF = _fetchOr(AdminRepository.listAdmissions, initialAdmissions);
    final tasksF = _fetchOr(AdminRepository.listTasks, initialMedicalTasks);
    final settingsF =
        _fetchOr(AdminRepository.getSettings, HospitalSettings.fromJson(const {}));
    final staffF = _fetchOr(AdminRepository.listStaff, initialStaffCredentials);

    final beds = await bedsF;
    final admissions = await admF;
    final tasks = await tasksF;
    final settings = await settingsF;
    final staff = await staffF;

    if (!mounted) return;
    setState(() {
      _beds = beds;
      _admissions = admissions;
      _tasks = tasks;
      _settings = settings;
      _staff = staff;
      _stage = _LoadStage.ready;
    });
  }

  // ---- CRUD: beds -------------------------------------------------------

  Future<bool> _addBed(Bed bed) async {
    try {
      final created = await AdminRepository.createBed(bed);
      if (mounted) setState(() => _beds = [..._beds, created]);
      return true;
    } catch (e) {
      if (mounted) showAdminToast(context, 'Failed to add bed: $e');
      return false;
    }
  }

  Future<void> _updateBed(Bed bed) async {
    try {
      final updated = await AdminRepository.updateBed(bed);
      if (!mounted) return;
      setState(() {
        _beds = [for (final b in _beds) if (b.id == updated.id) updated else b];
      });
    } catch (e) {
      if (mounted) showAdminToast(context, 'Failed to update bed: $e');
    }
  }

  Future<bool> _deleteBed(String bedId) async {
    try {
      await AdminRepository.deleteBed(bedId);
      if (mounted) setState(() => _beds = _beds.where((b) => b.id != bedId).toList());
      return true;
    } catch (e) {
      if (mounted) showAdminToast(context, 'Failed to delete bed: $e');
      return false;
    }
  }

  // ---- CRUD: admissions --------------------------------------------------

  Map<String, dynamic> _admissionPayload(Admission a) => {
        'patient_name': a.patientName,
        'patient_age': a.patientAge,
        'patient_gender': a.patientGender.toUpperCase(),
        'ward_type': a.wardType,
        'bed_id': a.bedId.isEmpty ? 'Pending' : a.bedId,
        'admit_date': a.admitDate,
        'discharge_date': a.dischargeDate,
        'billing_amount': a.billingAmount,
        'status': a.status.name.toUpperCase(),
        'insurance_status': a.insuranceStatus.name.toUpperCase(),
        'patient_email': a.patientEmail,
        'patient_phone': a.patientPhone,
      };

  void _occupyBed(String bedId, String patient) {
    if (bedId.isEmpty || bedId == 'Pending') return;
    setState(() {
      _beds = [
        for (final b in _beds)
          if (b.id == bedId)
            b.copyWith(
              status: BedStatus.occupied,
              patient: patient.isEmpty ? b.patient : patient,
            )
          else
            b,
      ];
    });
  }

  void _freeBed(String bedId) {
    if (bedId.isEmpty || bedId == 'Pending') return;
    setState(() {
      _beds = [
        for (final b in _beds)
          if (b.id == bedId)
            b.copyWith(status: BedStatus.sanitizing, patient: '')
          else
            b,
      ];
    });
  }

  void _addAdmission(Admission a) {
    final payload = _admissionPayload(a);
    _occupyBed(a.bedId, a.patientName);
    setState(() => _admissions = [..._admissions, a]);
    AdminRepository.createAdmission(payload).catchError((Object e) {
      if (mounted) showAdminToast(context, 'Failed to create admission: $e');
      return null;
    });
  }

  void _updateAdmission(Admission a) {
    final previous = _admissions.where((x) => x.id == a.id).firstOrNull;
    if (previous != null &&
        previous.bedId != a.bedId &&
        previous.bedId.isNotEmpty &&
        previous.bedId != 'Pending') {
      _freeBed(previous.bedId);
    }
    if (a.status == AdmissionStatus.discharged ||
        a.status == AdmissionStatus.cancelled) {
      _freeBed(a.bedId);
    } else if (a.bedId.isNotEmpty && a.bedId != 'Pending') {
      _occupyBed(a.bedId, a.patientName);
    }
    setState(() {
      _admissions = [
        for (final x in _admissions) if (x.id == a.id) a else x,
      ];
    });
    AdminRepository.updateAdmission(a.id, _admissionPayload(a))
        .catchError((Object e) {
      if (mounted) showAdminToast(context, 'Failed to update admission: $e');
      return null;
    });
  }

  // ---- CRUD: tasks --------------------------------------------------------

  Map<String, dynamic> _taskPayload(MedicalTask t) => {
        'bed_id': t.bedId,
        'task_description': t.task,
        'priority': t.priority.name.toUpperCase(),
        'assigned_to': t.assignedTo,
        'status': t.status.name.substring(0, 1).toUpperCase() +
            t.status.name.substring(1),
        'task_type': _taskTypeApi(t.type),
        'timestamp': t.timestamp,
      };

  String _taskTypeApi(TaskType t) => switch (t) {
        TaskType.labTest => 'LAB_TEST',
        TaskType.pharmacy => 'PHARMACY',
        TaskType.sanitization => 'SANITIZATION',
        TaskType.nursing => 'NURSING',
      };

  void _addTask(MedicalTask t) {
    setState(() => _tasks = [..._tasks, t]);
    AdminRepository.createTask(_taskPayload(t)).catchError((Object e) {
      if (mounted) showAdminToast(context, 'Failed to create task: $e');
      return null;
    });
  }

  void _updateTask(MedicalTask t) {
    setState(() => _tasks = [for (final x in _tasks) if (x.id == t.id) t else x]);
    AdminRepository.updateTask(t.id, _taskPayload(t)).catchError((Object e) {
      if (mounted) showAdminToast(context, 'Failed to update task: $e');
      return null;
    });
  }

  // ---- CRUD: staff --------------------------------------------------------

  void _addStaff(StaffCredential c) {
    setState(() => _staff = [..._staff, c]);
  }

  void _updateStaff(StaffCredential c) {
    setState(() => _staff = [for (final x in _staff) if (x.id == c.id) c else x]);
  }

  void _deleteStaff(String id) {
    setState(() => _staff = _staff.where((x) => x.id != id).toList());
  }

  // ---- Settings -----------------------------------------------------------

  Future<HospitalSettings> _saveSettings(Map<String, dynamic> payload) async {
    final updated = await AdminRepository.updateSettings(payload);
    if (mounted) setState(() => _settings = updated);
    return updated;
  }

  Future<void> _updateSettings(Map<String, dynamic> payload) async {
    final updated = await AdminRepository.updateSettings(payload);
    if (mounted) setState(() => _settings = updated);
  }

  // ---- Sign out -----------------------------------------------------------

  Future<void> _signOut() async {
    final ok = await showAdminConfirm(
      context,
      title: 'Sign out of Admin Console?',
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

  void _openAdmission() => setState(() {
      _current = AdminTab.admissions;
      _admissionSignal++;
    });

  void _openTask() => setState(() {
        _current = AdminTab.tasks;
        _taskSignal++;
      });

  @override
  Widget build(BuildContext context) {
    if (_stage == _LoadStage.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AdminColors.emerald500)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 960;
        final sidebar = AdminSidebar(
          current: _current,
          userName: _userName,
          userEmail: _userEmail,
          onSelect: (tab) => setState(() => _current = tab),
          onSignOut: _signOut,
        );

        final content = AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: KeyedSubtree(
            key: ValueKey(_current),
            child: _tabFor(_current),
          ),
        );

        if (!isDesktop) {
          final scaffoldKey = GlobalKey<ScaffoldState>();
          return Scaffold(
            key: scaffoldKey,
            drawer: SafeArea(
              child: SizedBox(width: 260, child: sidebar),
            ),
            body: Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: AdminNavbar(
                    title: _current.label,
                    userName: _userName,
                    userEmail: _userEmail,
                    onSignOut: _signOut,
                    onMenuTap: () => scaffoldKey.currentState?.openDrawer(),
                  ),
                ),
                Expanded(
                  child: Container(
                    color: AdminColors.canvas,
                    padding: const EdgeInsets.all(14),
                    child: content,
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: AdminColors.canvas,
          body: Row(
            children: [
              sidebar,
              Expanded(
                child: Column(
                  children: [
                    SafeArea(
                      bottom: false,
                      child: AdminNavbar(
                        title: _current.label,
                        userName: _userName,
                        userEmail: _userEmail,
                        onSignOut: _signOut,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        color: AdminColors.canvas,
                        padding: const EdgeInsets.all(22),
                        child: content,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tabFor(AdminTab tab) {
    switch (tab) {
      case AdminTab.beds:
        return WardsAndBedsTab(
          beds: _beds,
          loading: _stage == _LoadStage.loading,
          onAdd: _addBed,
          onUpdate: _updateBed,
          onDelete: _deleteBed,
        );
      case AdminTab.admissions:
        return PatientAdmissionsTab(
          admissions: _admissions,
          rooms: _beds,
          onAdd: _addAdmission,
          onUpdate: _updateAdmission,
          openCreateSignal: _admissionSignal,
        );
      case AdminTab.doctors:
        return AttendingDoctorsTab(doctors: initialDoctors);
      case AdminTab.tasks:
        return ClinicalTasksTab(
          tasks: _tasks,
          onAdd: _addTask,
          onUpdate: _updateTask,
          openCreateSignal: _taskSignal,
        );
      case AdminTab.staff:
        return StaffCredentialsTab(
          credentials: _staff,
          onAdd: _addStaff,
          onUpdate: _updateStaff,
          onDelete: _deleteStaff,
        );
      case AdminTab.settings:
        return HospitalSettingsTab(
          settings: _settings,
          onSave: _saveSettings,
        );
      case AdminTab.payments:
        return PaymentsTab(
          settings: _settings,
          onUpdateSettings: _updateSettings,
        );
      case AdminTab.overview:
        return OverviewTab(
          beds: _beds,
          admissions: _admissions,
          tasks: _tasks,
          onNavigate: (tab) => setState(() => _current = tab),
          onAddAdmission: _openAdmission,
          onAddTask: _openTask,
        );
    }
  }
}