/// Login/session models mirroring the web app's `AdminData` and `Patient`
/// interfaces (`frontend/src/services/auth.service.ts`, `patient.service.ts`).

class AuthSession {
  const AuthSession({
    required this.token,
    required this.role,
    required this.userId,
    this.userName,
    this.email,
    this.phone,
  });

  final String token;
  final String role;
  final String userId;
  final String? userName;
  final String? email;
  final String? phone;

  /// The successful login response is the backend envelope:
  /// `{ data: {...user, access_token, token_type}, message, success }`.
  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final token =
        (json['access_token'] ?? json['token'] ?? '') as String;
    return AuthSession(
      token: token,
      role: (json['role'] ?? '') as String,
      userId: (json['user_id'] ?? json['id'] ?? '').toString(),
      userName: json['user_name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'token': token,
        'role': role,
        'user_id': userId,
        'user_name': userName,
        'email': email,
        'phone': phone,
      };
}

/// Response of `POST /api/patient/otp/send`.
class OtpSendResult {
  const OtpSendResult({required this.phone, this.demoOtp, this.expiresIn});

  final String phone;

  /// In dev mode the backend returns the generated OTP so the demo flow
  /// works without an SMS provider.
  final String? demoOtp;
  final int? expiresIn;

  factory OtpSendResult.fromJson(Map<String, dynamic> json) => OtpSendResult(
        phone: (json['phone'] ?? '') as String,
        demoOtp: json['otp'] as String?,
        expiresIn: json['expires_in'] as int?,
      );
}