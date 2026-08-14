import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thrown when the backend returns a non-2xx status or `success: false`.
///
/// Mirrors the error extraction used by the web app (`lib/api.ts`): the
/// backend error envelope is `{message}` and FastAPI-native errors use
/// `{detail}` (auth middleware, 422 validation).
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.data});

  final String message;
  final int? statusCode;
  final dynamic data;

  @override
  String toString() => message;
}

/// Thin JSON client for the FastAPI backend.
///
/// The web app calls the same base URL — see `frontend/src/lib/api.ts` and
/// `next.config.ts` (`BACKEND_URL`, default `http://localhost:8000`).
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  /// Base URL of the FastAPI backend.
  ///
  /// Defaults to the deployed backend; override at build/run time with
  /// `--dart-define=API_BASE_URL=http://localhost:8000` for local development.
  /// Android emulators reach the host machine via `10.0.2.2`.
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  static const String _defaultBaseUrl = 'https://hospital-management-96s6.onrender.com';

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    return _defaultBaseUrl;
  }

  String? _accessToken;

  /// The JWT used for authenticated requests (sent as `Authorization: Bearer`).
  String? get accessToken => _accessToken;

  set accessToken(String? token) => _accessToken = token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  Future<dynamic> get(String path) =>
      _send('GET', path, null);

  Future<dynamic> post(String path, [Object? body]) =>
      _send('POST', path, body);

  Future<dynamic> put(String path, [Object? body]) =>
      _send('PUT', path, body);

  Future<dynamic> delete(String path) => _send('DELETE', path, null);

  Future<dynamic> _send(String method, String path, Object? body) async {
    final uri = Uri.parse('$baseUrl$path');
    final encoded = body == null ? null : jsonEncode(body);

    final http.Response response;
    switch (method) {
      case 'POST':
        response = await http.post(uri, headers: _headers, body: encoded);
      case 'PUT':
        response = await http.put(uri, headers: _headers, body: encoded);
      case 'DELETE':
        response = await http.delete(uri, headers: _headers);
      default:
        response = await http.get(uri, headers: _headers);
    }

    dynamic json;
    try {
      json = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      json = null;
    }

    final isBackendError =
        json is Map && json['success'] == false;
    if (response.statusCode >= 400 || isBackendError) {
      if (response.statusCode == 401) _accessToken = null;
      throw ApiException(
        _extractErrorMessage(json),
        statusCode: response.statusCode,
        data: json,
      );
    }

    return json;
  }

  String _extractErrorMessage(dynamic json) {
    if (json == null) return 'Request failed';
    if (json is! Map) return 'Request failed';
    final message = json['message'];
    if (message is String && message.isNotEmpty) return message;
    final detail = json['detail'];
    if (detail is String && detail.isNotEmpty) return detail;
    if (detail is List && detail.isNotEmpty) {
      final first = detail.first;
      if (first is Map && first['msg'] is String) {
        return first['msg'] as String;
      }
      return detail.toString();
    }
    if (detail is Map && detail['msg'] is String) {
      return detail['msg'] as String;
    }
    return 'Request failed';
  }
}