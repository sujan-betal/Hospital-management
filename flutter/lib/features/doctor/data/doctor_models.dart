/// Models mirroring `frontend/src/app/(dashboard)/doctor/page.tsx` types and
/// `frontend/src/services/doctor.service.ts`.

class DoctorAppointment {
  const DoctorAppointment({
    required this.id,
    required this.patientName,
    required this.age,
    required this.gender,
    required this.time,
    required this.type,
    required this.symptoms,
    required this.status,
  });

  final String id;
  final String patientName;
  final int age;
  final String gender;
  final String time;
  final String type; // Consultation | Follow-up | Emergency
  final String symptoms;
  final String status; // waiting | in-consultation | completed

  String get initials {
    final parts = patientName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  DoctorAppointment copyWith({String? status}) => DoctorAppointment(
        id: id,
        patientName: patientName,
        age: age,
        gender: gender,
        time: time,
        type: type,
        symptoms: symptoms,
        status: status ?? this.status,
      );
}

class DoctorMedicine {
  const DoctorMedicine({
    required this.name,
    required this.dosage,
    required this.duration,
  });

  final String name;
  final String dosage;
  final String duration;
}

class DoctorPrescription {
  const DoctorPrescription({
    required this.id,
    required this.patientName,
    required this.date,
    required this.medicines,
    required this.notes,
  });

  final String id;
  final String patientName;
  final String date;
  final List<DoctorMedicine> medicines;
  final String notes;
}

class DoctorLabOrder {
  const DoctorLabOrder({
    required this.id,
    required this.patientName,
    required this.testType,
    required this.status, // pending | processing | completed
    required this.priority, // routine | urgent | stat
    this.results,
    this.abnormalFlag = false,
  });

  final String id;
  final String patientName;
  final String testType;
  final String status;
  final String priority;
  final String? results;
  final bool abnormalFlag;
}

class DoctorConsultation {
  const DoctorConsultation({
    required this.id,
    required this.patientName,
    required this.date,
    required this.diagnosis,
    required this.treatmentPlan,
    required this.notes,
  });

  final String id;
  final String patientName;
  final String date;
  final String diagnosis;
  final String treatmentPlan;
  final String notes;
}

// ─────────────────────────────── Earnings API ───────────────────────────────

class DoctorBankDetails {
  const DoctorBankDetails({
    required this.accountHolder,
    required this.accountNumber,
    required this.ifsc,
    required this.bankName,
    required this.upiId,
    required this.hasBankDetails,
  });

  final String accountHolder;
  final String accountNumber;
  final String ifsc;
  final String bankName;
  final String upiId;
  final bool hasBankDetails;

  factory DoctorBankDetails.fromJson(Map<String, dynamic> json) =>
      DoctorBankDetails(
        accountHolder: (json['account_holder'] ?? '') as String,
        accountNumber: (json['account_number'] ?? '') as String,
        ifsc: (json['ifsc'] ?? '') as String,
        bankName: (json['bank_name'] ?? '') as String,
        upiId: (json['upi_id'] ?? '') as String,
        hasBankDetails: (json['has_bank_details'] ?? false) as bool,
      );

  Map<String, dynamic> toPayload() => {
        'account_holder': accountHolder,
        'account_number': accountNumber,
        'ifsc': ifsc,
        if (bankName.isNotEmpty) 'bank_name': bankName,
        if (upiId.isNotEmpty) 'upi_id': upiId,
      };
}

class DoctorEarningsSummary {
  const DoctorEarningsSummary({
    required this.totalEarned,
    required this.paidOut,
    required this.pending,
    required this.paymentsCount,
    required this.doctorSharePercent,
  });

  final num totalEarned;
  final num paidOut;
  final num pending;
  final int paymentsCount;
  final num doctorSharePercent;

  factory DoctorEarningsSummary.fromJson(Map<String, dynamic> json) =>
      DoctorEarningsSummary(
        totalEarned: (json['total_earned'] ?? 0) as num,
        paidOut: (json['paid_out'] ?? 0) as num,
        pending: (json['pending'] ?? 0) as num,
        paymentsCount: (json['payments_count'] ?? 0) as int,
        doctorSharePercent: (json['doctor_share_percent'] ?? 0) as num,
      );
}

class DoctorEarningPayment {
  const DoctorEarningPayment({
    required this.appointmentId,
    required this.patientName,
    required this.date,
    required this.time,
    required this.fee,
    required this.paymentStatus,
    required this.doctorSharePercent,
    required this.doctorShare,
    required this.payoutStatus,
    required this.payoutDate,
  });

  final String appointmentId;
  final String patientName;
  final String date;
  final String time;
  final num fee;
  final String paymentStatus;
  final num doctorSharePercent;
  final num doctorShare;
  final String payoutStatus;
  final String payoutDate;

  factory DoctorEarningPayment.fromJson(Map<String, dynamic> json) =>
      DoctorEarningPayment(
        appointmentId: (json['appointment_id'] ?? json['id'] ?? '') as String,
        patientName: (json['patient_name'] ?? '') as String,
        date: (json['date'] ?? '') as String,
        time: (json['time'] ?? '') as String,
        fee: (json['fee'] ?? 0) as num,
        paymentStatus: (json['payment_status'] ?? '') as String,
        doctorSharePercent: (json['doctor_share_percent'] ?? 0) as num,
        doctorShare: (json['doctor_share'] ?? 0) as num,
        payoutStatus: (json['payout_status'] ?? '') as String,
        payoutDate: (json['payout_date'] ?? '') as String,
      );
}

class DoctorEarnings {
  const DoctorEarnings({
    required this.bank,
    required this.summary,
    required this.payments,
  });

  final DoctorBankDetails bank;
  final DoctorEarningsSummary summary;
  final List<DoctorEarningPayment> payments;

  factory DoctorEarnings.fromJson(Map<String, dynamic> json) => DoctorEarnings(
        bank: DoctorBankDetails.fromJson(
            (json['bank'] ?? const <String, dynamic>{}) as Map<String, dynamic>),
        summary: DoctorEarningsSummary.fromJson(
            (json['summary'] ?? const <String, dynamic>{})
                as Map<String, dynamic>),
        payments: ((json['payments'] ?? const []) as List<dynamic>)
            .map((e) => DoctorEarningPayment.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
