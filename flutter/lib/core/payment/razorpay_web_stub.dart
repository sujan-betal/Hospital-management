import 'razorpay_payment.dart';

/// Non-web placeholder for [RazorpayWeb]. The real implementation lives in
/// `razorpay_web.dart` and is selected via a conditional import when the app
/// compiles for the web (see `razorpay_payment.dart`). This stub is never
/// invoked at runtime — the caller routes on `kIsWeb` before reaching it.
class RazorpayWeb {
  RazorpayWeb._();

  static Future<RazorpayPaymentResult?> open({
    required String keyId,
    required String orderId,
    required int amount,
    required String currency,
    required String description,
    required String name,
    required String contact,
    required String email,
  }) {
    return Future.error(StateError(
      'Razorpay checkout is not available on this platform. '
      'Run the app on an Android emulator, a real device, or Chrome.',
    ));
  }
}
