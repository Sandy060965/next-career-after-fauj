import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/officer_account.dart';
import 'authenticated_http.dart';
import 'profile_repository.dart';

const _baseUrl = 'https://next-career-after-fauj-fitment.sandy060965.workers.dev';
const _appSharedKey = String.fromEnvironment('APP_SHARED_KEY');

class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class VerifyOtpResult {
  const VerifyOtpResult({required this.token, required this.refreshToken, required this.account});

  final String token;
  final String refreshToken;
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
      refreshToken: json['refreshToken'] as String,
      account: OfficerAccount.fromJson(json['officer'] as Map<String, dynamic>),
    );
  }

  /// Best-effort account refresh on launch — transparently refreshes the
  /// access token via [authenticatedPost] if it's expired, so this keeps
  /// working even though access tokens are now only 1 hour, not 30 days.
  Future<OfficerAccount?> fetchAccount(ProfileRepository profileRepository) async {
    final response = await authenticatedPost(profileRepository, '/me', {});
    if (response.statusCode != 200) return null;
    return OfficerAccount.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<http.Response> _post(String path, Map<String, dynamic> body) {
    return http.post(
      Uri.parse('$_baseUrl$path'),
      headers: {
        'content-type': 'application/json',
        'x-app-key': _appSharedKey,
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
