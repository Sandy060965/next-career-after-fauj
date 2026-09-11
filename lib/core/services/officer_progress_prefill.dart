import 'dart:convert';

import 'authenticated_http.dart';
import 'profile_repository.dart';

/// Overridable in tests so a fresh-sign-in widget test never makes a real
/// network call just by mounting the app — see PhoneVerificationScreen and
/// OtpEntryScreen, which take this as an injectable constructor param.
typedef FetchProgressPrefill = Future<OfficerProgressPrefill?> Function(ProfileRepository repo);

/// Best-effort — a failed fetch just means onboarding starts blank, same as
/// it always has. Only worth calling when the officer has no local profile.
/// See [OfficerProgressPrefill] (profile_repository.dart) for the shape.
///
/// Named httpFetch... (not fetchProgressPrefill) to avoid colliding with
/// the identically-named constructor field this defaults on
/// PhoneVerificationScreen/OtpEntryScreen — `this.fetchProgressPrefill =
/// fetchProgressPrefill` reads as a self-reference to Dart and fails to
/// compile.
Future<OfficerProgressPrefill?> httpFetchProgressPrefill(ProfileRepository repo) async {
  try {
    final response = await authenticatedPost(repo, '/officer-progress/me', const {});
    if (response.statusCode != 200) return null;
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final progress = decoded['progress'] as Map<String, dynamic>?;
    if (progress == null) return null;
    return OfficerProgressPrefill.fromJson(progress);
  } catch (_) {
    return null;
  }
}
