// Widget tests for the Razorpay checkout flow in the patient panel.
//
// The native `razorpay_flutter` SDK and the web `checkout.js` loader are both
// unavailable under `flutter test`, so the tests substitute the checkout via
// `RazorpayPayment.debugOpenOverride` and stub the patient API through
// `PatientRepository.debug*` hooks — then assert the exact options the panel
// passes to the wrapper and how the UI reacts to success / cancel / failure.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hospital_management/core/payment/razorpay_payment.dart';
import 'package:hospital_management/features/patient/data/patient_models.dart';
import 'package:hospital_management/features/patient/data/patient_repository.dart';
import 'package:hospital_management/features/patient/presentation/pages/patient_dashboard_page.dart';

const _profile = PatientProfile(
  userId: 'P-1',
  userName: 'Asha Verma',
  email: 'asha@example.com',
  phone: '+919876543210',
);

const _unpaidAppointment = PatientAppointment(
  appointmentId: 'APT-101',
  patientName: 'Asha Verma',
  patientPhone: '+919876543210',
  doctorName: 'Dr. Smith',
  specialty: 'General Medicine',
  date: '2026-08-19',
  time: '09:30 AM',
  status: 'SCHEDULED',
  fee: 150,
  paymentStatus: 'UNPAID',
);

const _paidAppointment = PatientAppointment(
  appointmentId: 'APT-102',
  patientName: 'Asha Verma',
  patientPhone: '+919876543210',
  doctorName: 'Dr. Patel',
  specialty: 'Cardiology',
  date: '2026-08-19',
  time: '11:00 AM',
  status: 'SCHEDULED',
  fee: 150,
  paymentStatus: 'PAID',
);

const _doctor = PatientDoctor(
  userId: 'D-1',
  name: 'Dr. Smith',
  specialty: 'General Medicine',
  rating: 4.5,
  reviewCount: 12,
);

// The fee shown in the patient panel is Rs. 150, so the Razorpay order/checkout
// must carry exactly that amount — expressed in paise as the SDKs require.
const _feeRupees = 150;
const _order = PatientPaymentOrder(
  keyId: 'rzp_test_1a2b3c4d',
  orderId: 'order_Ov7t3nR9mK2pL',
  amount: _feeRupees * 100,
  currency: 'INR',
  receipt: 'APT-101',
  appointmentId: 'APT-101',
);

Future<void> _pumpPatientDashboard(WidgetTester tester) async {
  // Use a large surface so the records ListView builds the appointment card
  // without scrolling (the default 800x600 viewport clips it below the fold).
  tester.view.physicalSize = const Size(1400, 2200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    const MaterialApp(home: PatientDashboardPage()),
  );
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() {
    RazorpayPayment.debugOpenOverride = null;
    PatientRepository.debugGetProfile = null;
    PatientRepository.debugListAppointments = null;
    PatientRepository.debugListInvoices = null;
    PatientRepository.debugListDoctors = null;
    PatientRepository.debugListReviews = null;
    PatientRepository.debugListBookedSlots = null;
    PatientRepository.debugCreatePaymentOrder = null;
    PatientRepository.debugVerifyPayment = null;
  });

  void stubPatientApi({
    List<PatientAppointment> appointments = const [],
    List<PatientInvoice> invoices = const [],
  }) {
    PatientRepository.debugGetProfile = () async => _profile;
    PatientRepository.debugListAppointments = () async => appointments;
    PatientRepository.debugListInvoices = () async => invoices;
    PatientRepository.debugListDoctors = () async => const [_doctor];
    PatientRepository.debugListReviews = () async => const [];
    PatientRepository.debugListBookedSlots = (_) async => const [];
  }

  testWidgets(
      'Pay Now opens the Razorpay checkout with the patient order and '
      'marks the appointment PAID on success', (tester) async {
    final openedOptions = <String, Object?>{};
    final verifyCalls = <Map<String, dynamic>>[];

    stubPatientApi(appointments: const [_unpaidAppointment]);
    PatientRepository.debugCreatePaymentOrder = (_) async => _order;
    PatientRepository.debugVerifyPayment = (id, payload) async {
      verifyCalls.add(payload);
      return const <String, dynamic>{};
    };
    RazorpayPayment.debugOpenOverride = ({
      required keyId,
      required orderId,
      required amount,
      required currency,
      required description,
      required name,
      required contact,
      required email,
    }) async {
      openedOptions['keyId'] = keyId;
      openedOptions['orderId'] = orderId;
      openedOptions['amount'] = amount;
      openedOptions['currency'] = currency;
      openedOptions['description'] = description;
      openedOptions['name'] = name;
      openedOptions['contact'] = contact;
      openedOptions['email'] = email;
      return RazorpayPaymentResult(
        paymentId: 'pay_9x7y6z5w',
        orderId: orderId,
        signature: 'sig_abc123',
      );
    };

    await _pumpPatientDashboard(tester);

    expect(find.text('Pay Now'), findsOneWidget);
    await tester.tap(find.text('Pay Now'));
    await tester.pumpAndSettle();

    // The wrapper receives the order created by the backend. Razorpay reads the
    // amount in paise, so 150 * 100 = ₹150 — exactly what the panel displays.
    expect(openedOptions['keyId'], 'rzp_test_1a2b3c4d');
    expect(openedOptions['orderId'], 'order_Ov7t3nR9mK2pL');
    expect(openedOptions['amount'], _feeRupees * 100);
    expect(openedOptions['currency'], 'INR');
    expect(openedOptions['description'], 'OPD Consultation – Dr. Smith');
    expect(openedOptions['name'], 'Asha Verma');
    expect(openedOptions['contact'], '+919876543210');
    expect(openedOptions['email'], 'asha@example.com');

    // The Razorpay callback payload is forwarded to the verify endpoint.
    expect(verifyCalls, hasLength(1));
    expect(verifyCalls.single['razorpay_order_id'], 'order_Ov7t3nR9mK2pL');
    expect(verifyCalls.single['razorpay_payment_id'], 'pay_9x7y6z5w');
    expect(verifyCalls.single['razorpay_signature'], 'sig_abc123');

    // The appointment is now PAID and Pay Now disappears.
    expect(find.text('FEE: RS. 150 · PAID'), findsOneWidget);
    expect(find.text('Pay Now'), findsNothing);

    // Let the success SnackBar expire so no timers leak.
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
  });

  testWidgets('Dismissing the checkout leaves the appointment unpaid',
      (tester) async {
    var verifyCalled = false;

    stubPatientApi(appointments: const [_unpaidAppointment]);
    PatientRepository.debugCreatePaymentOrder = (_) async => _order;
    PatientRepository.debugVerifyPayment = (id, payload) async {
      verifyCalled = true;
      return const <String, dynamic>{};
    };
    RazorpayPayment.debugOpenOverride = ({
      required keyId,
      required orderId,
      required amount,
      required currency,
      required description,
      required name,
      required contact,
      required email,
    }) async =>
        null;

    await _pumpPatientDashboard(tester);

    await tester.tap(find.text('Pay Now'));
    await tester.pumpAndSettle();

    expect(verifyCalled, isFalse);
    expect(find.text('FEE: RS. 150 · UNPAID'), findsOneWidget);
    expect(find.text('Pay Now'), findsOneWidget);
  });

  testWidgets('Checkout failure surfaces an error toast', (tester) async {
    stubPatientApi(appointments: const [_unpaidAppointment]);
    PatientRepository.debugCreatePaymentOrder = (_) async => _order;
    RazorpayPayment.debugOpenOverride = ({
      required keyId,
      required orderId,
      required amount,
      required currency,
      required description,
      required name,
      required contact,
      required email,
    }) async =>
        throw StateError('Payment failed');

    await _pumpPatientDashboard(tester);

    await tester.tap(find.text('Pay Now'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Could not complete payment'), findsOneWidget);
    expect(find.text('FEE: RS. 150 · UNPAID'), findsOneWidget);

    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
  });

  testWidgets('Paid appointments do not offer a Pay Now action',
      (tester) async {
    stubPatientApi(appointments: const [_paidAppointment]);

    await _pumpPatientDashboard(tester);

    expect(find.text('FEE: RS. 150 · PAID'), findsOneWidget);
    expect(find.text('Pay Now'), findsNothing);
  });

  test('RazorpayPayment.open rejects unsupported desktop platforms', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await expectLater(
        RazorpayPayment.open(
          keyId: 'rzp_test_1a2b3c4d',
          orderId: 'order_Ov7t3nR9mK2pL',
          amount: 15000,
          currency: 'INR',
          description: 'OPD Consultation – Dr. Smith',
          name: 'Asha Verma',
          contact: '+919876543210',
          email: 'asha@example.com',
        ),
        throwsA(isA<StateError>()),
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}