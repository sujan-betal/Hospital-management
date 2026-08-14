import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import 'patient_models.dart';

/// API layer for the patient portal — mirrors the web app's
/// `src/services/patient.service.ts`. All calls go through [ApiClient]
/// which attaches the JWT and unwraps the `{ data, message }` envelope.
class PatientRepository {
  PatientRepository._();

  // ---- Profile -----------------------------------------------------------

  /// `GET /api/patient/me`
  static Future<PatientProfile> getProfile() async {
    final json = await ApiClient.instance.get('/api/patient/me');
    return PatientProfile.fromApi(
        (json['data'] ?? const <String, dynamic>{}) as Map<String, dynamic>);
  }

  /// `PUT /api/patient/me`
  static Future<PatientProfile> updateProfile(
      Map<String, dynamic> payload) async {
    final json = await ApiClient.instance.put('/api/patient/me', payload);
    return PatientProfile.fromApi(
        (json['data'] ?? payload) as Map<String, dynamic>);
  }

  // ---- Doctor directory ----------------------------------------------------

  /// `GET /api/patient/doctors`
  static Future<List<PatientDoctor>> listDoctors() async {
    final json = await ApiClient.instance.get('/api/patient/doctors');
    return ((json['data'] ?? const []) as List)
        .map((e) => PatientDoctor.fromApi(e as Map<String, dynamic>))
        .toList();
  }

  // ---- Appointments --------------------------------------------------------

  /// `GET /api/patient/appointments`
  static Future<List<PatientAppointment>> listAppointments() async {
    final json = await ApiClient.instance.get('/api/patient/appointments');
    return ((json['data'] ?? const []) as List)
        .map((e) => PatientAppointment.fromApi(e as Map<String, dynamic>))
        .toList();
  }

  /// `GET /api/patient/appointments/booked-slots?date=YYYY-MM-DD`
  static Future<List<BookedSlot>> listBookedSlots(String date) async {
    final json = await ApiClient.instance
        .get('/api/patient/appointments/booked-slots?date=${Uri.encodeQueryComponent(date)}');
    return ((json['data'] ?? const []) as List)
        .map((e) => BookedSlot.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `POST /api/patient/appointments`
  static Future<PatientAppointment> bookAppointment(
      Map<String, dynamic> payload) async {
    final json = await ApiClient.instance.post('/api/patient/appointments', payload);
    return PatientAppointment.fromApi(
        (json['data'] ?? payload) as Map<String, dynamic>);
  }

  /// `PUT /api/patient/appointments/{appointment_id}`
  static Future<PatientAppointment> updateAppointment(
      String appointmentId, Map<String, dynamic> payload) async {
    final json = await ApiClient.instance
        .put('/api/patient/appointments/$appointmentId', payload);
    return PatientAppointment.fromApi(
        (json['data'] ?? payload) as Map<String, dynamic>);
  }

  // ---- Payment --------------------------------------------------------------

  /// `POST /api/patient/appointments/{appointment_id}/payment/order`
  static Future<PatientPaymentOrder> createPaymentOrder(
      String appointmentId) async {
    final json = await ApiClient.instance
        .post('/api/patient/appointments/$appointmentId/payment/order');
    return PatientPaymentOrder.fromJson(
        (json['data'] ?? const <String, dynamic>{}) as Map<String, dynamic>);
  }

  /// `POST /api/patient/appointments/{appointment_id}/payment/verify`
  static Future<Map<String, dynamic>> verifyPayment(
    String appointmentId,
    Map<String, dynamic> payload,
  ) async {
    final json = await ApiClient.instance
        .post('/api/patient/appointments/$appointmentId/payment/verify', payload);
    return (json['data'] ?? const <String, dynamic>{}) as Map<String, dynamic>;
  }

  // ---- Invoices -------------------------------------------------------------

  /// `GET /api/patient/invoices`
  static Future<List<PatientInvoice>> listInvoices() async {
    final json = await ApiClient.instance.get('/api/patient/invoices');
    return ((json['data'] ?? const []) as List)
        .map((e) => PatientInvoice.fromApi(e as Map<String, dynamic>))
        .toList();
  }

  // ---- Doctor reviews ---------------------------------------------------------

  /// `GET /api/patient/reviews`
  static Future<List<PatientReview>> listReviews() async {
    final json = await ApiClient.instance.get('/api/patient/reviews');
    return ((json['data'] ?? const []) as List)
        .map((e) => PatientReview.fromApi(e as Map<String, dynamic>))
        .toList();
  }

  /// `POST /api/patient/reviews`
  static Future<PatientReview> submitReview(
      Map<String, dynamic> payload) async {
    final json = await ApiClient.instance.post('/api/patient/reviews', payload);
    return PatientReview.fromApi(
        (json['data'] ?? payload) as Map<String, dynamic>);
  }

  /// Logging hook so callers can observe API failures without leaking secrets.
  @visibleForTesting
  static void debug(Object message) => debugPrint('[PatientRepository] $message');
}
