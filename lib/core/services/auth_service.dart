import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/officer_account.dart';

const _baseUrl = 'https://next-career-after-fauj-fitment.sandy060965.workers.dev';
const _appSharedKey = String.fromEnvironment('APP_SHARED_KEY');

class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class VerifyOtpResult {
  const VerifyOtpResult({required this.token, required this.account});

  final String token;
  final OfficerAccount account;
}

/// Phone-OTP login against the Worker's /auth/* and /me endpoints. Deliberately
/// no auto-retry here (unlike the other HTTP services) — retrying a failed
/// OTP send or check could double-send an SMS or trip Twilio's rate limits;
/// the UI surfaces a "resend" action instead so retries are explicit.
class AuthService {
  Future<void> requestOtp(String mobileNumber) async {
    final response = await _post('/auth/request-otp', {'mobileNumber': mobileNumber});
    if (response.statusCode != 200) {
      throw AuthException(_errorMessage(response, fallback: 'Could not send verification code.'));
    }
  }

  Future<VerifyOtpResult> verifyOtp({required String mobileNumber, required String code}) async {
    final response = await _post('/auth/verify-otp', {'mobileNumber': mobileNumber, 'code': code});
    if (response.statusCode != 200) {
      throw AuthException(_errorMessage(response, fallback: 'Invalid or expired code.'));
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return VerifyOtpResult(
      token: json['token'] as String,
      account: OfficerAccount.fromJson(json['officer'] as Map<String, dynamic>),
    );
  }

  Future<OfficerAccount?> fetchAccount(String token) async {
    final response = await _post('/me', {}, token: token);
    if (response.statusCode != 200) return null;
    return OfficerAccount.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<http.Response> _post(String path, Map<String, dynamic> body, {String? token}) {
    return http.post(
      Uri.parse('$_baseUrl$path'),
      headers: {
        'content-type': 'application/json',
        'x-app-key': _appSharedKey,
        if (token != null) 'authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
  }

  String _errorMessage(http.Response response, {required String fallback}) {
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['error'] as String? ?? fallback;
    } catch (_) {
      return fallback;
    }
  }
}
