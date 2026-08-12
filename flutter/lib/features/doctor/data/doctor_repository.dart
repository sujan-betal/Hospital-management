import '../../../core/network/api_client.dart';
import 'doctor_models.dart';

/// Doctor portal API calls. Backend endpoints live in
/// `backend/src/modules/doctor/doctor_routes.py`.
class DoctorRepository {
  DoctorRepository._();

  /// `GET /api/doctor/earnings` → `{ data: DoctorEarnings }`
  static Future<DoctorEarnings> getEarnings() async {
    final json = await ApiClient.instance.get('/api/doctor/earnings');
    return DoctorEarnings.fromJson(
        (json['data'] ?? const <String, dynamic>{}) as Map<String, dynamic>);
  }

  /// `PUT /api/doctor/bank-details` → `{ data: DoctorBankDetails }`
  static Future<DoctorBankDetails> updateBankDetails(
    DoctorBankDetails payload,
  ) async {
    final json =
        await ApiClient.instance.put('/api/doctor/bank-details', payload.toPayload());
    return DoctorBankDetails.fromJson(
        (json['data'] ?? const <String, dynamic>{}) as Map<String, dynamic>);
  }
}
