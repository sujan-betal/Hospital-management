import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'auth_inputs.dart';

class PatientLoginForm extends StatefulWidget {
  const PatientLoginForm({super.key, this.onSendOtp, this.onVerify});

  /// Replace with real API calls once the network layer is wired up.
  final Future<String?> Function(String phone)? onSendOtp;
  final Future<bool> Function(String phone, String otp)? onVerify;

  @override
  State<PatientLoginForm> createState() => _PatientLoginFormState();
}

class _PatientLoginFormState extends State<PatientLoginForm> {
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  final _otpFocus = FocusNode();

  bool _otpSent = false;
  bool _captchaVerified = false;
  bool _submitting = false;
  bool _sending = false;
  int _countdown = 0;
  String? _demoOtp;
  String? _serverMessage;
  String? _phoneError;
  String? _otpError;
  String? _captchaError;
  Timer? _timer;

  static final RegExp _phoneRe = RegExp(r'^[+]?[\d\s()-]{6,20}$');

  bool get _phoneValid => _phoneRe.hasMatch(_phone.text.trim());

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phone.dispose();
    _otp.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  void _startCountdown(int seconds) {
    _timer?.cancel();
    setState(() => _countdown = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown <= 1) {
        timer.cancel();
        setState(() => _countdown = 0);
      } else {
        setState(() => _countdown = _countdown - 1);
      }
    });
  }

  Future<void> _sendOtp() async {
    if (!_phoneValid) {
      setState(() => _phoneError = 'Enter a valid phone number');
      return;
    }
    setState(() {
      _phoneError = null;
      _serverMessage = null;
      _demoOtp = null;
      _sending = true;
    });
    try {
      final demoCode = (widget.onSendOtp == null)
          ? _fakeOtp()
          : await widget.onSendOtp!(_phone.text.trim());
      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _sending = false;
        _demoOtp = demoCode ?? null;
        _serverMessage = demoCode == null
            ? 'OTP sent to ${_phone.text.trim()}'
            : 'OTP sent to ${_phone.text.trim()} · Demo mode: $demoCode';
      });
      _startCountdown(30);
      _otpFocus.requestFocus();
    } catch (e) {
      if (mounted) {
        setState(() {
          _sending = false;
          _phoneError = e.toString();
        });
      }
    }
  }

  String _fakeOtp() => (100000 + DateTime.now().millisecondsSinceEpoch % 900000)
      .toString();

  Future<void> _verify() async {
    final errs = <String>[];
    if (!_phoneValid) errs.add('phone');
    if (_otp.text.isEmpty) errs.add('otp');
    if (!_captchaVerified) errs.add('captcha');
    setState(() {
      _phoneError = errs.contains('phone') ? 'Enter a valid phone number' : null;
      _otpError = errs.contains('otp') ? 'Enter the OTP code' : null;
      _captchaError = errs.contains('captcha') ? "Please verify you're not a robot" : null;
    });
    if (errs.isNotEmpty) return;

    setState(() => _submitting = true);
    try {
      if (widget.onVerify != null) {
        await widget.onVerify!(_phone.text.trim(), _otp.text);
      }
    } catch (e) {
      if (mounted) setState(() => _otpError = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phone number',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            color: AppColors.textStrong,
          ),
        ),
        const SizedBox(height: 6),
        AuthTextField(
          controller: _phone,
          icon: Icons.smartphone,
          hintText: '+1 (555) 019-2834',
          keyboardType: TextInputType.phone,
          enabled: !_otpSent,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() => _phoneError = null),
        ),
        AuthErrorText(_phoneError),
        if (!_otpSent)
          const Padding(
            padding: EdgeInsets.only(top: 6, left: 2),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, size: 13, color: AppColors.emerald),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'No registration needed — just enter your phone number',
                    style: TextStyle(fontSize: 11, color: AppColors.textHint),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 14),

        if (!_otpSent)
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: (_phoneValid && !_sending) ? _sendOtp : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.30)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                disabledForegroundColor: AppColors.primary.withValues(alpha: 0.4),
              ),
              icon: _sending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Icon(Icons.send, size: 16),
              label: Text(_sending ? 'Sending OTP...' : 'Send OTP'),
            ),
          )
        else ...[
          const Text(
            'One-time code',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.inputBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _otpError != null ? AppColors.error : AppColors.inputBorder,
              ),
            ),
            child: TextField(
              controller: _otp,
              focusNode: _otpFocus,
              keyboardType: TextInputType.number,
              maxLength: 8,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                letterSpacing: 8,
                color: AppColors.textDark,
                fontWeight: FontWeight.w500,
              ),
              onChanged: (v) {
                final digits = v.replaceAll(RegExp(r'\D'), '');
                if (digits != v) {
                  _otp.value = TextEditingValue(
                    text: digits,
                    selection: TextSelection.collapsed(offset: digits.length),
                  );
                }
                setState(() => _otpError = null);
              },
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                hintText: '······',
                hintStyle: TextStyle(
                  fontSize: 18,
                  letterSpacing: 8,
                  color: AppColors.textFaint,
                ),
              ),
            ),
          ),
          AuthErrorText(_otpError),
          if (_serverMessage != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD1FAE5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      size: 14, color: AppColors.successDark),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _serverMessage!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.successDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_demoOtp != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Demo OTP:  $_demoOtp',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF92400E),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      _otp.text = _demoOtp!;
                      setState(() {});
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFCD34D)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.key, size: 12, color: Color(0xFF92400E)),
                          SizedBox(width: 4),
                          Text(
                            'Use code',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sent to ${_phone.text.trim().isEmpty ? 'your number' : _phone.text.trim()}',
                style: const TextStyle(fontSize: 12, color: AppColors.textBody),
              ),
              if (_countdown > 0)
                Text(
                  'Resend in ${_countdown}s',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w500,
                  ),
                )
              else
                GestureDetector(
                  onTap: _sending ? null : _sendOtp,
                  child: const Text(
                    'Resend OTP',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.accentRed,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 16),

        // Captcha box
        InkWell(
          onTap: () => setState(() {
            _captchaVerified = !_captchaVerified;
            _captchaError = null;
          }),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _captchaVerified
                  ? AppColors.primary.withValues(alpha: 0.06)
                  : AppColors.inputBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _captchaVerified
                    ? AppColors.primary.withValues(alpha: 0.40)
                    : AppColors.inputBorder,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _captchaVerified ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _captchaVerified
                          ? AppColors.primary
                          : AppColors.textFaint,
                      width: 2,
                    ),
                  ),
                  child: _captchaVerified
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "I'm not a robot",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _captchaVerified
                              ? AppColors.primary
                              : AppColors.textMid,
                        ),
                      ),
                      const Text(
                        'reCAPTCHA verification',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.verified_user,
                  size: 20,
                  color: _captchaVerified
                      ? AppColors.primary
                      : AppColors.textFaint,
                ),
              ],
            ),
          ),
        ),
        AuthErrorText(_captchaError),
        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: (_submitting || !_otpSent) ? null : _verify,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.7),
              foregroundColor: Colors.white,
              elevation: 6,
              shadowColor: AppColors.primary.withValues(alpha: 0.25),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Verify & login'),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}