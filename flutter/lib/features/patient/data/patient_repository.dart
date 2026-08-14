import '../../../core/network/api_client.dart';
import 'patient_models.dart';

/// Patient portal API calls. Backend endpoints live in
/// `backend/src/modules/patient/patient_routes.py` and mirror the web app's
/// `frontend/src/services/patient.service.ts`.
class PatientRepository {
  PatientRepository._();

  /// `GET /api/patient/me` → `{ data: PatientProfile }`
  static Future<PatientProfile> getProfile() async {
    final json = await ApiClient.instance.get('/api/patient/me');
    return PatientProfile.fromJson(
        (json['data'] ?? const <String, dynamic>{}) as Map<String, dynamic>);
  }

  /// `PUT /api/patient/me` → persists profile edits.
  static Future<void> updateProfile(PatientProfile profile) async {
    await ApiClient.instance.put('/api/patient/me', profile.toUpdatePayload());
  }

  /// `GET /api/patient/doctors` → `{ data: [PatientDoctor] }`
  static Future<List<PatientDoctor>> getDoctors() async {
    final json = await ApiClient.instance.get('/api/patient/doctors');
    return (json['data'] as List<dynamic>? ?? [])
        .map((e) => PatientDoctor.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `GET /api/patient/appointments` → `{ data: [PatientAppointment] }`
  static Future<List<PatientAppointment>> getAppointments() async {
    final json = await ApiClient.instance.get('/api/patient/appointments');
    return (json['data'] as List<dynamic>? ?? [])
        .map((e) => PatientAppointment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `GET /api/patient/appointments/booked-slots?date=...` → `{ data: [...] }`
  static Future<List<PatientBookedSlot>> getBookedSlots(String date) async {
    final json = await ApiClient.instance.get(
        '/api/patient/appointments/booked-slots?date=${Uri.encodeQueryComponent(date)}');
    return (json['data'] as List<dynamic>? ?? [])
        .map((e) => PatientBookedSlot.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `POST /api/patient/appointments` → `{ data: PatientAppointment }`
  static Future<PatientAppointment> bookAppointment({
    required String doctorName,
    required String specialty,
    required String date,
    required String time,
  }) async {
    final json = await ApiClient.instance.post('/api/patient/appointments', {
      'doctor_name': doctorName,
      'specialty': specialty,
      'date': date,
      'time': time,
    });
    return PatientAppointment.fromJson(
        (json['data'] ?? const <String, dynamic>{}) as Map<String, dynamic>);
  }

  /// `PUT /api/patient/appointments/{id}` → reschedule.
  static Future<PatientAppointment> updateAppointment(
    String appointmentId, {
    String? date,
    String? time,
  }) async {
    final json = await ApiClient.instance.put(
      '/api/patient/appointments/$appointmentId',
      {
        if (date != null) 'date': date,
        if (time != null) 'time': time,
      },
    );
    return PatientAppointment.fromJson(
        (json['data'] ?? const <String, dynamic>{}) as Map<String, dynamic>);
  }

  /// `POST /api/patient/appointments/{id}/payment/order` → starts Razorpay order.
  static Future<PatientPaymentOrder> createPaymentOrder(String appointmentId) async {
    final json = await ApiClient.instance
        .post('/api/patient/appointments/$appointmentId/payment/order', {});
    return PatientPaymentOrder.fromJson(
        (json['data'] ?? const <String, dynamic>{}) as Map<String, dynamic>);
  }

  /// `POST /api/patient/appointments/{id}/payment/verify` → confirm payment.
  static Future<PatientAppointment> verifyPayment(
    String appointmentId,
    Map<String, dynamic> payload,
  ) async {
    final json = await ApiClient.instance
        .post('/api/patient/appointments/$appointmentId/payment/verify', payload);
    final data = (json['data'] ?? const <String, dynamic>{}) as Map<String, dynamic>;
    return PatientAppointment.fromJson(
        (data['appointment'] ?? data) as Map<String, dynamic>);
  }

  /// `GET /api/patient/invoices` → `{ data: [PatientInvoice] }`
  static Future<List<PatientInvoice>> getInvoices() async {
    final json = await ApiClient.instance.get('/api/patient/invoices');
    return (json['data'] as List<dynamic>? ?? [])
        .map((e) => PatientInvoice.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `GET /api/patient/reviews` → `{ data: [PatientReview] }`
  static Future<List<PatientReview>> getReviews() async {
    final json = await ApiClient.instance.get('/api/patient/reviews');
    return (json['data'] as List<dynamic>? ?? [])
        .map((e) => PatientReview.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `POST /api/patient/reviews` → `{ data: PatientReview }`
  static Future<PatientReview> submitReview({
    required String appointmentId,
    required int rating,
    String comment = '',
  }) async {
    final json = await ApiClient.instance.post('/api/patient/reviews', {
      'appointment_id': appointmentId,
      'rating': rating,
      if (comment.isNotEmpty) 'comment': comment,
    });
    return PatientReview.fromJson(
        (json['data'] ?? const <String, dynamic>{}) as Map<String, dynamic>);
  }
}
