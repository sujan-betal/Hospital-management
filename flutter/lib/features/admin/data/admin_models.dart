/// Domain models for the admin console — mirrors the web app's
/// `src/app/admin/mockData.ts` interfaces and `admin.service.ts` API types.

class Bed {
  const Bed({
    required this.id,
    required this.ward,
    required this.status,
    required this.price,
    required this.floor,
    required this.assignedNurse,
    required this.equipment,
    required this.patient,
  });

  final String id;
  final String ward;
  final BedStatus status;
  final int price;
  final int floor;
  final String assignedNurse;
  final List<String> equipment;
  final String? patient;

  Bed copyWith({
    String? id,
    String? ward,
    BedStatus? status,
    int? price,
    int? floor,
    String? assignedNurse,
    List<String>? equipment,
    String? patient,
  }) =>
      Bed(
        id: id ?? this.id,
        ward: ward ?? this.ward,
        status: status ?? this.status,
        price: price ?? this.price,
        floor: floor ?? this.floor,
        assignedNurse: assignedNurse ?? this.assignedNurse,
        equipment: equipment ?? this.equipment,
        patient: patient ?? this.patient,
      );
}

enum BedStatus {
  available,
  occupied,
  sanitizing,
  reserved;

  String get label => name;
}

BedStatus bedStatusFromApi(String raw) {
  switch (raw.trim().toUpperCase()) {
    case 'AVAILABLE':
      return BedStatus.available;
    case 'OCCUPIED':
      return BedStatus.occupied;
    case 'SANITIZING':
      return BedStatus.sanitizing;
    case 'RESERVED':
      return BedStatus.reserved;
    default:
      return BedStatus.available;
  }
}

/// Map the API snake_case bed record onto the camelCase [Bed] shape the UI
/// renders (see `fromApiBed` in the web's `admin/page.tsx`).
Bed bedFromApi(Map<String, dynamic> json) => Bed(
      id: (json['bed_id'] ?? json['id'] ?? '') as String,
      ward: (json['ward'] ?? '') as String,
      status: bedStatusFromApi((json['status'] ?? '') as String),
      price: (json['price'] ?? 0) as int,
      floor: (json['floor'] ?? 1) as int,
      assignedNurse: (json['assigned_nurse'] ?? '') as String,
      equipment: ((json['equipment'] ?? []) as List).cast<String>(),
      patient: json['patient'] as String?,
    );

Map<String, dynamic> bedToApi(Bed bed) => {
      'bed_id': bed.id,
      'ward': bed.ward,
      'status': bed.status.name.toUpperCase(),
      'price': bed.price,
      'floor': bed.floor,
      'assigned_nurse': bed.assignedNurse,
      'equipment': bed.equipment,
      'patient': bed.status == BedStatus.occupied ? bed.patient : null,
    };

const initialBeds = <Bed>[
  Bed(id: 'ICU-101', ward: 'ICU', status: BedStatus.occupied, price: 850, floor: 1, assignedNurse: 'Nurse Sarah Jenkins', equipment: ['Ventilator', 'Cardiac Monitor', 'Oxygen Infusion'], patient: 'Robert Downey Jr.'),
  Bed(id: 'ICU-102', ward: 'ICU', status: BedStatus.available, price: 850, floor: 1, assignedNurse: 'Nurse Sarah Jenkins', equipment: ['Ventilator', 'Cardiac Monitor', 'Defibrillator'], patient: null),
  Bed(id: 'ER-201', ward: 'Emergency', status: BedStatus.occupied, price: 400, floor: 2, assignedNurse: 'Nurse David Vance', equipment: ['Oxygen Port', 'IV Stand', 'Suction Unit'], patient: 'Liam Neeson'),
  Bed(id: 'ER-202', ward: 'Emergency', status: BedStatus.sanitizing, price: 400, floor: 2, assignedNurse: 'Nurse David Vance', equipment: ['Oxygen Port', 'IV Stand'], patient: null),
  Bed(id: 'GEN-301', ward: 'General Ward', status: BedStatus.occupied, price: 150, floor: 3, assignedNurse: 'Nurse Maria Gomez', equipment: ['IV Stand', 'Calling Button'], patient: 'Emma Watson'),
  Bed(id: 'GEN-302', ward: 'General Ward', status: BedStatus.available, price: 150, floor: 3, assignedNurse: 'Nurse Maria Gomez', equipment: ['IV Stand', 'Calling Button'], patient: null),
  Bed(id: 'GEN-303', ward: 'General Ward', status: BedStatus.reserved, price: 150, floor: 3, assignedNurse: 'Nurse Maria Gomez', equipment: ['IV Stand', 'Telemetry Hookup'], patient: null),
  Bed(id: 'PED-401', ward: 'Pediatrics', status: BedStatus.occupied, price: 200, floor: 4, assignedNurse: 'Nurse John Doe', equipment: ['Oxygen Port', 'Pediatric Pulse-Ox'], patient: 'Tommy Watson'),
  Bed(id: 'PED-402', ward: 'Pediatrics', status: BedStatus.available, price: 200, floor: 4, assignedNurse: 'Nurse John Doe', equipment: ['Oxygen Port'], patient: null),
  Bed(id: 'MAT-501', ward: 'Maternity', status: BedStatus.occupied, price: 300, floor: 5, assignedNurse: 'Nurse Sarah Jenkins', equipment: ['Fetal Monitor', 'Neonatal Warmer'], patient: 'Scarlett Johansson'),
];

class Admission {
  const Admission({
    required this.id,
    required this.patientName,
    required this.patientAge,
    required this.patientGender,
    required this.wardType,
    required this.bedId,
    required this.admitDate,
    required this.dischargeDate,
    required this.billingAmount,
    required this.status,
    required this.insuranceStatus,
    required this.patientEmail,
    required this.patientPhone,
  });

  final String id;
  final String patientName;
  final int patientAge;
  final String patientGender;
  final String wardType;
  final String bedId;
  final String admitDate;
  final String dischargeDate;
  final int billingAmount;
  final AdmissionStatus status;
  final InsuranceStatus insuranceStatus;
  final String patientEmail;
  final String patientPhone;

  Admission copyWith({
    String? id,
    String? patientName,
    int? patientAge,
    String? patientGender,
    String? wardType,
    String? bedId,
    String? admitDate,
    String? dischargeDate,
    int? billingAmount,
    AdmissionStatus? status,
    InsuranceStatus? insuranceStatus,
    String? patientEmail,
    String? patientPhone,
  }) =>
      Admission(
        id: id ?? this.id,
        patientName: patientName ?? this.patientName,
        patientAge: patientAge ?? this.patientAge,
        patientGender: patientGender ?? this.patientGender,
        wardType: wardType ?? this.wardType,
        bedId: bedId ?? this.bedId,
        admitDate: admitDate ?? this.admitDate,
        dischargeDate: dischargeDate ?? this.dischargeDate,
        billingAmount: billingAmount ?? this.billingAmount,
        status: status ?? this.status,
        insuranceStatus: insuranceStatus ?? this.insuranceStatus,
        patientEmail: patientEmail ?? this.patientEmail,
        patientPhone: patientPhone ?? this.patientPhone,
      );
}

enum AdmissionStatus { admitted, scheduled, discharged, cancelled }

enum InsuranceStatus { covered, pending, uninsured }

const initialAdmissions = <Admission>[
  Admission(id: 'ADM-8392', patientName: 'Emma Watson', patientAge: 32, patientGender: 'Female', wardType: 'General Ward', bedId: 'GEN-301', admitDate: '2026-07-15', dischargeDate: '2026-07-22', billingAmount: 1050, status: AdmissionStatus.admitted, insuranceStatus: InsuranceStatus.covered, patientEmail: 'emma.watson@gmail.com', patientPhone: '+1 (555) 019-2834'),
  Admission(id: 'ADM-9481', patientName: 'Liam Neeson', patientAge: 68, patientGender: 'Male', wardType: 'Emergency', bedId: 'ER-201', admitDate: '2026-07-19', dischargeDate: '2026-07-24', billingAmount: 2000, status: AdmissionStatus.admitted, insuranceStatus: InsuranceStatus.pending, patientEmail: 'liam@taken.com', patientPhone: '+44 7911 123456'),
  Admission(id: 'ADM-4829', patientName: 'Scarlett Johansson', patientAge: 36, patientGender: 'Female', wardType: 'Maternity', bedId: 'MAT-501', admitDate: '2026-07-18', dischargeDate: '2026-07-25', billingAmount: 2100, status: AdmissionStatus.admitted, insuranceStatus: InsuranceStatus.covered, patientEmail: 'scarlett@avengers.org', patientPhone: '+1 (555) 102-8822'),
  Admission(id: 'ADM-1049', patientName: 'Robert Downey Jr.', patientAge: 55, patientGender: 'Male', wardType: 'ICU', bedId: 'ICU-101', admitDate: '2026-07-17', dischargeDate: '2026-07-21', billingAmount: 3400, status: AdmissionStatus.admitted, insuranceStatus: InsuranceStatus.covered, patientEmail: 'rdj@stark.com', patientPhone: '+1 (555) 300-3000'),
  Admission(id: 'ADM-1102', patientName: 'Leonardo DiCaprio', patientAge: 47, patientGender: 'Male', wardType: 'ICU', bedId: 'ICU-102', admitDate: '2026-07-21', dischargeDate: '2026-07-28', billingAmount: 5950, status: AdmissionStatus.scheduled, insuranceStatus: InsuranceStatus.uninsured, patientEmail: 'leo@di-caprio.com', patientPhone: '+1 (555) 987-6543'),
  Admission(id: 'ADM-5819', patientName: 'Brad Pitt', patientAge: 56, patientGender: 'Male', wardType: 'General Ward', bedId: 'GEN-302', admitDate: '2026-07-10', dischargeDate: '2026-07-14', billingAmount: 600, status: AdmissionStatus.discharged, insuranceStatus: InsuranceStatus.covered, patientEmail: 'pitt@brad.net', patientPhone: '+1 (555) 321-7654'),
  Admission(id: 'ADM-9901', patientName: 'Will Smith', patientAge: 52, patientGender: 'Male', wardType: 'Emergency', bedId: 'ER-202', admitDate: '2026-07-12', dischargeDate: '2026-07-13', billingAmount: 400, status: AdmissionStatus.cancelled, insuranceStatus: InsuranceStatus.uninsured, patientEmail: 'freshprince@will.com', patientPhone: '+1 (555) 111-2222'),
];

class Doctor {
  const Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.status,
    required this.activePatients,
    required this.email,
    required this.phone,
  });

  final String id;
  final String name;
  final String specialty;
  final DoctorStatus status;
  final int activePatients;
  final String email;
  final String phone;

  Doctor copyWith({int? activePatients, DoctorStatus? status}) => Doctor(
        id: id,
        name: name,
        specialty: specialty,
        status: status ?? this.status,
        activePatients: activePatients ?? this.activePatients,
        email: email,
        phone: phone,
      );
}

enum DoctorStatus { onDuty, onCall, offDuty }

const initialDoctors = <Doctor>[
  Doctor(id: 'DOC-001', name: 'Dr. Gregory House', specialty: 'General Medicine', status: DoctorStatus.onDuty, activePatients: 4, email: 'house@aura-med.org', phone: '+1 (555) 123-9081'),
  Doctor(id: 'DOC-002', name: 'Dr. Meredith Grey', specialty: 'Neurology', status: DoctorStatus.onDuty, activePatients: 2, email: 'grey@aura-med.org', phone: '+1 (555) 345-1234'),
  Doctor(id: 'DOC-003', name: 'Dr. Shaun Murphy', specialty: 'Orthopedics', status: DoctorStatus.onDuty, activePatients: 1, email: 'murphy@aura-med.org', phone: '+1 (555) 890-4321'),
  Doctor(id: 'DOC-004', name: 'Dr. Stephen Strange', specialty: 'Cardiology', status: DoctorStatus.onCall, activePatients: 1, email: 'strange@aura-med.org', phone: '+1 (555) 456-7890'),
  Doctor(id: 'DOC-005', name: 'Dr. Allison Cameron', specialty: 'Pediatrics', status: DoctorStatus.offDuty, activePatients: 0, email: 'cameron@aura-med.org', phone: '+1 (555) 789-0123'),
];

class MedicalTask {
  const MedicalTask({
    required this.id,
    required this.bedId,
    required this.task,
    required this.priority,
    required this.assignedTo,
    required this.status,
    required this.type,
    required this.timestamp,
  });

  final String id;
  final String bedId;
  final String task;
  final TaskPriority priority;
  final String assignedTo;
  final TaskStatus status;
  final TaskType type;
  final String timestamp;

  MedicalTask copyWith({TaskStatus? status}) => MedicalTask(
        id: id,
        bedId: bedId,
        task: task,
        priority: priority,
        assignedTo: assignedTo,
        status: status ?? this.status,
        type: type,
        timestamp: timestamp,
      );
}

enum TaskPriority { low, medium, high, emergency }

enum TaskStatus { pending, inProgress, completed }

enum TaskType { nursing, labTest, pharmacy, sanitization }

const initialMedicalTasks = <MedicalTask>[
  MedicalTask(id: 'TSK-8812', bedId: 'ICU-101', task: 'Administer 10ml Epinephrine and monitor blood pressure', priority: TaskPriority.emergency, assignedTo: 'Nurse Sarah Jenkins', status: TaskStatus.inProgress, type: TaskType.nursing, timestamp: '10:30 AM'),
  MedicalTask(id: 'TSK-8813', bedId: 'MAT-501', task: 'Deliver prescribed post-natal antibiotics from pharmacy', priority: TaskPriority.high, assignedTo: 'Nurse Sarah Jenkins', status: TaskStatus.pending, type: TaskType.pharmacy, timestamp: '12:15 PM'),
  MedicalTask(id: 'TSK-8814', bedId: 'ER-202', task: 'Sanitize bed post discharge and replace sheets', priority: TaskPriority.medium, assignedTo: 'Nurse David Vance', status: TaskStatus.pending, type: TaskType.sanitization, timestamp: '11:45 AM'),
  MedicalTask(id: 'TSK-8815', bedId: 'GEN-301', task: 'Collect blood samples for comprehensive CBC and glucose test', priority: TaskPriority.high, assignedTo: 'Nurse Maria Gomez', status: TaskStatus.completed, type: TaskType.labTest, timestamp: '08:15 AM'),
  MedicalTask(id: 'TSK-8816', bedId: 'PED-401', task: 'Administer saline nebulizer', priority: TaskPriority.low, assignedTo: 'Nurse John Doe', status: TaskStatus.completed, type: TaskType.nursing, timestamp: '09:30 AM'),
];

class StaffCredential {
  const StaffCredential({
    required this.id,
    this.userId,
    this.adminId,
    required this.fullName,
    required this.role,
    required this.email,
    required this.phone,
    required this.department,
    required this.employeeId,
    required this.status,
    required this.createdAt,
    required this.lastLogin,
    required this.permissions,
  });

  final String id;
  final String? userId;
  final int? adminId;
  final String fullName;
  final StaffRole role;
  final String email;
  final String phone;
  final String department;
  final String employeeId;
  final StaffStatus status;
  final String createdAt;
  final String? lastLogin;
  final List<String> permissions;

  StaffCredential copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? department,
    StaffStatus? status,
    List<String>? permissions,
  }) =>
      StaffCredential(
        id: id,
        userId: userId,
        adminId: adminId,
        fullName: fullName ?? this.fullName,
        role: role,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        department: department ?? this.department,
        employeeId: employeeId,
        status: status ?? this.status,
        createdAt: createdAt,
        lastLogin: lastLogin,
        permissions: permissions ?? this.permissions,
      );
}

enum StaffRole { doctor, receptionist, subadmin, admin }

enum StaffStatus { active, suspended, inactive }

const initialStaffCredentials = <StaffCredential>[
  StaffCredential(id: 'CRED-001', fullName: 'Dr. Gregory House', role: StaffRole.doctor, email: 'house@auramedical.org', phone: '+91 98765 43210', department: 'General Medicine', employeeId: 'EMP-D001', status: StaffStatus.active, createdAt: '2026-01-15', lastLogin: '2026-07-20 09:15 AM', permissions: []),
  StaffCredential(id: 'CRED-002', fullName: 'Dr. Meredith Grey', role: StaffRole.doctor, email: 'grey@auramedical.org', phone: '+91 98765 43211', department: 'Neurology', employeeId: 'EMP-D002', status: StaffStatus.active, createdAt: '2026-02-10', lastLogin: '2026-07-19 03:42 PM', permissions: []),
  StaffCredential(id: 'CRED-003', fullName: 'Dr. Stephen Strange', role: StaffRole.doctor, email: 'strange@auramedical.org', phone: '+91 98765 43212', department: 'Cardiology', employeeId: 'EMP-D003', status: StaffStatus.active, createdAt: '2026-03-05', lastLogin: '2026-07-18 11:00 AM', permissions: []),
  StaffCredential(id: 'CRED-004', fullName: 'Priya Sharma', role: StaffRole.receptionist, email: 'priya.sharma@auramedical.org', phone: '+91 91234 56789', department: 'Front Desk - OPD', employeeId: 'EMP-R001', status: StaffStatus.active, createdAt: '2026-01-20', lastLogin: '2026-07-20 08:30 AM', permissions: []),
  StaffCredential(id: 'CRED-005', fullName: 'Rahul Verma', role: StaffRole.receptionist, email: 'rahul.verma@auramedical.org', phone: '+91 91234 56790', department: 'Front Desk - Emergency', employeeId: 'EMP-R002', status: StaffStatus.active, createdAt: '2026-04-12', lastLogin: '2026-07-20 07:45 AM', permissions: []),
  StaffCredential(id: 'CRED-006', fullName: 'Dr. Allison Cameron', role: StaffRole.doctor, email: 'cameron@auramedical.org', phone: '+91 98765 43213', department: 'Pediatrics', employeeId: 'EMP-D004', status: StaffStatus.inactive, createdAt: '2026-02-28', lastLogin: null, permissions: []),
  StaffCredential(id: 'CRED-007', fullName: 'Anita Desai', role: StaffRole.receptionist, email: 'anita.desai@auramedical.org', phone: '+91 91234 56791', department: 'Front Desk - Maternity', employeeId: 'EMP-R003', status: StaffStatus.suspended, createdAt: '2026-05-01', lastLogin: '2026-06-15 04:20 PM', permissions: []),
];

class PermissionOption {
  const PermissionOption({
    required this.key,
    required this.label,
    required this.description,
  });

  factory PermissionOption.fromJson(Map<String, dynamic> json) =>
      PermissionOption(
        key: (json['key'] ?? '') as String,
        label: (json['label'] ?? '') as String,
        description: (json['description'] ?? '') as String,
      );

  final String key;
  final String label;
  final String description;
}

class PermissionGroup {
  const PermissionGroup({required this.group, required this.items});

  factory PermissionGroup.fromJson(Map<String, dynamic> json) =>
      PermissionGroup(
        group: (json['group'] ?? '') as String,
        items: ((json['items'] ?? []) as List)
            .map((e) => PermissionOption.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final String group;
  final List<PermissionOption> items;
}

const fallbackPermissionGroups = <PermissionGroup>[

];

class HospitalSettings {
  const HospitalSettings({
    required this.hospitalName,
    required this.address,
    required this.currency,
    required this.copayRate,
    required this.emergencyMarkup,
    required this.doctorSharePercent,
    required this.autoTelemetry,
    required this.sanitationInterval,
    required this.autoDirty,
  });

  factory HospitalSettings.fromJson(Map<String, dynamic> json) =>
      HospitalSettings(
        hospitalName: (json['hospital_name'] ?? 'AURA Medical Center & ICU') as String,
        address: (json['address'] ?? '456 Care Boulevard, Medical District, SF 94102') as String,
        currency: (json['currency'] ?? 'INR (Rs.)') as String,
        copayRate: (json['copay_rate'] ?? 10) as int,
        emergencyMarkup: (json['emergency_markup'] ?? 25) as int,
        doctorSharePercent: (json['doctor_share_percent'] ?? 30) as int,
        autoTelemetry: (json['auto_telemetry'] ?? true) as bool,
        sanitationInterval: (json['sanitation_interval'] ?? 12) as int,
        autoDirty: (json['auto_dirty'] ?? true) as bool,
      );

  final String hospitalName;
  final String address;
  final String currency;
  final int copayRate;
  final int emergencyMarkup;
  final int doctorSharePercent;
  final bool autoTelemetry;
  final int sanitationInterval;
  final bool autoDirty;

  HospitalSettings copyWith({
    String? hospitalName,
    String? address,
    int? copayRate,
    int? emergencyMarkup,
    int? doctorSharePercent,
    bool? autoTelemetry,
    int? sanitationInterval,
    bool? autoDirty,
  }) =>
      HospitalSettings(
        hospitalName: hospitalName ?? this.hospitalName,
        address: address ?? this.address,
        currency: currency,
        copayRate: copayRate ?? this.copayRate,
        emergencyMarkup: emergencyMarkup ?? this.emergencyMarkup,
        doctorSharePercent: doctorSharePercent ?? this.doctorSharePercent,
        autoTelemetry: autoTelemetry ?? this.autoTelemetry,
        sanitationInterval: sanitationInterval ?? this.sanitationInterval,
        autoDirty: autoDirty ?? this.autoDirty,
      );
}

class AdminDoctor {
  const AdminDoctor({
    required this.userId,
    required this.userName,
    required this.email,
    required this.hasBankDetails,
    required this.bankAccountHolder,
    required this.bankAccountNumber,
    required this.bankIfsc,
    required this.bankName,
    required this.upiId,
  });

  factory AdminDoctor.fromJson(Map<String, dynamic> json) => AdminDoctor(
        userId: (json['user_id'] ?? '') as String,
        userName: (json['user_name'] ?? '') as String,
        email: (json['email'] ?? '') as String,
        hasBankDetails: (json['has_bank_details'] ?? false) as bool,
        bankAccountHolder: (json['bank_account_holder'] ?? '') as String,
        bankAccountNumber: (json['bank_account_number'] ?? '') as String,
        bankIfsc: (json['bank_ifsc'] ?? '') as String,
        bankName: (json['bank_name'] ?? '') as String,
        upiId: (json['upi_id'] ?? '') as String,
      );

  final String userId;
  final String userName;
  final String email;
  final bool hasBankDetails;
  final String bankAccountHolder;
  final String bankAccountNumber;
  final String bankIfsc;
  final String bankName;
  final String upiId;
}

class RevenueDoctor {
  const RevenueDoctor({
    required this.doctorName,
    required this.payments,
    required this.collected,
    required this.adminKeep,
    required this.doctorShare,
    required this.paidOut,
    required this.pending,
  });

  factory RevenueDoctor.fromJson(Map<String, dynamic> json) => RevenueDoctor(
        doctorName: (json['doctor_name'] ?? '') as String,
        payments: (json['payments'] ?? 0) as int,
        collected: (json['collected'] ?? 0) as int,
        adminKeep: (json['admin_keep'] ?? 0) as int,
        doctorShare: (json['doctor_share'] ?? 0) as int,
        paidOut: (json['paid_out'] ?? 0) as int,
        pending: (json['pending'] ?? 0) as int,
      );

  final String doctorName;
  final int payments;
  final int collected;
  final int adminKeep;
  final int doctorShare;
  final int paidOut;
  final int pending;
}

class RevenuePayment {
  const RevenuePayment({
    required this.appointmentId,
    required this.patientName,
    required this.doctorName,
    required this.fee,
    required this.doctorSharePercent,
    required this.adminShare,
    required this.doctorShare,
    required this.payoutStatus,
  });

  factory RevenuePayment.fromJson(Map<String, dynamic> json) => RevenuePayment(
        appointmentId: (json['appointment_id'] ?? '') as String,
        patientName: (json['patient_name'] ?? '') as String,
        doctorName: (json['doctor_name'] ?? '') as String,
        fee: (json['fee'] ?? 0) as int,
        doctorSharePercent: (json['doctor_share_percent'] ?? 0) as int,
        adminShare: (json['admin_share'] ?? 0) as int,
        doctorShare: (json['doctor_share'] ?? 0) as int,
        payoutStatus: (json['payout_status'] ?? '') as String,
      );

  final String appointmentId;
  final String patientName;
  final String doctorName;
  final int fee;
  final int doctorSharePercent;
  final int adminShare;
  final int doctorShare;
  final String payoutStatus;
}

class RevenueSummary {
  const RevenueSummary({
    required this.paymentCount,
    required this.totalCollected,
    required this.adminKeep,
    required this.doctorShare,
    required this.doctorSharePercent,
    required this.paidOut,
    required this.pending,
  });

  factory RevenueSummary.fromJson(Map<String, dynamic> json) => RevenueSummary(
        paymentCount: (json['payment_count'] ?? 0) as int,
        totalCollected: (json['total_collected'] ?? 0) as int,
        adminKeep: (json['admin_keep'] ?? 0) as int,
        doctorShare: (json['doctor_share'] ?? 0) as int,
        doctorSharePercent: (json['doctor_share_percent'] ?? 0) as int,
        paidOut: (json['paid_out'] ?? 0) as int,
        pending: (json['pending'] ?? 0) as int,
      );

  final int paymentCount;
  final int totalCollected;
  final int adminKeep;
  final int doctorShare;
  final int doctorSharePercent;
  final int paidOut;
  final int pending;
}

class RevenueOverview {
  const RevenueOverview({
    required this.settings,
    required this.summary,
    required this.doctors,
    required this.payments,
  });

  factory RevenueOverview.fromJson(Map<String, dynamic> json) =>
      RevenueOverview(
        settings: HospitalSettings.fromJson(
            (json['settings'] ?? {}) as Map<String, dynamic>),
        summary:
            RevenueSummary.fromJson((json['summary'] ?? {}) as Map<String, dynamic>),
        doctors: ((json['doctors'] ?? []) as List)
            .map((e) => RevenueDoctor.fromJson(e as Map<String, dynamic>))
            .toList(),
        payments: ((json['payments'] ?? []) as List)
            .map((e) => RevenuePayment.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final HospitalSettings settings;
  final RevenueSummary summary;
  final List<RevenueDoctor> doctors;
  final List<RevenuePayment> payments;
}