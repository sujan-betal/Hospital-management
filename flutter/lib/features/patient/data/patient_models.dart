/// Models mirroring `frontend/src/services/patient.service.ts` and the web
/// patient portal (`frontend/src/app/(dashboard)/patient/page.tsx`).

class PatientProfile {
  const PatientProfile({
    this.fullName = '',
    this.age,
    this.gender = '',
    this.phone = '',
    this.email = '',
    this.insuranceProvider = '',
  });

  final String fullName;
  final int? age;
  final String gender;
  final String phone;
  final String email;
  final String insuranceProvider;

  factory PatientProfile.fromJson(Map<String, dynamic> json) => PatientProfile(
        fullName: (json['user_name'] ?? json['name'] ?? '') as String,
        age: json['age'] as int?,
        gender: (json['gender'] ?? '') as String,
        phone: (json['phone'] ?? '') as String,
        email: (json['email'] ?? '') as String,
        insuranceProvider:
            (json['insurance_provider'] ?? '') as String,
      );

  PatientProfile copyWith({
    String? fullName,
    int? age,
    String? gender,
    String? phone,
    String? email,
    String? insuranceProvider,
  }) =>
      PatientProfile(
        fullName: fullName ?? this.fullName,
        age: age ?? this.age,
        gender: gender ?? this.gender,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        insuranceProvider: insuranceProvider ?? this.insuranceProvider,
      );

  /// Body for `PUT /api/patient/me` (mirrors `PatientUpdatePayload`).
  Map<String, dynamic> toUpdatePayload() => {
        if (fullName.isNotEmpty) 'user_name': fullName,
        if (email.isNotEmpty) 'email': email,
        'phone': phone,
        if (age != null) 'age': age,
        if (gender.isNotEmpty) 'gender': gender,
        if (insuranceProvider.isNotEmpty)
          'insurance_provider': insuranceProvider,
      };
}

class PatientAppointment {
  const PatientAppointment({
    required this.appointmentId,
    required this.doctorName,
    required this.specialty,
    required this.date,
    required this.time,
    required this.status,
    this.fee = 150,
    this.paymentStatus = 'UNPAID',
  });

  final String appointmentId;
  final String doctorName;
  final String specialty;
  final String date;
  final String time;
  final String status; // SCHEDULED | CHECKED-IN | COMPLETED | CANCELLED
  final num fee;
  final String paymentStatus; // PAID | UNPAID

  factory PatientAppointment.fromJson(Map<String, dynamic> json) =>
      PatientAppointment(
        appointmentId:
            (json['appointment_id'] ?? json['id'] ?? '') as String,
        doctorName: (json['doctor_name'] ?? '') as String,
        specialty: (json['specialty'] ?? '') as String,
        date: (json['date'] ?? '') as String,
        time: (json['time'] ?? '') as String,
        status: (json['status'] ?? '') as String,
        fee: (json['fee'] ?? 150) as num,
        paymentStatus: (json['payment_status'] ?? 'UNPAID') as String,
      );

  PatientAppointment copyWith({
    String? date,
    String? time,
    String? status,
    String? paymentStatus,
  }) =>
      PatientAppointment(
        appointmentId: appointmentId,
        doctorName: doctorName,
        specialty: specialty,
        date: date ?? this.date,
        time: time ?? this.time,
        status: status ?? this.status,
        fee: fee,
        paymentStatus: paymentStatus ?? this.paymentStatus,
      );
}

class PatientInvoiceItem {
  const PatientInvoiceItem({required this.description, required this.cost});

  final String description;
  final num cost;

  factory PatientInvoiceItem.fromJson(Map<String, dynamic> json) =>
      PatientInvoiceItem(
        description: (json['description'] ?? '') as String,
        cost: (json['cost'] ?? 0) as num,
      );
}

class PatientInvoice {
  const PatientInvoice({
    required this.invoiceId,
    required this.date,
    required this.amount,
    required this.items,
    required this.paymentStatus,
  });

  final String invoiceId;
  final String date;
  final num amount;
  final List<PatientInvoiceItem> items;
  final String paymentStatus; // PAID | UNPAID

  factory PatientInvoice.fromJson(Map<String, dynamic> json) => PatientInvoice(
        invoiceId: (json['invoice_id'] ?? json['id'] ?? '') as String,
        date: (json['date'] ?? '') as String,
        amount: (json['amount'] ?? 0) as num,
        items: ((json['items'] ?? const []) as List<dynamic>)
            .map((e) => PatientInvoiceItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        paymentStatus: (json['payment_status'] ?? 'UNPAID') as String,
      );
}

class PatientDoctor {
  const PatientDoctor({
    required this.userId,
    required this.name,
    required this.specialty,
    this.rating = 0,
    this.reviewCount = 0,
    this.experienceYears,
    this.isTopRated = false,
  });

  final String userId;
  final String name;
  final String specialty;
  final double rating;
  final int reviewCount;
  final int? experienceYears;
  final bool isTopRated;

  factory PatientDoctor.fromJson(Map<String, dynamic> json) => PatientDoctor(
        userId: (json['user_id'] ?? '') as String,
        name: (json['name'] ?? '') as String,
        specialty: (json['specialty'] ?? '') as String,
        rating: ((json['rating'] ?? 0) as num).toDouble(),
        reviewCount: (json['review_count'] ?? 0) as int,
        experienceYears: json['experience_years'] as int?,
        isTopRated: (json['is_top_rated'] ?? false) as bool,
      );

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return parts
          .skip(1)
          .map((n) => n.isNotEmpty ? n[0] : '')
          .join()
          .toUpperCase();
    }
    if (parts.isEmpty || parts.first.isEmpty) return 'DR';
    return parts.first.substring(0, parts.first.length > 2 ? 2 : 1)
        .toUpperCase();
  }
}

class PatientReview {
  const PatientReview({
    required this.reviewId,
    required this.appointmentId,
    this.rating = 0,
    this.comment = '',
  });

  final String reviewId;
  final String appointmentId;
  final int rating;
  final String comment;

  factory PatientReview.fromJson(Map<String, dynamic> json) => PatientReview(
        reviewId: (json['review_id'] ?? json['id'] ?? '') as String,
        appointmentId: (json['appointment_id'] ?? '') as String,
        rating: (json['rating'] ?? 0) as int,
        comment: (json['comment'] ?? '') as String,
      );
}

class PatientBookedSlot {
  const PatientBookedSlot({required this.doctorName, required this.time});

  final String doctorName;
  final String time;

  factory PatientBookedSlot.fromJson(Map<String, dynamic> json) =>
      PatientBookedSlot(
        doctorName: (json['doctor_name'] ?? '') as String,
        time: (json['time'] ?? '') as String,
      );
}

/// Payment order response of `POST .../payment/order`.
class PatientPaymentOrder {
  const PatientPaymentOrder({
    required this.orderId,
    required this.amount,
    required this.currency,
    this.keyId = '',
    this.receipt = '',
  });

  final String keyId;
  final String orderId;
  final num amount;
  final String currency;
  final String receipt;

  factory PatientPaymentOrder.fromJson(Map<String, dynamic> json) =>
      PatientPaymentOrder(
        keyId: (json['key_id'] ?? '') as String,
        orderId: (json['order_id'] ?? '') as String,
        amount: (json['amount'] ?? 0) as num,
        currency: (json['currency'] ?? 'INR') as String,
        receipt: (json['receipt'] ?? '') as String,
      );
}

/// Fixed OPD slots offered on the book tab (matches the web `SLOTS` const).
const List<String> patientSlots = [
  '09:30 AM',
  '10:15 AM',
  '11:00 AM',
  '01:15 PM',
  '03:30 PM',
  '04:45 PM',
];
