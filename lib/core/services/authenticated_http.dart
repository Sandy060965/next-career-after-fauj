import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/officer_account.dart';
import 'profile_repository.dart';

const _baseUrl = 'https://next-career-after-fauj-fitment.sandy060965.workers.dev';
const _appSharedKey = String.fromEnvironment('APP_SHARED_KEY');

/// POSTs to [path] with the officer's current access token. Access tokens
/// are short-lived (1 hour) by design, so on a 401 this makes exactly one
/// silent refresh-and-retry via /auth/refresh before giving up — the
/// officer never notices their token expired mid-session, without the app
/// having to carry a long-lived bearer credential.
Future<http.Response> authenticatedPost(
  ProfileRepository profileRepository,
  String path,
  Map<String, dynamic> body,
) async {
  final encodedBody = jsonEncode(body);

  Future<http.Response> attempt(String token) => http.post(
        Uri.parse('$_baseUrl$path'),
        headers: {
          'content-type': 'application/json',
          'x-app-key': _appSharedKey,
          'authorization': 'Bearer $token',
        },
        body: encodedBody,
      );

  final token = profileRepository.sessionToken;
  if (token == null) {
    throw StateError('authenticatedPost called with no session token');
  }

  var response = await attempt(token);
  if (response.statusCode == 401) {
    final refreshedToken = await _tryRefresh(profileRepository);
    if (refreshedToken != null) {
      response = await attempt(refreshedToken);
    }
  }
  return response;
}

Future<String?> _tryRefresh(ProfileRepository profileRepository) async {
  final refreshToken = profileRepository.refreshToken;
  if (refreshToken == null) return null;

  try {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/refresh'),
      headers: const {'content-type': 'application/json', 'x-app-key': _appSharedKey},
      body: jsonEncode({'refreshToken': refreshToken}),
    );
    if (response.statusCode != 200) return null;

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final newToken = json['token'] as String;
    final newRefreshToken = json['refreshToken'] as String;
    final account = OfficerAccount.fromJson(json['officer'] as Map<String, dynamic>);
    await profileRepository.saveSession(newToken, account, refreshToken: newRefreshToken);
    return newToken;
  } catch (_) {
    return null;
  }
}

/// Best-effort server-side revocation of a refresh token — called on sign
/// out so the token can't be replayed later. Never throws: sign-out must
/// always succeed locally even if this call fails.
Future<void> revokeRefreshToken(String refreshToken) async {
  try {
    await http.post(
      Uri.parse('$_baseUrl/auth/logout'),
      headers: const {'content-type': 'application/json', 'x-app-key': _appSharedKey},
      body: jsonEncode({'refreshToken': refreshToken}),
    );
  } catch (_) {
    // Best-effort — the local session is already cleared regardless.
  }
}
