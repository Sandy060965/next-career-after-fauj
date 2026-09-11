import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../models/officer_account.dart';
import 'auth_service.dart';

const _baseUrl = 'https://next-career-after-fauj-fitment.sandy060965.workers.dev';
const _appSharedKey = String.fromEnvironment('APP_SHARED_KEY');
const _googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

/// Google Sign-In against Google's own OAuth directly — no Firebase. The
/// same GOOGLE_CLIENT_ID (a Web-application OAuth Client ID) is used here as
/// [serverClientId] and on the Worker as the expected `aud` claim, which is
/// what makes the resulting ID token verifiable server-side without Firebase
/// in the loop.
///
/// Exchanges an ID token with /auth/google-signin the same way phone-OTP
/// exchanges a verified code, returning the identical [VerifyOtpResult]
/// shape so the post-auth flow (saveSession, then navigate to profile-or-
/// onboarding) can be reused verbatim rather than duplicated.
///
/// [signIn] (interactive `authenticate()`) only works on non-web platforms —
/// `google_sign_in_web` explicitly does not support it, since web requires
/// rendering Google's own button widget instead of an app-triggered popup.
/// The web button (features/auth/google_native_button_web.dart) calls
/// [ensureInitialized] and [exchangeIdToken] directly instead of [signIn].
class GoogleAuthService {
  bool _initialized = false;

  /// Public so the web-only native button widget can initialize the same
  /// singleton before calling `renderButton()`, without duplicating the
  /// clientId/serverClientId platform split below.
  Future<void> ensureInitialized() async {
    if (_initialized) return;
    // google_sign_in_web asserts serverClientId is null on web — the same
    // OAuth Web-application Client ID is passed as clientId there instead
    // (or auto-detected from web/index.html's google-signin-client_id meta
    // tag), and the resulting ID token's `aud` claim is that same client ID
    // either way, so the backend's single GOOGLE_CLIENT_ID check works
    // unchanged across platforms.
    await GoogleSignIn.instance.initialize(
      clientId: kIsWeb ? _googleServerClientId : null,
      serverClientId: kIsWeb ? null : _googleServerClientId,
    );
    _initialized = true;
  }

  /// Runs the native interactive Google account picker (non-web only), then
  /// exchanges the resulting ID token with the backend. Throws
  /// [AuthException] (the same type phone-OTP uses) on cancellation or any
  /// failure, so callers get one consistent error-handling path regardless
  /// of which sign-in method ran.
  Future<VerifyOtpResult> signIn() async {
    await ensureInitialized();

    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw AuthException('Sign-in was cancelled.');
      }
      throw AuthException('Could not sign in with Google.');
    }

    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw AuthException('Could not get a Google sign-in token.');
    }
    return exchangeIdToken(idToken);
  }

  /// Exchanges an already-obtained Google ID token with the backend —
  /// shared by [signIn] (non-web) and the web native-button widget, which
  /// gets its ID token from an authentication-event stream instead of a
  /// direct `authenticate()` return value.
  Future<VerifyOtpResult> exchangeIdToken(String idToken) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/google-signin'),
      headers: {'content-type': 'application/json', 'x-app-key': _appSharedKey},
      body: jsonEncode({'idToken': idToken}),
    );
    if (response.statusCode != 200) {
      throw AuthException(_errorMessage(response));
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return VerifyOtpResult(
      token: json['token'] as String,
      refreshToken: json['refreshToken'] as String,
      account: OfficerAccount.fromJson(json['officer'] as Map<String, dynamic>),
    );
  }

  String _errorMessage(http.Response response) {
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['error'] as String? ?? 'Could not sign in with Google.';
    } catch (_) {
      return 'Could not sign in with Google.';
    }
  }
}
