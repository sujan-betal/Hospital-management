/// Domain models for the receptionist front desk — mirrors the web app's
/// `src/app/(dashboard)/receptionist/page.tsx` types (`receptionist.service.ts`).
library;

class PatientRecord {
  const PatientRecord({
    required this.id,
    required this.name,
    required this.phone,
    this.email = '',
    this.age,
    this.gender = '',
    this.insuranceProvider = '',
    this.status = 'ACTIVE',
  });

  factory PatientRecord.fromApi(Map<String, dynamic> json) => PatientRecord(
        id: (json['user_id'] ?? json['id'] ?? '').toString(),
        name: (json['user_name'] ?? json['name'] ?? '') as String,
        phone: (json['phone'] ?? '') as String,
        email: (json['email'] ?? '') as String,
        age: json['age'] as int?,
        gender: (json['gender'] ?? '') as String,
        insuranceProvider: (json['insurance_provider'] ?? '') as String,
        status: (json['status'] ?? 'ACTIVE') as String,
      );

  final String id;
  final String name;
  final String phone;
  final String email;
  final int? age;
  final String gender;
  final String insuranceProvider;
  final String status;
}

class Appointment {
  const Appointment({
    required this.id,
    required this.appointmentId,
    required this.patientName,
    required this.patientPhone,
    required this.doctorName,
    required this.specialty,
    required this.date,
    required this.time,
    required this.status,
    this.fee = 150,
    this.paymentStatus = 'UNPAID',
  });

  factory Appointment.fromApi(Map<String, dynamic> json) => Appointment(
        id: (json['appointment_id'] ?? json['id'] ?? '').toString(),
        appointmentId: (json['appointment_id'] ?? '') as String,
        patientName: (json['patient_name'] ?? '') as String,
        patientPhone: (json['patient_phone'] ?? '') as String,
        doctorName: (json['doctor_name'] ?? '') as String,
        specialty: (json['specialty'] ?? 'General Medicine') as String,
        date: (json['date'] ?? '') as String,
        time: (json['time'] ?? '') as String,
        status: (json['status'] ?? 'SCHEDULED') as String,
        fee: (json['fee'] ?? 150) as int,
        paymentStatus: (json['payment_status'] ?? 'UNPAID') as String,
      );

  final String id;
  final String appointmentId;
  final String patientName;
  final String patientPhone;
  final String doctorName;
  final String specialty;
  final String date;
  final String time;
  final String status;
  final int fee;
  final String paymentStatus;
}

enum InvoiceStatus { paid, unpaid }
enum InsuranceStatus2 { insured, uninsured }

class InvoiceItem {
  const InvoiceItem({required this.description, required this.cost});

  factory InvoiceItem.fromJson(Map<String, dynamic> json) => InvoiceItem(
        description: (json['description'] ?? '') as String,
        cost: (json['cost'] ?? 0) as int,
      );

  final String description;
  final int cost;

  Map<String, dynamic> toJson() => {'description': description, 'cost': cost};
}

class Invoice {
  const Invoice({
    required this.id,
    required this.invoiceId,
    required this.patientName,
    required this.patientPhone,
    required this.date,
    required this.amount,
    required this.items,
    required this.insuranceStatus,
    required this.paymentStatus,
  });

  factory Invoice.fromApi(Map<String, dynamic> json) => Invoice(
        id: (json['invoice_id'] ?? json['id'] ?? '').toString(),
        invoiceId: (json['invoice_id'] ?? '') as String,
        patientName: (json['patient_name'] ?? '') as String,
        patientPhone: (json['patient_phone'] ?? '') as String,
        date: (json['date'] ?? '') as String,
        amount: (json['amount'] ?? 0) as int,
        items: ((json['items'] ?? []) as List)
            .map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        insuranceStatus: (json['insurance_status'] ?? 'UNINSURED') as String,
        paymentStatus: (json['payment_status'] ?? 'UNPAID') as String,
      );

  final String id;
  final String invoiceId;
  final String patientName;
  final String patientPhone;
  final String date;
  final int amount;
  final List<InvoiceItem> items;
  final String insuranceStatus;
  final String paymentStatus;

  bool get isPaid => paymentStatus.toUpperCase() == 'PAID';
}

class ReceptionistDoctor {
  const ReceptionistDoctor({required this.name, required this.specialty});

  factory ReceptionistDoctor.fromApi(Map<String, dynamic> json) =>
      ReceptionistDoctor(
        name: (json['name'] ?? json['user_name'] ?? '') as String,
        specialty: (json['specialty'] ?? 'General Medicine') as String,
      );

  final String name;
  final String specialty;
}

class DashboardStats {
  const DashboardStats({
    this.todayVisits = 0,
    this.checkedInToday = 0,
    this.totalPatients = 0,
    this.paidBillings = 0,
    this.unpaidBillings = 0,
    this.unpaidInvoices = 0,
    this.totalBeds = 0,
    this.occupiedBeds = 0,
    this.occupancyRate = 0,
    this.pendingTasks = 0,
    this.admitted = 0,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
        todayVisits: (json['today_visits'] ?? 0) as int,
        checkedInToday: (json['checked_in_today'] ?? 0) as int,
        totalPatients: (json['total_patients'] ?? 0) as int,
        paidBillings: (json['paid_billings'] ?? 0) as int,
        unpaidBillings: (json['unpaid_billings'] ?? 0) as int,
        unpaidInvoices: (json['unpaid_invoices'] ?? 0) as int,
        totalBeds: (json['total_beds'] ?? 0) as int,
        occupiedBeds: (json['occupied_beds'] ?? 0) as int,
        occupancyRate: (json['occupancy_rate'] ?? 0) as int,
        pendingTasks: (json['pending_tasks'] ?? 0) as int,
        admitted: (json['admitted'] ?? 0) as int,
      );

  final int todayVisits;
  final int checkedInToday;
  final int totalPatients;
  final int paidBillings;
  final int unpaidBillings;
  final int unpaidInvoices;
  final int totalBeds;
  final int occupiedBeds;
  final int occupancyRate;
  final int pendingTasks;
  final int admitted;
}