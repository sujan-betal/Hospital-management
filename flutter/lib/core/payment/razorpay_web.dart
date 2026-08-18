import 'dart:async';

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'razorpay_payment.dart';

/// The global `Razorpay` constructor exposed by `checkout.js`.
@JS('Razorpay')
extension type RazorpayCheckout(JSObject _) implements JSObject {
  external void open();
}

/// Razorpay checkout on the web, driven by the official `checkout.js` script.
///
/// `razorpay_flutter` only ships native Android/iOS channels, so on Flutter web
/// we load the script and drive it directly — the same approach the web app
/// uses in `frontend/src/app/(dashboard)/patient/page.tsx`.
class RazorpayWeb {
  RazorpayWeb._();

  static const String _checkoutUrl =
      'https://checkout.razorpay.com/v1/checkout.js';

  static Future<RazorpayPaymentResult?> open({
    required String keyId,
    required String orderId,
    required int amount,
    required String currency,
    required String description,
    required String name,
    required String contact,
    required String email,
  }) async {
    final checkout = await ensureLoaded();
    if (checkout == null) {
      throw StateError(
        'Payment gateway could not be loaded. Please check your connection.',
      );
    }

    final completer = Completer<RazorpayPaymentResult?>();

    void onDismiss(JSAny? _) {
      if (completer.isCompleted) return;
      completer.complete(null);
    }

    void onSuccess(JSAny? response) {
      if (completer.isCompleted) return;
      final data = response as JSObject?;
      final paymentId = data?['razorpay_payment_id'] as JSString?;
      final respOrderId = data?['razorpay_order_id'] as JSString?;
      final signature = data?['razorpay_signature'] as JSString?;
      completer.complete(RazorpayPaymentResult(
        paymentId: paymentId?.toDart ?? '',
        orderId: respOrderId?.toDart ?? orderId,
        signature: signature?.toDart ?? '',
      ));
    }

    final prefill = JSObject()
      ..['contact'] = contact.toJS
      ..['email'] = email.toJS
      ..['name'] = name.toJS;

    final theme = JSObject()..['color'] = '#12463E'.toJS;

    final modal = JSObject()..['ondismiss'] = onDismiss.toJS;

    final options = JSObject()
      ..['key'] = keyId.toJS
      ..['amount'] = amount.toJS
      ..['currency'] = currency.toJS
      ..['name'] = 'Aura Medical Center'.toJS
      ..['description'] = description.toJS
      ..['order_id'] = orderId.toJS
      ..['prefill'] = prefill
      ..['theme'] = theme
      ..['modal'] = modal
      ..['handler'] = onSuccess.toJS;

    final instance = checkout.callAsConstructor<JSObject>(options);
    (instance as RazorpayCheckout).open();

    return completer.future;
  }

  /// Returns the global `Razorpay` constructor if the script already loaded.
  static JSFunction? _findCheckout() {
    final existing = globalContext['Razorpay'];
    return existing is JSFunction ? existing : null;
  }

  /// Inject the checkout script (once) and wait for the global `Razorpay`
  /// constructor to appear. Returns `null` if it never loads.
  static Future<JSFunction?> ensureLoaded() async {
    final cached = _findCheckout();
    if (cached != null) return cached;

    final document = globalContext['document'] as JSObject;
    final head = document['head'] as JSObject;
    final script =
        document.callMethod<JSObject>('createElement'.toJS, 'script'.toJS);
    script['src'] = _checkoutUrl.toJS;
    script['async'] = true.toJS;
    head.callMethod<JSAny?>('appendChild'.toJS, script);

    for (var i = 0; i < 100; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final ctor = _findCheckout();
      if (ctor != null) return ctor;
    }
    return null;
  }
}
