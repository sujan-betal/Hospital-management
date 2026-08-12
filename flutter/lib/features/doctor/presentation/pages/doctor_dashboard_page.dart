import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../data/doctor_models.dart';
import '../doctor_colors.dart';
import '../tabs/consultations_tab.dart';
import '../tabs/earnings_tab.dart';
import '../tabs/lab_orders_tab.dart';
import '../tabs/prescriptions_tab.dart';
import '../tabs/schedule_tab.dart';
import '../widgets/doctor_modals.dart';
import '../widgets/doctor_navbar.dart';
import '../widgets/doctor_sidebar.dart';

/// Doctor Clinical Console — ports `frontend/src/app/(dashboard)/doctor/page.tsx`.
class DoctorDashboardPage extends StatefulWidget {
  const DoctorDashboardPage({super.key});

  @override
  State<DoctorDashboardPage> createState() => _DoctorDashboardPageState();
}

class _DoctorDashboardPageState extends State<DoctorDashboardPage> {
  DoctorTab _current = DoctorTab.schedule;

  late final String _userName;
  late final String _userRole;

  // ── Mock clinical data (mirrors the web page's useState seeds) ─────────
  List<DoctorAppointment> _appointments = [
    const DoctorAppointment(
        id: 'APT-101', patientName: 'Robert Downey Jr.', age: 55, gender: 'Male',
        time: '09:30 AM', type: 'Follow-up',
        symptoms: 'Recovering from hypertension, BP follow-up', status: 'waiting'),
    const DoctorAppointment(
        id: 'APT-102', patientName: 'Emma Watson', age: 32, gender: 'Female',
        time: '10:15 AM', type: 'Consultation',
        symptoms: 'Chronic headaches, fatigue', status: 'in-consultation'),
    const DoctorAppointment(
        id: 'APT-103', patientName: 'Liam Neeson', age: 68, gender: 'Male',
        time: '11:00 AM', type: 'Emergency',
        symptoms: 'Shortness of breath, chest pressure', status: 'waiting'),
    const DoctorAppointment(
        id: 'APT-104', patientName: 'Scarlett Johansson', age: 36, gender: 'Female',
        time: '11:45 AM', type: 'Consultation',
        symptoms: 'Routine antenatal check-up', status: 'waiting'),
    const DoctorAppointment(
        id: 'APT-105', patientName: 'Tommy Watson', age: 8, gender: 'Male',
        time: '12:30 PM', type: 'Follow-up',
        symptoms: 'Allergic bronchitis review', status: 'completed'),
  ];

  List<DoctorPrescription> _prescriptions = [
    const DoctorPrescription(
      id: 'PRX-501', patientName: 'Tommy Watson', date: '2026-07-20',
      medicines: [
        DoctorMedicine(name: 'Montelukast 5mg', dosage: '1 tablet daily at night', duration: '10 Days'),
        DoctorMedicine(name: 'Levosalbutamol Inhaler', dosage: '2 puffs twice daily', duration: '1 Month'),
      ],
      notes: 'Avoid cold items and potential allergen triggers.',
    ),
    const DoctorPrescription(
      id: 'PRX-502', patientName: 'Robert Downey Jr.', date: '2026-07-19',
      medicines: [
        DoctorMedicine(name: 'Amlodipine 5mg', dosage: '1 tablet in morning', duration: '3 Months'),
        DoctorMedicine(name: 'Atorvastatin 10mg', dosage: '1 tablet after dinner', duration: '3 Months'),
      ],
      notes: 'Strict low-sodium diet recommended. Track daily BP.',
    ),
  ];

  List<DoctorLabOrder> _labOrders = [
    const DoctorLabOrder(
      id: 'LAB-801', patientName: 'Emma Watson',
      testType: 'Complete Blood Count (CBC) & Serum Glucose',
      status: 'completed', priority: 'urgent',
      results: 'Hb 12.8 g/dL (Normal), RBC 4.2 M/uL, Glucose 98 mg/dL',
      abnormalFlag: false),
    const DoctorLabOrder(
      id: 'LAB-802', patientName: 'Liam Neeson',
      testType: 'Cardiac Troponin & ECG Telemetry Review',
      status: 'processing', priority: 'stat'),
    const DoctorLabOrder(
      id: 'LAB-803', patientName: 'Robert Downey Jr.',
      testType: 'Lipid Profile & Kidney Function Test',
      status: 'pending', priority: 'routine'),
  ];

  List<DoctorConsultation> _consultations = [
    const DoctorConsultation(
      id: 'CON-301', patientName: 'Robert Downey Jr.', date: '2026-07-17',
      diagnosis: 'Essential Hypertension',
      treatmentPlan: 'Statins & Vasodilators initiation',
      notes: 'Patient reported mild vertigo when starting dosage. Adjusted Amlodipine timing.'),
    const DoctorConsultation(
      id: 'CON-302', patientName: 'Tommy Watson', date: '2026-07-16',
      diagnosis: 'Allergic Bronchitis',
      treatmentPlan: 'Inhaled bronchodilator therapy',
      notes: 'Nebulizer administered in clinic. Pulse ox 97% post therapy.'),
  ];

  List<String> get _patientNames =>
      _appointments.map((a) => a.patientName).toSet().toList();

  static final _rng = Random();

  @override
  void initState() {
    super.initState();
    final user = AuthRepository.cachedUser;
    _userName = (user?['user_name'] ?? user?['name'] ?? 'Dr. House') as String;
    _userRole = (user?['specialty'] ?? 'General Medicine Specialist') as String;
  }

  // ── Status updates ─────────────────────────────────────────────────────

  void _updateStatus(String id, String status) {
    setState(() {
      _appointments = [
        for (final a in _appointments)
          if (a.id == id) a.copyWith(status: status) else a,
      ];
    });
  }

  // ── Modals ─────────────────────────────────────────────────────────────

  void _openPrescription({String patient = ''}) {
    showDoctorModal<void>(
      context: context,
      title: 'Write Medical Prescription',
      icon: Icons.description_rounded,
      child: PrescriptionModalBody(
        patients: _patientNames,
        initialPatient: patient,
        onSave: (p, meds, notes) {
          Navigator.of(context).pop();
          setState(() {
            _prescriptions = [
              DoctorPrescription(
                id: 'PRX-${_rng.nextInt(500) + 500}',
                patientName: p,
                date: _today(),
                medicines: meds,
                notes: notes,
              ),
              ..._prescriptions,
            ];
          });
        },
      ),
    );
  }

  void _openLab({String patient = ''}) {
    showDoctorModal<void>(
      context: context,
      title: 'Request Lab & Diagnostics',
      icon: Icons.science_rounded,
      child: LabModalBody(
        patients: _patientNames,
        initialPatient: patient,
        onSave: (p, testType, priority) {
          Navigator.of(context).pop();
          setState(() {
            _labOrders = [
              DoctorLabOrder(
                id: 'LAB-${_rng.nextInt(200) + 800}',
                patientName: p,
                testType: testType,
                status: 'pending',
                priority: priority,
              ),
              ..._labOrders,
            ];
          });
        },
      ),
    );
  }

  void _openConsultation({String patient = ''}) {
    showDoctorModal<void>(
      context: context,
      title: 'Start Diagnosis Notes',
      icon: Icons.medical_services_rounded,
      child: ConsultationModalBody(
        patients: _patientNames,
        initialPatient: patient,
        onSave: (p, diagnosis, treatment, notes) {
          Navigator.of(context).pop();
          setState(() {
            _consultations = [
              DoctorConsultation(
                id: 'CON-${_rng.nextInt(200) + 300}',
                patientName: p,
                date: _today(),
                diagnosis: diagnosis,
                treatmentPlan: treatment,
                notes: notes,
              ),
              ..._consultations,
            ];
          });
        },
      ),
    );
  }

  static String _today() {
    final n = DateTime.now();
    final m = n.month.toString().padLeft(2, '0');
    final d = n.day.toString().padLeft(2, '0');
    return '${n.year}-$m-$d';
  }

  // ── Sign out ───────────────────────────────────────────────────────────

  Future<void> _signOut() async {
    await AuthRepository.clearSession();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────

  String get _tabTitle => switch (_current) {
        DoctorTab.schedule => 'Clinical Appointments',
        DoctorTab.prescriptions => 'Prescription Pad',
        DoctorTab.labOrders => 'Laboratory Orders & Diagnostics',
        DoctorTab.consultations => 'Specialist Consultations',
        DoctorTab.earnings => 'Earnings & Payout',
      };

  String get _tabSubtitle =>
      'Welcome back, ${_displayName}. Medical console fully sync\'d.';

  String get _displayName {
    final parts = _userName.split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return 'Doctor';
    if (parts.first.toLowerCase().startsWith('dr')) return _userName;
    return 'Dr. $parts.first';
  }

  @override
  Widget build(BuildContext context) {
    final sidebar = DoctorSidebar(
      current: _current,
      userName: _displayName,
      userRole: _userRole,
      onSelect: (tab) => setState(() => _current = tab),
      onSignOut: _signOut,
    );

    final navbar = DoctorNavbar(title: _tabTitle, subtitle: _tabSubtitle);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 960;
        final body = Scaffold(
          backgroundColor: DoctorColors.canvas,
          body: Row(
            children: [
              if (isDesktop) ...[sidebar, const VerticalDivider(width: 0)],
              Expanded(
                child: Column(
                  children: [
                    navbar,
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1400),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: KeyedSubtree(
                                key: ValueKey(_current),
                                child: _tabFor(_current),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

        if (isDesktop) return body;

        final scaffoldKey = GlobalKey<ScaffoldState>();
        return Scaffold(
          key: scaffoldKey,
          backgroundColor: DoctorColors.canvas,
          appBar: AppBar(
            backgroundColor: DoctorColors.surface,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => scaffoldKey.currentState?.openDrawer(),
            ),
            title: Text(_tabTitle,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
          ),
          drawer: SizedBox(width: 272, child: sidebar),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _tabFor(_current),
          ),
        );
      },
    );
  }

  Widget _tabFor(DoctorTab tab) {
    switch (tab) {
      case DoctorTab.schedule:
        return ScheduleTab(
          appointments: _appointments,
          onUpdateStatus: _updateStatus,
          onLogConsultation: () => _openConsultation(),
          onRx: (a) => _openPrescription(patient: a.patientName),
          onLab: (a) => _openLab(patient: a.patientName),
        );
      case DoctorTab.prescriptions:
        return PrescriptionsTab(
          prescriptions: _prescriptions,
          onNew: () => _openPrescription(),
        );
      case DoctorTab.labOrders:
        return LabOrdersTab(
          orders: _labOrders,
          onNew: () => _openLab(),
        );
      case DoctorTab.consultations:
        return ConsultationsTab(
          consultations: _consultations,
          onNew: () => _openConsultation(),
        );
      case DoctorTab.earnings:
        return const EarningsTab();
    }
  }
}
