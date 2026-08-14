import 'package:flutter/material.dart';

import '../../../../core/widgets/panel_scaffold.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../admin/presentation/admin_colors.dart';
import '../../../admin/presentation/widgets/admin_common.dart';
import '../../data/patient_models.dart';
import '../../data/patient_repository.dart';
import '../tabs/book_tab.dart';
import '../tabs/profile_tab.dart';
import '../tabs/records_tab.dart';

enum PatientTab {
  records('My Appointments & Bills', Icons.receipt_long_rounded),
  book('Book Appointment', Icons.event_available_rounded),
  profile('Profile Details', Icons.person_rounded);

  const PatientTab(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Patient portal — profile, appointments, billing and doctor bookings, all
/// backed by the `/api/patient/*` endpoints. Mirrors the web patient dashboard.
class PatientDashboardPage extends StatefulWidget {
  const PatientDashboardPage({super.key});

  @override
  State<PatientDashboardPage> createState() => _PatientDashboardPageState();
}

class _PatientDashboardPageState extends State<PatientDashboardPage> {
  PatientTab _current = PatientTab.records;
  bool _loading = true;

  PatientProfile _profile = const PatientProfile();
  List<PatientAppointment> _appointments = const [];
  List<PatientInvoice> _invoices = const [];
  List<PatientDoctor> _doctors = const [];
  List<PatientReview> _reviews = const [];
  List<BookedSlot> _bookedSlots = const [];

  late final String _userName;
  late final String _userEmail;

  static String get today {
    final now = DateTime.now();
    final local = DateTime(now.year, now.month, now.day);
    return local.toIso8601String().split('T').first;
  }

  @override
  void initState() {
    super.initState();
    final user = AuthRepository.cachedUser;
    _userName = (user?['user_name'] ?? user?['name'] ?? 'Patient') as String;
    _userEmail = (user?['email'] ?? '') as String;
    _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      final results = await Future.wait([
        PatientRepository.getProfile(),
        PatientRepository.listAppointments(),
        PatientRepository.listInvoices(),
        PatientRepository.listDoctors(),
        PatientRepository.listReviews(),
        PatientRepository.listBookedSlots(today),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = results[0] as PatientProfile;
        _appointments = results[1] as List<PatientAppointment>;
        _invoices = results[2] as List<PatientInvoice>;
        _doctors = results[3] as List<PatientDoctor>;
        _reviews = results[4] as List<PatientReview>;
        _bookedSlots = results[5] as List<BookedSlot>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showAdminToast(context, 'Failed to load patient data: $e');
    }
  }

  // ---- Profile ------------------------------------------------------------

  Future<void> _saveProfile(PatientProfile updated) async {
    try {
      final saved = await PatientRepository.updateProfile(updated.toUpdatePayload());
      if (!mounted) return;
      setState(() => _profile = saved);
      showAdminToast(context, 'Profile updated in the hospital database');
    } catch (e) {
      if (mounted) showAdminToast(context, 'Failed to save profile: $e');
      rethrow;
    }
  }

  // ---- Booking -------------------------------------------------------------

  Future<bool> _bookAppointment(PatientDoctor doctor, String slot) async {
    try {
      final created = await PatientRepository.bookAppointment({
        'doctor_name': doctor.name,
        'specialty': doctor.specialty,
        'date': today,
        'time': slot,
      });
      if (!mounted) return true;
      setState(() {
        _appointments = [created, ..._appointments];
        _bookedSlots = [..._bookedSlots, BookedSlot(doctorName: doctor.name, time: slot)];
      });
      return true;
    } catch (e) {
      if (mounted) showAdminToast(context, 'Failed to book appointment: $e');
      return false;
    }
  }

  Future<void> _refreshBookedSlots() async {
    try {
      final slots = await PatientRepository.listBookedSlots(today);
      if (!mounted) return;
      setState(() => _bookedSlots = slots);
    } catch (_) {}
  }

  // ---- Reschedule ----------------------------------------------------------

  Future<void> _reschedule(
      PatientAppointment appt, String date, String time) async {
    try {
      final updated =
          await PatientRepository.updateAppointment(appt.appointmentId, {
        'date': date,
        'time': time,
      });
      if (!mounted) return;
      setState(() {
        _appointments = [
          for (final a in _appointments)
            if (a.appointmentId == updated.appointmentId) updated else a,
        ];
      });
      _refreshBookedSlots();
      showAdminToast(context, 'Appointment rescheduled successfully');
    } catch (e) {
      if (mounted) showAdminToast(context, 'Failed to reschedule: $e');
    }
  }

  // ---- Payment ---------------------------------------------------------------

  Future<void> _payNow(PatientAppointment appt) async {
    try {
      final order = await PatientRepository.createPaymentOrder(appt.appointmentId);
      if (!mounted) return;
      await showAdminModal<void>(
        context,
        title: 'Consultation Fee Payment',
        subtitle: 'Razorpay order created for ${appt.doctorName}',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _orderRow('Order ID', order.orderId),
            const SizedBox(height: 10),
            _orderRow('Appointment', appt.appointmentId),
            const SizedBox(height: 10),
            _orderRow('Amount', 'Rs. ${order.amount} ${order.currency}'),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AdminColors.bgSubtle,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Complete the payment in the Razorpay checkout (opens in your browser). '
                'Once verified, the fee status updates automatically.',
                style: TextStyle(fontSize: 12, color: AdminColors.emerald600),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) showAdminToast(context, 'Could not start payment: $e');
    }
  }

  Widget _orderRow(String label, String value) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AdminColors.emerald600)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0B2B26))),
          ),
        ],
      );

  // ---- Review ---------------------------------------------------------------

  Future<void> _submitReview(
      PatientAppointment appt, int rating, String comment) async {
    try {
      final review = await PatientRepository.submitReview({
        'appointment_id': appt.appointmentId,
        'rating': rating,
        'comment': comment,
      });
      if (!mounted) return;
      setState(() => _reviews = [review, ..._reviews]);
      showAdminToast(
          context, 'Thank you for rating Dr. ${appt.doctorName}!');
    } catch (e) {
      if (mounted) showAdminToast(context, 'Failed to submit review: $e');
    }
  }

  // ---- Sign out ---------------------------------------------------------------

  Future<void> _signOut() async {
    final ok = await showAdminConfirm(
      context,
      title: 'Exit patient dashboard?',
      message: 'You will be returned to the login screen.',
      confirmLabel: 'Exit',
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
      sectionLabel: 'Patient Portal',
      tabs: [
        for (final t in PatientTab.values) PanelTab(t.label, t.icon),
      ],
      current: _current.index,
      userName: _profile.userName.isNotEmpty ? _profile.userName : _userName,
      userEmail: _profile.email.isNotEmpty ? _profile.email : _userEmail,
      roleLabel: 'Patient',
      onSelect: (i) => setState(() => _current = PatientTab.values[i]),
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

  Widget _tabFor(PatientTab tab) {
    switch (tab) {
      case PatientTab.records:
        return RecordsTab(
          profile: _profile,
          appointments: _appointments,
          invoices: _invoices,
          reviews: _reviews,
          onReschedule: _reschedule,
          onPayNow: _payNow,
          onSubmitReview: _submitReview,
          onBookNew: () => setState(() => _current = PatientTab.book),
        );
      case PatientTab.book:
        return BookTab(
          doctors: _doctors,
          bookedSlots: _bookedSlots,
          appointments: _appointments,
          today: today,
          onBook: _bookAppointment,
        );
      case PatientTab.profile:
        return ProfileTab(
          profile: _profile,
          onSave: _saveProfile,
        );
    }
  }
}
