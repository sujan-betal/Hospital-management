import '../../../core/network/api_client.dart';
import '../../../data/models/auth_models.dart';
import 'admin_models.dart';

/// API layer for the admin console — mirrors the web app's `admin.service.ts`,
/// `staffCredentials.service.ts` and `payments.service.ts`.
///
/// All calls go through [ApiClient] which already attaches the JWT and
/// unwraps the `{ data, message, success }` envelope.
class AdminRepository {
  AdminRepository._();

  // ---- Beds / Admissions / Tasks / Settings / Revenue (hospital_routes) ---

  static Future<List<Bed>> listBeds() async {
    final json = await ApiClient.instance.get('/api/admin/beds');
    return (json['data'] as List<dynamic>? ?? [])
        .map((e) => bedFromApi(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Bed> createBed(Bed bed) async {
    final json = await ApiClient.instance.post('/api/admin/beds', bedToApi(bed));
    return bedFromApi((json['data'] ?? bedToApi(bed)) as Map<String, dynamic>);
  }

  static Future<Bed> updateBed(Bed bed) async {
    final json = await ApiClient.instance
        .put('/api/admin/beds/${bed.id}', bedToApi(bed));
    return bedFromApi((json['data'] ?? bedToApi(bed)) as Map<String, dynamic>);
  }

  static Future<void> deleteBed(String bedId) =>
      ApiClient.instance.delete('/api/admin/beds/$bedId');

  static Future<List<Admission>> listAdmissions() async {
    final json = await ApiClient.instance.get('/api/admin/admissions');
    return (json['data'] as List<dynamic>? ?? [])
        .map((e) => admissionFromApi(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> createAdmission(Map<String, dynamic> payload) async {
    await ApiClient.instance.post('/api/admin/admissions', payload);
  }

  static Future<void> updateAdmission(
      String id, Map<String, dynamic> payload) async {
    await ApiClient.instance.put('/api/admin/admissions/$id', payload);
  }

  static Future<void> deleteAdmission(String id) =>
      ApiClient.instance.delete('/api/admin/admissions/$id');

  static Future<List<MedicalTask>> listTasks() async {
    final json = await ApiClient.instance.get('/api/admin/tasks');
    return (json['data'] as List<dynamic>? ?? [])
        .map((e) => taskFromApi(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> createTask(Map<String, dynamic> payload) async {
    await ApiClient.instance.post('/api/admin/tasks', payload);
  }

  static Future<void> updateTask(String id, Map<String, dynamic> payload) async {
    await ApiClient.instance.put('/api/admin/tasks/$id', payload);
  }

  static Future<void> deleteTask(String id) =>
      ApiClient.instance.delete('/api/admin/tasks/$id');

  static Future<HospitalSettings> getSettings() async {
    final json = await ApiClient.instance.get('/api/admin/settings');
    return HospitalSettings.fromJson((json['data'] ?? {}) as Map<String, dynamic>);
  }

  static Future<HospitalSettings> updateSettings(
      Map<String, dynamic> payload) async {
    final json = await ApiClient.instance.put('/api/admin/settings', payload);
    return HospitalSettings.fromJson(
        (json['data'] ?? payload) as Map<String, dynamic>);
  }

  static Future<RevenueOverview> getRevenueOverview() async {
    final json = await ApiClient.instance.get('/api/admin/revenue');
    return RevenueOverview.fromJson(
        (json['data'] ?? {}) as Map<String, dynamic>);
  }

  // ---- Staff & credentials (admin_routes + receptionist_routes) -----------

  static Future<void> createReceptionist(Map<String, dynamic> payload) async {
    await ApiClient.instance.post('/api/receptionist/register', payload);
  }

  static Future<AuthSession> createDoctor(Map<String, dynamic> payload) async {
    final json = await ApiClient.instance.post('/api/admin/doctors', payload);
    return AuthSession.fromJson((json['data'] ?? {}) as Map<String, dynamic>);
  }

  static Future<AuthSession> registerAdmin(Map<String, dynamic> payload) async {
    final json = await ApiClient.instance.post('/api/admin/register', payload);
    return AuthSession.fromJson((json['data'] ?? {}) as Map<String, dynamic>);
  }

  static Future<AuthSession> createSubAdmin(Map<String, dynamic> payload) async {
    final json = await ApiClient.instance.post('/api/admin/subadmins', payload);
    return AuthSession.fromJson((json['data'] ?? {}) as Map<String, dynamic>);
  }

  static Future<void> updatePermissions(Map<String, dynamic> payload) async {
    await ApiClient.instance.put('/api/admin/permissions', payload);
  }

  static Future<List<PermissionGroup>> getPermissions() async {
    final json = await ApiClient.instance.get('/api/admin/permissions');
    return (json['data'] as List<dynamic>? ?? [])
        .map((e) => PermissionGroup.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<AdminDoctor>> listAdminDoctors() async {
    final json = await ApiClient.instance.get('/api/admin/doctors');
    return (json['data'] as List<dynamic>? ?? [])
        .map((e) => AdminDoctor.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> updateDoctorBankDetails(
      String userId, Map<String, dynamic> payload) async {
    await ApiClient.instance
        .put('/api/admin/doctors/$userId/bank-details', payload);
  }

  static Future<List<StaffCredential>> listStaff() async {
    final json = await ApiClient.instance.get('/api/admin/staff');
    return (json['data'] as List<dynamic>? ?? [])
        .map((e) => staffFromApi(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> updateStaff(String userId, Map<String, dynamic> payload) async {
    await ApiClient.instance.put('/api/admin/staff/$userId', payload);
  }

  static Future<void> deleteStaff(String userId) =>
      ApiClient.instance.delete('/api/admin/staff/$userId');
}

// =============================== Mappers ===================================

StaffCredential staffFromApi(Map<String, dynamic> json) {
  final role = _staffRoleFromApi((json['role'] ?? '') as String);
  return StaffCredential(
    id: (json['id'] ?? json['employee_id'] ?? json['user_id'] ?? '') as String,
    userId: (json['user_id'] ?? json['user_id']) as String?,
    adminId: json['admin_id'] as int?,
    fullName: (json['user_name'] ?? json['full_name'] ?? '') as String,
    role: role,
    email: (json['email'] ?? '') as String,
    phone: (json['phone'] ?? '') as String,
    department: (json['department'] ?? '') as String,
    employeeId: (json['employee_id'] ?? '') as String,
    status: _staffStatusFromApi((json['status'] ?? 'ACTIVE') as String),
    createdAt: (json['created_at'] ?? '') as String,
    lastLogin: json['last_login'] as String?,
    permissions: ((json['permissions'] ?? []) as List).cast<String>(),
  );
}

StaffRole _staffRoleFromApi(String raw) {
  switch (raw.trim().toUpperCase()) {
    case 'RECEPTIONIST':
      return StaffRole.receptionist;
    case 'SUBADMIN':
      return StaffRole.subadmin;
    case 'ADMIN':
      return StaffRole.admin;
    case 'DOCTOR':
    default:
      return StaffRole.doctor;
  }
}

StaffStatus _staffStatusFromApi(String raw) {
  switch (raw.trim().toUpperCase()) {
    case 'ACTIVE':
      return StaffStatus.active;
    case 'SUSPENDED':
      return StaffStatus.suspended;
    default:
      return StaffStatus.inactive;
  }
}

Admission admissionFromApi(Map<String, dynamic> json) => Admission(
      id: (json['admission_id'] ?? json['id'] ?? '') as String,
      patientName: (json['patient_name'] ?? json['full_name'] ?? '') as String,
      patientAge: (json['patient_age'] ?? 0) as int,
      patientGender: (json['patient_gender'] ?? '') as String,
      wardType: (json['ward_type'] ?? json['ward'] ?? '') as String,
      bedId: (json['bed_id'] ?? '') as String,
      admitDate: (json['admit_date'] ?? '') as String,
      dischargeDate: (json['discharge_date'] ?? '') as String,
      billingAmount: (json['billing_amount'] ?? 0) as int,
      status: admissionStatusFromApi((json['status'] ?? '') as String),
      insuranceStatus:
          insuranceStatusFromApi((json['insurance_status'] ?? '') as String),
      patientEmail: (json['patient_email'] ?? '') as String,
      patientPhone: (json['patient_phone'] ?? '') as String,
    );

AdmissionStatus admissionStatusFromApi(String raw) {
  switch (raw.toUpperCase()) {
    case 'SCHEDULED':
      return AdmissionStatus.scheduled;
    case 'DISCHARGED':
      return AdmissionStatus.discharged;
    case 'CANCELLED':
      return AdmissionStatus.cancelled;
    default:
      return AdmissionStatus.admitted;
  }
}

InsuranceStatus insuranceStatusFromApi(String raw) {
  switch (raw.toUpperCase()) {
    case 'PENDING':
      return InsuranceStatus.pending;
    case 'UNINSURED':
    case 'NONE':
      return InsuranceStatus.uninsured;
    default:
      return InsuranceStatus.covered;
  }
}

MedicalTask taskFromApi(Map<String, dynamic> json) => MedicalTask(
      id: (json['task_id'] ?? json['id'] ?? '') as String,
      bedId: (json['bed_id'] ?? '') as String,
      task: (json['task'] ?? json['description'] ?? '') as String,
      priority: taskPriorityFromApi((json['priority'] ?? '') as String),
      assignedTo:
          (json['assigned_to'] ?? json['assigned_nurse'] ?? '') as String,
      status: taskStatusFromApi((json['status'] ?? '') as String),
      type: taskTypeFromApi((json['type'] ?? '') as String),
      timestamp: (json['timestamp'] ?? '') as String,
    );

TaskPriority taskPriorityFromApi(String raw) {
  switch (raw.toUpperCase()) {
    case 'EMERGENCY':
      return TaskPriority.emergency;
    case 'HIGH':
      return TaskPriority.high;
    case 'MEDIUM':
      return TaskPriority.medium;
    default:
      return TaskPriority.low;
  }
}

TaskStatus taskStatusFromApi(String raw) {
  switch (raw.toUpperCase().replaceAll('_', ' ')) {
    case 'IN PROGRESS':
    case 'IN_PROGRESS':
      return TaskStatus.inProgress;
    case 'COMPLETED':
      return TaskStatus.completed;
    default:
      return TaskStatus.pending;
  }
}

TaskType taskTypeFromApi(String raw) {
  switch (raw.toUpperCase()) {
    case 'LAB_TEST':
    case 'LABTEST':
      return TaskType.labTest;
    case 'PHARMACY':
      return TaskType.pharmacy;
    case 'SANITIZATION':
      return TaskType.sanitization;
    default:
      return TaskType.nursing;
  }
}