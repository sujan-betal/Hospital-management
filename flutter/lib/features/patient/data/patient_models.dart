/// Domain models for the patient portal — mirrors the web app's
/// `src/app/(dashboard)/patient/page.tsx` types (`patient.service.ts`).

class PatientProfile {
  const PatientProfile({
    this.userId = '',
    this.userName = '',
    this.name = '',
    this.email = '',
    this.phone = '',
    this.age,
    this.gender = '',
    this.insuranceProvider = 'Self-Pay / None',
    this.status = 'ACTIVE',
    this.role = 'PATIENT',
  });

  factory PatientProfile.fromApi(Map<String, dynamic> json) => PatientProfile(
        userId: (json['user_id'] ?? json['id'] ?? '').toString(),
        userName: (json['user_name'] ?? json['name'] ?? '') as String,
        name: (json['name'] ?? json['user_name'] ?? '') as String,
        email: (json['email'] ?? '') as String,
        phone: (json['phone'] ?? '') as String,
        age: json['age'] as int?,
        gender: (json['gender'] ?? '') as String,
        insuranceProvider:
            (json['insurance_provider'] ?? 'Self-Pay / None') as String,
        status: (json['status'] ?? 'ACTIVE') as String,
        role: (json['role'] ?? 'PATIENT') as String,
      );

  final String userId;
  final String userName;
  final String name;
  final String email;
  final String phone;
  final int? age;
  final String gender;
  final String insuranceProvider;
  final String status;
  final String role;

  Map<String, dynamic> toUpdatePayload() => {
        if (userName.trim().isNotEmpty) 'user_name': userName.trim(),
        if (email.trim().isNotEmpty) 'email': email.trim(),
        if (phone.trim().isNotEmpty) 'phone': phone.trim(),
        if (age != null) 'age': age,
        if (gender.trim().isNotEmpty) 'gender': gender.trim(),
        if (insuranceProvider.trim().isNotEmpty)
          'insurance_provider': insuranceProvider.trim(),
      };

  PatientProfile copyWith({
    String? userName,
    String? email,
    String? phone,
    int? age,
    String? gender,
    String? insuranceProvider,
  }) =>
      PatientProfile(
        userId: userId,
        userName: userName ?? this.userName,
        name: name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        age: age ?? this.age,
        gender: gender ?? this.gender,
        insuranceProvider: insuranceProvider ?? this.insuranceProvider,
        status: status,
        role: role,
      );
}

class PatientDoctor {
  const PatientDoctor({
    this.userId = '',
    this.name = '',
    this.specialty = 'General Medicine',
    this.department,
    this.email = '',
    this.phone = '',
    this.rating = 0,
    this.reviewCount = 0,
    this.experienceYears,
    this.isTopRated = false,
  });

  factory PatientDoctor.fromApi(Map<String, dynamic> json) => PatientDoctor(
        userId: (json['user_id'] ?? json['id'] ?? '').toString(),
        name: (json['name'] ?? json['user_name'] ?? '') as String,
        specialty: (json['specialty'] ?? 'General Medicine') as String,
        department: json['department'] as String?,
        email: (json['email'] ?? '') as String,
        phone: (json['phone'] ?? '') as String,
        rating: (json['rating'] ?? 0) as num,
        reviewCount: (json['review_count'] ?? 0) as int,
        experienceYears: json['experience_years'] as int?,
        isTopRated: (json['is_top_rated'] ?? false) as bool,
      );

  final String userId;
  final String name;
  final String specialty;
  final String? department;
  final String email;
  final String phone;
  final num rating;
  final int reviewCount;
  final int? experienceYears;
  final bool isTopRated;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'DR';
    final meaningful = parts.where((p) => p.isNotEmpty).toList();
    final surname = meaningful.length > 1 ? meaningful.last : meaningful.first;
    return (surname.isNotEmpty ? surname[0] : 'D').toUpperCase();
  }
}

class PatientAppointment {
  const PatientAppointment({
    this.id = '',
    this.appointmentId = '',
    this.patientName = '',
    this.patientPhone = '',
    this.doctorName = '',
    this.specialty = 'General Medicine',
    this.date = '',
    this.time = '',
    this.status = 'SCHEDULED',
    this.fee = 150,
    this.paymentStatus = 'UNPAID',
  });

  factory PatientAppointment.fromApi(Map<String, dynamic> json) =>
      PatientAppointment(
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

  bool get isPaid => paymentStatus.toUpperCase() == 'PAID';

  PatientAppointment copyWith({
    String? date,
    String? time,
    String? status,
    String? paymentStatus,
  }) =>
      PatientAppointment(
        id: id,
        appointmentId: appointmentId,
        patientName: patientName,
        patientPhone: patientPhone,
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
  const PatientInvoiceItem({this.description = '', this.cost = 0});

  factory PatientInvoiceItem.fromJson(Map<String, dynamic> json) =>
      PatientInvoiceItem(
        description: (json['description'] ?? '') as String,
        cost: (json['cost'] ?? 0) as int,
      );

  final String description;
  final int cost;
}

class PatientInvoice {
  const PatientInvoice({
    this.id = '',
    this.invoiceId = '',
    this.patientName = '',
    this.patientPhone = '',
    this.date = '',
    this.amount = 0,
    this.items = const [],
    this.insuranceStatus = 'UNINSURED',
    this.paymentStatus = 'UNPAID',
  });

  factory PatientInvoice.fromApi(Map<String, dynamic> json) => PatientInvoice(
        id: (json['invoice_id'] ?? json['id'] ?? '').toString(),
        invoiceId: (json['invoice_id'] ?? '') as String,
        patientName: (json['patient_name'] ?? '') as String,
        patientPhone: (json['patient_phone'] ?? '') as String,
        date: (json['date'] ?? '') as String,
        amount: (json['amount'] ?? 0) as int,
        items: ((json['items'] ?? const []) as List)
            .map((e) => PatientInvoiceItem.fromJson(e as Map<String, dynamic>))
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
  final List<PatientInvoiceItem> items;
  final String insuranceStatus;
  final String paymentStatus;

  bool get isPaid => paymentStatus.toUpperCase() == 'PAID';
}

class PatientReview {
  const PatientReview({
    this.id = 0,
    this.reviewId = '',
    this.appointmentId = '',
    this.doctorId = '',
    this.doctorName = '',
    this.specialty = '',
    this.patientName = '',
    this.rating = 0,
    this.comment = '',
    this.createdAt,
  });

  factory PatientReview.fromApi(Map<String, dynamic> json) => PatientReview(
        id: (json['id'] ?? 0) as int,
        reviewId: (json['review_id'] ?? '') as String,
        appointmentId: (json['appointment_id'] ?? '') as String,
        doctorId: (json['doctor_id'] ?? '') as String,
        doctorName: (json['doctor_name'] ?? '') as String,
        specialty: (json['specialty'] ?? '') as String,
        patientName: (json['patient_name'] ?? '') as String,
        rating: (json['rating'] ?? 0) as int,
        comment: (json['comment'] ?? '') as String,
        createdAt: json['created_at'] as String?,
      );

  final int id;
  final String reviewId;
  final String appointmentId;
  final String doctorId;
  final String doctorName;
  final String specialty;
  final String patientName;
  final int rating;
  final String comment;
  final String? createdAt;
}

class BookedSlot {
  const BookedSlot({this.doctorName = '', this.time = ''});

  factory BookedSlot.fromJson(Map<String, dynamic> json) => BookedSlot(
        doctorName: (json['doctor_name'] ?? '') as String,
        time: (json['time'] ?? '') as String,
      );

  final String doctorName;
  final String time;
}

/// Razorpay order created by `POST /api/patient/appointments/{id}/payment/order`.
class PatientPaymentOrder {
  const PatientPaymentOrder({
    this.keyId = '',
    this.orderId = '',
    this.amount = 0,
    this.currency = 'INR',
    this.receipt = '',
    this.appointmentId = '',
  });

  factory PatientPaymentOrder.fromJson(Map<String, dynamic> json) =>
      PatientPaymentOrder(
        keyId: (json['key_id'] ?? '') as String,
        orderId: (json['order_id'] ?? '') as String,
        amount: (json['amount'] ?? 0) as int,
        currency: (json['currency'] ?? 'INR') as String,
        receipt: (json['receipt'] ?? '') as String,
        appointmentId: (json['appointment_id'] ?? '') as String,
      );

  final String keyId;
  final String orderId;
  final int amount;
  final String currency;
  final String receipt;
  final String appointmentId;
}
