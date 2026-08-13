import '../../../core/network/api_client.dart';
import '../../admin/data/admin_models.dart';
import 'receptionist_models.dart';

/// API layer for the receptionist front desk — mirrors the web app's
/// `src/services/receptionist.service.ts`. All calls go through [ApiClient]
/// which attaches the JWT and unwraps the `{ data, message }` envelope.
class ReceptionistRepository {
  ReceptionistRepository._();

  // ---- Patients (owned by the Patient module) --------------------------

  static Future<List<PatientRecord>> listPatients() async {
    final json = await ApiClient.instance.get('/api/patient');
    return ((json['data'] ?? []) as List)
        .map((e) => PatientRecord.fromApi(e as Map<String, dynamic>))
        .toList();
  }

  static Future<PatientRecord> createPatient(Map<String, dynamic> payload) async {
    final json = await ApiClient.instance.post('/api/patient', payload);
    return PatientRecord.fromApi(
        (json['data'] ?? payload) as Map<String, dynamic>);
  }

  // ---- OPD appointments ------------------------------------------------

  static Future<List<Appointment>> listAppointments() async {
    final json = await ApiClient.instance.get('/api/receptionist/appointments');
    return ((json['data'] ?? []) as List)
        .map((e) => Appointment.fromApi(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Appointment> bookAppointment(
      Map<String, dynamic> payload) async {
    final json =
        await ApiClient.instance.post('/api/receptionist/appointments', payload);
    return Appointment.fromApi(
        (json['data'] ?? payload) as Map<String, dynamic>);
  }

  static Future<Appointment> updateAppointment(
      String appointmentId, Map<String, dynamic> payload) async {
    final json = await ApiClient.instance
        .put('/api/receptionist/appointments/$appointmentId', payload);
    return Appointment.fromApi(
        (json['data'] ?? payload) as Map<String, dynamic>);
  }

  static Future<void> deleteAppointment(String appointmentId) =>
      ApiClient.instance.delete('/api/receptionist/appointments/$appointmentId');

  // ---- Billing & invoices ------------------------------------------------

  static Future<List<Invoice>> listInvoices() async {
    final json = await ApiClient.instance.get('/api/receptionist/invoices');
    return ((json['data'] ?? []) as List)
        .map((e) => Invoice.fromApi(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Invoice> createInvoice(Map<String, dynamic> payload) async {
    final json =
        await ApiClient.instance.post('/api/receptionist/invoices', payload);
    return Invoice.fromApi((json['data'] ?? payload) as Map<String, dynamic>);
  }

  static Future<Invoice> updateInvoice(
      String invoiceId, Map<String, dynamic> payload) async {
    final json = await ApiClient.instance
        .put('/api/receptionist/invoices/$invoiceId', payload);
    return Invoice.fromApi((json['data'] ?? payload) as Map<String, dynamic>);
  }

  // ---- Ward & beds --------------------------------------------------------

  static Future<List<Bed>> listBeds() async {
    final json = await ApiClient.instance.get('/api/receptionist/beds');
    return ((json['data'] ?? []) as List)
        .map((e) => bedFromApi(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Bed> updateBedStatus(
      String bedId, Map<String, dynamic> payload) async {
    final json =
        await ApiClient.instance.put('/api/receptionist/beds/$bedId', payload);
    return bedFromApi((json['data'] ?? {}) as Map<String, dynamic>);
  }

  // ---- Analytics ----------------------------------------------------------

  static Future<DashboardStats> getDashboard() async {
    final json = await ApiClient.instance.get('/api/receptionist/dashboard');
    return DashboardStats.fromJson((json['data'] ?? {}) as Map<String, dynamic>);
  }
}