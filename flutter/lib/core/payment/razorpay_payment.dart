import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'razorpay_web_stub.dart'
    if (dart.library.js_interop) 'razorpay_web.dart';

/// Result of a completed Razorpay checkout.
class RazorpayPaymentResult {
  const RazorpayPaymentResult({
    required this.paymentId,
    required this.orderId,
    required this.signature,
  });

  final String paymentId;
  final String orderId;
  final String signature;
}

/// Wraps the Razorpay checkout SDK so the patient payment flow can await the
/// outcome instead of juggling the plugin's event listeners — mirrors the web
/// app's `loadRazorpay()` + `new Razorpay(options)` handler in
/// `frontend/src/app/(dashboard)/patient/page.tsx`.
class RazorpayPayment {
  RazorpayPayment._();

  /// Test-only substitution for [open]. Widget tests replace the native/web
  /// SDK (neither is available under `flutter test`) with a fake and assert on
  /// the exact options the patient panel passes to the checkout.
  @visibleForTesting
  static Future<RazorpayPaymentResult?> Function({
    required String keyId,
    required String orderId,
    required int amount,
    required String currency,
    required String description,
    required String name,
    required String contact,
    required String email,
  })? debugOpenOverride;

  /// Opens the Razorpay checkout for a previously created order.
  ///
  /// Resolves with the payment details on success, `null` when the user
  /// dismisses/cancels the checkout, or throws an `Exception` on failure.
  ///
  /// On Android/iOS the native `razorpay_flutter` SDK is used; on web the
  /// official `checkout.js` is loaded via [RazorpayWeb]. Desktop platforms
  /// (Windows/macOS/Linux) are not supported by either and throw a clear error.
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
    final override = debugOpenOverride;
    if (override != null) {
      return override(
        keyId: keyId,
        orderId: orderId,
        amount: amount,
        currency: currency,
        description: description,
        name: name,
        contact: contact,
        email: email,
      );
    }
    if (kIsWeb) {
      return RazorpayWeb.open(
        keyId: keyId,
        orderId: orderId,
        amount: amount,
        currency: currency,
        description: description,
        name: name,
        contact: contact,
        email: email,
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return _openNative(
          keyId: keyId,
          orderId: orderId,
          amount: amount,
          currency: currency,
          description: description,
          name: name,
          contact: contact,
          email: email,
        );
      default:
        return Future.error(StateError(
          'Razorpay checkout is not available on desktop. '
          'Run the app on an Android emulator, a real device, or Chrome.',
        ));
    }
  }

  static Future<RazorpayPaymentResult?> _openNative({
    required String keyId,
    required String orderId,
    required int amount,
    required String currency,
    required String description,
    required String name,
    required String contact,
    required String email,
  }) {
    final razorpay = Razorpay();
    final completer = Completer<RazorpayPaymentResult?>();

    void onSuccess(PaymentSuccessResponse response) {
      if (completer.isCompleted) return;
      completer.complete(RazorpayPaymentResult(
        paymentId: response.paymentId ?? '',
        orderId: response.orderId ?? orderId,
        signature: response.signature ?? '',
      ));
    }

    void onError(PaymentFailureResponse response) {
      if (completer.isCompleted) return;
      if (response.code == Razorpay.PAYMENT_CANCELLED) {
        completer.complete(null);
      } else {
        completer.completeError(
          StateError(response.message ?? 'Payment failed'),
        );
      }
    }

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess);
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, onError);
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (_) {});

    try {
      razorpay.open({
        'key': keyId,
        'amount': amount,
        'currency': currency,
        'name': 'Aura Medical Center',
        'description': description,
        'order_id': orderId,
        'prefill': {
          'contact': contact,
          'email': email,
          'name': name,
        },
        'theme': {'color': '#12463E'},
      });
    } catch (e) {
      if (!completer.isCompleted) completer.completeError(e);
    }

    return completer.future.whenComplete(razorpay.clear);
  }
}
