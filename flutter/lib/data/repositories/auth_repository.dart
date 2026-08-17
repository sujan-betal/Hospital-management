import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_client.dart';
import '../models/auth_models.dart';

/// Handles the login API calls + session persistence.
///
/// Storage keys mirror the web app, which keeps the token in localStorage
/// under `access_token` and the user record under `user`.
class AuthRepository {
  AuthRepository._();

  static const String _tokenKey = 'access_token';
  static const String _userKey = 'user';

  /// Raw body fields of the authenticated user (persisted alongside the token).
  static Map<String, dynamic>? _cachedUser;

  static Map<String, dynamic>? get cachedUser =>
      _cachedUser == null ? null : Map<String, dynamic>.from(_cachedUser!);

  /// Unified staff login. The backend resolves the account across Admin,
  /// Doctor and Receptionist tables by username/email.
  ///
  /// `POST /api/admin/login` → `{ data: {...user, access_token}, ... }`
  static Future<AuthSession> loginStaff({
    required String identifier,
    required String password,
  }) async {
    final json = await ApiClient.instance
        .post('/api/admin/login', {'email': identifier, 'password': password});
    return _handleSession(json);
  }

  /// Dedicated doctor login (also requires a password set via the reset link).
  ///
  /// `POST /api/doctor/login` → `{ data: {...doctor, access_token}, ... }`
  static Future<AuthSession> loginDoctor({
    required String identifier,
    required String password,
  }) async {
    final json = await ApiClient.instance
        .post('/api/doctor/login', {'email': identifier, 'password': password});
    return _handleSession(json);
  }

  /// `POST /api/patient/otp/send` → `{ data: {phone, otp?, expires_in}, ... }`
  static Future<OtpSendResult> sendPatientOtp(String phone) async {
    final json = await ApiClient.instance.post('/api/patient/otp/send', {
      'phone': phone,
    });
    return OtpSendResult.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// `POST /api/doctor/forgot-password` → sends a password-set link to the email
  /// if an account exists (doctors, admins, receptionists).
  static Future<void> forgotPassword({required String email}) async {
    await ApiClient.instance.post('/api/doctor/forgot-password', {
      'email': email,
    });
  }

  /// `POST /api/doctor/reset-password` → sets a new password from a reset token.
  static Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await ApiClient.instance.post('/api/doctor/reset-password', {
      'token': token,
      'new_password': newPassword,
    });
  }

  /// `POST /api/patient/otp/verify` → `{ data: {...patient, access_token} }`
  static Future<AuthSession> verifyPatientOtp({
    required String phone,
    required String otp,
  }) async {
    final json = await ApiClient.instance.post('/api/patient/otp/verify', {
      'phone': phone,
      'otp': otp,
    });
    return _handleSession(json);
  }

  /// Restore a previously saved session at app start.
  static Future<AuthSession?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) return null;
    final rawUser = prefs.getString(_userKey);
    final user = rawUser == null ? null : jsonDecode(rawUser);
    if (user is! Map<String, dynamic>) return null;
    _cachedUser = user;
    ApiClient.instance.accessToken = token;
    return AuthSession.fromJson({...user, 'access_token': token});
  }

  /// Persist the session (token + user) so it survives restarts.
  static Future<void> saveSession(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, session.token);
    await prefs.setString(_userKey, jsonEncode(_cachedUser ?? session.toJson()));
    ApiClient.instance.accessToken = session.token;
  }

  /// Clear the stored token + user (logout).
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    _cachedUser = null;
    ApiClient.instance.accessToken = null;
  }

  static AuthSession _handleSession(dynamic json) {
    final data = (json['data'] ?? {}) as Map<String, dynamic>;
    final session = AuthSession.fromJson(data);
    if (session.token.isEmpty) {
      throw const ApiException('Login failed: no access token returned');
    }
    final user = Map<String, dynamic>.from(data)..remove('access_token');
    _cachedUser = user;
    ApiClient.instance.accessToken = session.token;
    return session;
  }
}