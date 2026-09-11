import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/models/officer_account.dart';
import 'package:next_career_after_fauj/core/routing/app_routes.dart';
import 'package:next_career_after_fauj/core/services/auth_service.dart';
import 'package:next_career_after_fauj/core/services/google_auth_service.dart';
import 'package:next_career_after_fauj/core/services/profile_repository.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/auth/phone_verification_screen.dart';
import 'package:provider/provider.dart';

class _FakeGoogleAuthService extends GoogleAuthService {
  _FakeGoogleAuthService({this.signInError});

  final Object? signInError;
  int signInCalls = 0;

  @override
  Future<VerifyOtpResult> signIn() async {
    signInCalls++;
    if (signInError != null) throw signInError!;
    return const VerifyOtpResult(
      token: 'google-token',
      refreshToken: 'google-refresh-token',
      account: OfficerAccount(
        id: 'officer-1',
        email: 'officer@example.com',
        entitlementTier: EntitlementTier.free,
        entitlementExpiresAt: null,
      ),
    );
  }
}

// PhoneVerificationScreen defaults fetchProgressPrefill to the real HTTP
// call — every test must override it to a no-op, or it'll fire a real
// network call against the live backend and hang pumpAndSettle.
Future<OfficerProgressPrefill?> _noProgressPrefill(ProfileRepository repo) async => null;

Widget _wrapPhoneScreen(GoogleAuthService googleAuthService, {ProfileRepository? repository}) {
  return ChangeNotifierProvider<ProfileRepository>.value(
    value: repository ?? ProfileRepository(),
    child: MaterialApp(
      theme: AppTheme.light,
      initialRoute: '/verify',
      routes: {
        '/verify': (_) => PhoneVerificationScreen(
              googleAuthService: googleAuthService,
              fetchProgressPrefill: _noProgressPrefill,
            ),
        AppRoutes.onboarding: (_) => const Scaffold(body: Text('Onboarding screen')),
        AppRoutes.profile: (_) => const Scaffold(body: Text('Profile screen')),
      },
    ),
  );
}

void main() {
  group('PhoneVerificationScreen — Google Sign-In', () {
    testWidgets('tapping the Google button signs in, saves the session, and navigates to onboarding '
        'when no profile exists', (tester) async {
      final googleAuthService = _FakeGoogleAuthService();
      final repository = ProfileRepository();
      await tester.pumpWidget(_wrapPhoneScreen(googleAuthService, repository: repository));

      await tester.tap(find.byKey(const Key('googleSignInButton')));
      await tester.pumpAndSettle();

      expect(googleAuthService.signInCalls, 1);
      expect(repository.sessionToken, 'google-token');
      expect(repository.refreshToken, 'google-refresh-token');
      expect(repository.account?.id, 'officer-1');
      expect(find.text('Onboarding screen'), findsOneWidget);
    });

    testWidgets('a cancelled or failed sign-in shows an error and does not save a session or navigate',
        (tester) async {
      final googleAuthService = _FakeGoogleAuthService(
        signInError: AuthException('Sign-in was cancelled.'),
      );
      final repository = ProfileRepository();
      await tester.pumpWidget(_wrapPhoneScreen(googleAuthService, repository: repository));

      await tester.tap(find.byKey(const Key('googleSignInButton')));
      await tester.pumpAndSettle();

      expect(find.text('Sign-in was cancelled.'), findsOneWidget);
      expect(repository.sessionToken, isNull);
      expect(find.text('Onboarding screen'), findsNothing);
      expect(find.text('Profile screen'), findsNothing);
    });
  });
}
