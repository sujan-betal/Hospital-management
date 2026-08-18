import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/payment/razorpay_payment.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../data/patient_models.dart';
import '../../data/patient_repository.dart';
import '../patient_colors.dart';
import '../tabs/book_tab.dart';
import '../tabs/profile_tab.dart';
import '../tabs/records_tab.dart';
import '../widgets/patient_common.dart';
import '../widgets/patient_modals.dart';
import '../widgets/patient_scaffold.dart';
import '../widgets/patient_sidebar.dart';

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
      showPatientToast(context, 'Failed to load patient data: $e', error: true);
    }
  }

  // ---- Profile ------------------------------------------------------------

  Future<void> _saveProfile(PatientProfile updated) async {
    try {
      final saved = await PatientRepository.updateProfile(updated.toUpdatePayload());
      if (!mounted) return;
      setState(() => _profile = saved);
      showPatientToast(context, 'Profile updated in the hospital database');
    } catch (e) {
      if (mounted) showPatientToast(context, 'Failed to save profile: $e', error: true);
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
      showPatientToast(
        context,
        'Booking successful! Your consultation with ${doctor.name} is confirmed for $slot today.',
      );
      return true;
    } catch (e) {
      if (mounted) showPatientToast(context, 'Failed to book appointment: $e', error: true);
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

  Future<bool> _reschedule(
      PatientAppointment appt, String date, String time) async {
    try {
      final updated =
          await PatientRepository.updateAppointment(appt.appointmentId, {
        'date': date,
        'time': time,
      });
      if (!mounted) return true;
      setState(() {
        _appointments = [
          for (final a in _appointments)
            if (a.appointmentId == updated.appointmentId) updated else a,
        ];
      });
      _refreshBookedSlots();
      showPatientToast(context, 'Appointment rescheduled successfully');
      return true;
    } catch (e) {
      if (mounted) showPatientToast(context, 'Failed to reschedule: $e', error: true);
      return false;
    }
  }

  // ---- Payment ---------------------------------------------------------------

  /// Open the Razorpay checkout for the appointment's OPD fee, then confirm the
  /// payment server-side — mirrors the web app's `handlePayNow` in
  /// `frontend/src/app/(dashboard)/patient/page.tsx`.
  Future<void> _payNow(PatientAppointment appt) async {
    try {
      final order =
          await PatientRepository.createPaymentOrder(appt.appointmentId);
      if (!mounted) return;

      final result = await RazorpayPayment.open(
        keyId: order.keyId,
        orderId: order.orderId,
        amount: order.amount,
        currency: order.currency,
        description: 'OPD Consultation – ${appt.doctorName}',
        name: _profile.userName.isNotEmpty ? _profile.userName : _userName,
        contact: _profile.phone,
        email: _profile.email,
      );

      // User dismissed the checkout without paying.
      if (result == null || !mounted) return;

      await PatientRepository.verifyPayment(appt.appointmentId, {
        'razorpay_order_id': result.orderId,
        'razorpay_payment_id': result.paymentId,
        'razorpay_signature': result.signature,
      });

      if (!mounted) return;
      setState(() {
        _appointments = [
          for (final a in _appointments)
            if (a.appointmentId == appt.appointmentId)
              a.copyWith(paymentStatus: 'PAID')
            else
              a,
        ];
      });
      showPatientToast(
        context,
        'Payment successful! Your appointment is confirmed.',
      );
    } on ApiException catch (e) {
      if (mounted) showPatientToast(context, e.message, error: true);
    } catch (e) {
      if (mounted) {
        showPatientToast(context, 'Could not complete payment: $e', error: true);
      }
    }
  }

  // ---- Review ---------------------------------------------------------------

  Future<bool> _submitReview(
      PatientAppointment appt, int rating, String comment) async {
    try {
      final review = await PatientRepository.submitReview({
        'appointment_id': appt.appointmentId,
        'rating': rating,
        'comment': comment,
      });
      if (!mounted) return true;
      setState(() => _reviews = [review, ..._reviews]);
      showPatientToast(context, 'Thank you for rating Dr. ${appt.doctorName}!');
      return true;
    } catch (e) {
      if (mounted) showPatientToast(context, 'Failed to submit review: $e', error: true);
      return false;
    }
  }

  // ---- Sign out ---------------------------------------------------------------

  Future<void> _signOut() async {
    final ok = await showPatientConfirm(
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
    return PatientScaffold(
      current: _current,
      userName: _profile.userName.isNotEmpty ? _profile.userName : _userName,
      userPhone: _profile.phone,
      onSelect: (t) => setState(() => _current = t),
      onSignOut: _signOut,
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: PatientColors.emerald),
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
          today: today,
          bookedSlots: _bookedSlots,
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