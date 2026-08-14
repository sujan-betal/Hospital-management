import 'package:flutter/material.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../data/patient_models.dart';
import '../../data/patient_repository.dart';
import '../patient_colors.dart';
import '../tabs/book_tab.dart';
import '../tabs/profile_tab.dart';
import '../tabs/records_tab.dart';
import '../widgets/patient_common.dart';
import '../widgets/patient_modals.dart';
import '../widgets/patient_navbar.dart';
import '../widgets/patient_sidebar.dart';

/// Patient Self-Service Portal — ports
/// `frontend/src/app/(dashboard)/patient/page.tsx`.
class PatientDashboardPage extends StatefulWidget {
  const PatientDashboardPage({super.key});

  @override
  State<PatientDashboardPage> createState() => _PatientDashboardPageState();
}

class _PatientDashboardPageState extends State<PatientDashboardPage> {
  PatientTab _current = PatientTab.records;

  late final String _userName;
  late final String _userPhone;
  late final String _today;

  PatientProfile _profile = const PatientProfile();
  List<PatientAppointment> _appointments = const [];
  List<PatientInvoice> _invoices = const [];
  List<PatientDoctor> _doctors = const [];
  List<PatientReview> _reviews = const [];
  List<PatientBookedSlot> _bookedSlots = const [];

  bool _loadingRecords = true;
  bool _booking = false;
  bool _savingEdit = false;
  bool _savingProfile = false;
  bool _reviewing = false;
  String? _payingAppointmentId;

  String _selectedSpecialty = 'All Specialties';
  bool _sortByName = false;

  @override
  void initState() {
    super.initState();
    final user = AuthRepository.cachedUser;
    _userName = (user?['user_name'] ?? user?['name'] ?? '') as String;
    _userPhone = (user?['phone'] ?? '') as String;
    _today = _dateOnly(DateTime.now());
    _loadProfile();
    _loadRecords();
    _loadDoctors();
    _loadBookedSlots();
  }

  static String _dateOnly(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String get _displayName =>
      _profile.fullName.trim().isEmpty ? _userName : _profile.fullName;

  String get _displayPhone =>
      _profile.phone.trim().isEmpty ? _userPhone : _profile.phone;

  String get _tabTitle => switch (_current) {
        PatientTab.records => 'My Appointments & Bills',
        PatientTab.book => 'Schedule Care Appointment',
        PatientTab.profile => 'Patient Registration Details',
      };

  // ── Loaders ────────────────────────────────────────────────────────────

  Future<void> _loadProfile() async {
    try {
      final p = await PatientRepository.getProfile();
      if (mounted) {
        setState(() {
          _profile = PatientProfile(
            fullName: p.fullName.isEmpty ? _userName : p.fullName,
            age: p.age,
            gender: p.gender,
            phone: p.phone.isEmpty ? _userPhone : p.phone,
            email: p.email,
            insuranceProvider: p.insuranceProvider,
          );
        });
      }
    } catch (_) {
      // No token or API offline: keep the cached session values.
    }
  }

  Future<void> _loadRecords() async {
    setState(() => _loadingRecords = true);
    try {
      final results = await Future.wait([
        PatientRepository.getAppointments(),
        PatientRepository.getInvoices(),
        PatientRepository.getReviews(),
      ]);
      if (!mounted) return;
      setState(() {
        _appointments = results[0] as List<PatientAppointment>;
        _invoices = results[1] as List<PatientInvoice>;
        _reviews = results[2] as List<PatientReview>;
        _loadingRecords = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _appointments = const [];
          _invoices = const [];
          _reviews = const [];
          _loadingRecords = false;
        });
      }
    }
  }

  Future<void> _loadDoctors() async {
    try {
      final docs = await PatientRepository.getDoctors();
      if (mounted) setState(() => _doctors = docs);
    } catch (_) {
      // Keep whatever we have.
    }
  }

  Future<void> _loadBookedSlots() async {
    try {
      final slots = await PatientRepository.getBookedSlots(_today);
      if (mounted) setState(() => _bookedSlots = slots);
    } catch (_) {
      // Keep whatever we have.
    }
  }

  Set<String> _bookedTimesFor(String doctorName) {
    final s = <String>{};
    for (final b in _bookedSlots) {
      if (b.doctorName == doctorName) s.add(b.time);
    }
    for (final a in _appointments) {
      if (a.date == _today &&
          a.status.toUpperCase() != 'CANCELLED' &&
          a.doctorName == doctorName) {
        s.add(a.time);
      }
    }
    return s;
  }

  Set<String> get _reviewedAppointmentIds =>
      _reviews.map((r) => r.appointmentId).toSet();

  // ── Actions ────────────────────────────────────────────────────────────

  Future<void> _bookSlot(PatientDoctor doc, String slot) async {
    setState(() => _booking = true);
    try {
      final created = await PatientRepository.bookAppointment(
        doctorName: doc.name,
        specialty: doc.specialty.isEmpty ? 'General Medicine' : doc.specialty,
        date: _today,
        time: slot,
      );
      if (!mounted) return;
      setState(() => _appointments = [created, ..._appointments]);
      showPatientToast(context,
          'Booking successful! Your consultation with ${doc.name} is confirmed for $slot today.');
      _loadBookedSlots();
    } catch (e) {
      if (mounted) {
        showPatientToast(context,
            e.toString().contains('already')
                ? 'That slot was just booked. Please pick another.'
                : 'Could not book the appointment. Please try again.',
            error: true);
      }
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  void _openReschedule(PatientAppointment appt) {
    showPatientModal<void>(
      context: context,
      title: 'Reschedule Appointment',
      subtitle: appt.doctorName,
      icon: Icons.event_repeat_rounded,
      iconBg: PatientColors.emeraldSoft,
      iconColor: PatientColors.emeraldDark,
      child: RescheduleModalBody(
        doctorName: appt.doctorName,
        initialDate: appt.date,
        initialTime: appt.time,
        today: _today,
        bookedTimes: _bookedTimesFor(appt.doctorName),
        saving: _savingEdit,
        onSave: (date, time) async {
          setState(() => _savingEdit = true);
          try {
            final updated =
                await PatientRepository.updateAppointment(appt.appointmentId,
                    date: date, time: time);
            if (!mounted) return false;
            setState(() {
              _appointments = [
                for (final a in _appointments)
                  if (a.appointmentId == updated.appointmentId) updated else a,
              ];
              _savingEdit = false;
            });
            showPatientToast(context, 'Appointment rescheduled successfully!');
            _loadBookedSlots();
            return true;
          } catch (e) {
            if (mounted) {
              setState(() => _savingEdit = false);
              showPatientToast(context,
                  'Could not reschedule the appointment. Please try again.',
                  error: true);
            }
            return false;
          }
        },
      ),
    );
  }

  Future<void> _payNow(PatientAppointment appt) async {
    setState(() => _payingAppointmentId = appt.appointmentId);
    try {
      final order = await PatientRepository.createPaymentOrder(appt.appointmentId);
      if (!mounted) return;
      await showPatientModal<void>(
        context: context,
        title: 'Payment Order Created',
        subtitle: appt.doctorName,
        icon: Icons.account_balance_wallet_rounded,
        iconBg: PatientColors.blueSoft,
        iconColor: PatientColors.blue,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: PatientColors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: PatientColors.borderStrong),
              ),
              child: Column(
                children: [
                  _orderRow('Amount', 'Rs. ${order.amount.toInt()}'),
                  const SizedBox(height: 10),
                  _orderRow('Order ID', order.orderId),
                  const SizedBox(height: 10),
                  _orderRow('Currency', order.currency),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: PatientColors.amberSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: PatientColors.amberLine),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: PatientColors.amberText),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'The Razorpay checkout opens in the web patient portal to complete this payment. Your appointment stays confirmed either way.',
                      style: TextStyle(
                          color: PatientColors.amberText, fontSize: 11.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: PatientPrimaryButton(
                label: 'Done',
                icon: Icons.check_rounded,
                compact: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        showPatientToast(context,
            'Could not start payment. Please try again.',
            error: true);
      }
    } finally {
      if (mounted) setState(() => _payingAppointmentId = null);
    }
  }

  void _openReview(PatientAppointment appt) {
    showPatientModal<void>(
      context: context,
      title: 'Rate Your Doctor',
      subtitle: '${appt.doctorName}  ·  ${appt.specialty}',
      icon: Icons.star_rounded,
      iconBg: PatientColors.amberSoft,
      iconColor: PatientColors.amber,
      child: RateDoctorModalBody(
        doctorName: appt.doctorName,
        specialty: appt.specialty,
        submitting: _reviewing,
        onSubmit: (rating, comment) async {
          setState(() => _reviewing = true);
          try {
            final review = await PatientRepository.submitReview(
              appointmentId: appt.appointmentId,
              rating: rating,
              comment: comment,
            );
            if (!mounted) return false;
            setState(() => _reviews = [review, ..._reviews]);
            showPatientToast(context,
                'Thank you for rating Dr. ${appt.doctorName}!');
            return true;
          } catch (e) {
            if (mounted) {
              setState(() => _reviewing = false);
              showPatientToast(context,
                  'Could not submit your review. Please try again.',
                  error: true);
            }
            return false;
          }
        },
      ),
    );
  }

  Future<bool> _saveProfile(PatientProfile p) async {
    setState(() => _savingProfile = true);
    try {
      await PatientRepository.updateProfile(p);
      if (!mounted) return false;
      setState(() => _profile = p);
      showPatientToast(context, 'Your profile was saved to the hospital database.');
      return true;
    } catch (e) {
      if (mounted) {
        showPatientToast(context, 'Could not save changes. Please try again.',
            error: true);
      }
      return false;
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _signOut() async {
    final ok = await showPatientConfirm(
      context,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      confirmLabel: 'Yes, Logout',
      danger: true,
    );
    if (!ok || !mounted) return;
    await AuthRepository.clearSession();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sidebar = PatientSidebar(
      current: _current,
      userName: _displayName,
      userPhone: _displayPhone,
      onSelect: (tab) => setState(() => _current = tab),
      onSignOut: _signOut,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 960;
        final navbar = PatientNavbar(
          title: _tabTitle,
          subtitle: 'Welcome back, ${_displayName.isEmpty ? 'patient' : _displayName}.',
          phone: _displayPhone,
        );

        final body = Scaffold(
          backgroundColor: PatientColors.canvas,
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
                            constraints:
                                const BoxConstraints(maxWidth: 1400),
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
          backgroundColor: PatientColors.canvas,
          appBar: AppBar(
            backgroundColor: PatientColors.surface,
            foregroundColor: PatientColors.textStrong,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => scaffoldKey.currentState?.openDrawer(),
            ),
            title: Text(_tabTitle,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800)),
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

  Widget _tabFor(PatientTab tab) {
    switch (tab) {
      case PatientTab.records:
        return RecordsTab(
          appointments: _appointments,
          invoices: _invoices,
          loading: _loadingRecords,
          reviewedAppointmentIds: _reviewedAppointmentIds,
          payingAppointmentId: _payingAppointmentId,
          onBookNew: () => setState(() => _current = PatientTab.book),
          onEdit: _openReschedule,
          onPay: _payNow,
          onRate: _openReview,
        );
      case PatientTab.book:
        return BookTab(
          doctors: _doctors,
          selectedSpecialty: _selectedSpecialty,
          sortByName: _sortByName,
          booking: _booking,
          onSelectSpecialty: (sp) => setState(() => _selectedSpecialty = sp),
          onToggleSort: () => setState(() => _sortByName = !_sortByName),
          onBookSlot: _bookSlot,
          bookedTimesFor: _bookedTimesFor,
        );
      case PatientTab.profile:
        return ProfileTab(
          profile: _profile,
          saving: _savingProfile,
          onSave: _saveProfile,
        );
    }
  }
}

Widget _orderRow(String label, String value) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                color: PatientColors.textMuted, fontSize: 12)),
        Text(value,
            style: const TextStyle(
                color: PatientColors.textStrong,
                fontSize: 12,
                fontWeight: FontWeight.w800)),
      ],
    );
