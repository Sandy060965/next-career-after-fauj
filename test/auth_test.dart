import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/models/officer_account.dart';
import 'package:next_career_after_fauj/core/routing/app_routes.dart';
import 'package:next_career_after_fauj/core/services/auth_service.dart';
import 'package:next_career_after_fauj/core/services/profile_repository.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/auth/otp_entry_screen.dart';
import 'package:next_career_after_fauj/features/auth/phone_verification_screen.dart';
import 'package:provider/provider.dart';

class _FakeAuthService extends AuthService {
  _FakeAuthService({this.requestOtpError});

  final List<String> requestedNumbers = [];
  final List<String> verifiedCodes = [];
  final Object? requestOtpError;

  @override
  Future<void> requestOtp(String mobileNumber) async {
    requestedNumbers.add(mobileNumber);
    if (requestOtpError != null) throw requestOtpError!;
  }

  @override
  Future<VerifyOtpResult> verifyOtp({required String mobileNumber, required String code}) async {
    verifiedCodes.add(code);
    return const VerifyOtpResult(
      token: 'test-token',
      account: OfficerAccount(
        id: 'officer-1',
        mobileNumber: '9876543210',
        entitlementTier: EntitlementTier.free,
        entitlementExpiresAt: null,
      ),
    );
  }
}

Widget _wrapPhoneScreen(AuthService authService) {
  return MaterialApp(theme: AppTheme.light, home: PhoneVerificationScreen(authService: authService));
}

Widget _wrapOtpScreen(AuthService authService, {ProfileRepository? repository}) {
  return ChangeNotifierProvider<ProfileRepository>.value(
    value: repository ?? ProfileRepository(),
    child: MaterialApp(
      theme: AppTheme.light,
      initialRoute: '/otp',
      routes: {
        '/otp': (_) => OtpEntryScreen(mobileNumber: '9876543210', authService: authService),
        AppRoutes.onboarding: (_) => const Scaffold(body: Text('Onboarding screen')),
        AppRoutes.profile: (_) => const Scaffold(body: Text('Profile screen')),
      },
    ),
  );
}

void main() {
  group('PhoneVerificationScreen', () {
    testWidgets('rejects an invalid mobile number without calling the service', (tester) async {
      final authService = _FakeAuthService();
      await tester.pumpWidget(_wrapPhoneScreen(authService));

      await tester.enterText(find.byKey(const Key('phoneField')), '123');
      await tester.tap(find.byKey(const Key('sendCodeButton')));
      await tester.pump();

      expect(find.text('Enter a valid 10-digit mobile number'), findsOneWidget);
      expect(authService.requestedNumbers, isEmpty);
    });

    testWidgets('sends the code and navigates to OTP entry on a valid number', (tester) async {
      final authService = _FakeAuthService();
      await tester.pumpWidget(_wrapPhoneScreen(authService));

      await tester.enterText(find.byKey(const Key('phoneField')), '9876543210');
      await tester.tap(find.byKey(const Key('sendCodeButton')));
      await tester.pumpAndSettle();

      expect(authService.requestedNumbers, ['9876543210']);
      expect(find.text('Enter code'), findsOneWidget);
      expect(find.textContaining('+91 9876543210'), findsOneWidget);
    });

    testWidgets('shows an error message when the service call fails', (tester) async {
      final authService = _FakeAuthService(requestOtpError: AuthException('Could not send code'));
      await tester.pumpWidget(_wrapPhoneScreen(authService));

      await tester.enterText(find.byKey(const Key('phoneField')), '9876543210');
      await tester.tap(find.byKey(const Key('sendCodeButton')));
      await tester.pump();
      await tester.pump();

      expect(find.text('Could not send code'), findsOneWidget);
    });
  });

  group('OtpEntryScreen', () {
    testWidgets('verifying a code saves the session and navigates to onboarding when no profile exists',
        (tester) async {
      final authService = _FakeAuthService();
      final repository = ProfileRepository();
      await tester.pumpWidget(_wrapOtpScreen(authService, repository: repository));

      await tester.enterText(find.byKey(const Key('otpField')), '123456');
      await tester.tap(find.byKey(const Key('verifyOtpButton')));
      await tester.pumpAndSettle();

      expect(authService.verifiedCodes, ['123456']);
      expect(repository.sessionToken, 'test-token');
      expect(repository.account?.id, 'officer-1');
      expect(find.text('Onboarding screen'), findsOneWidget);
    });

    testWidgets('rejects a short code without calling the service', (tester) async {
      final authService = _FakeAuthService();
      await tester.pumpWidget(_wrapOtpScreen(authService));

      await tester.enterText(find.byKey(const Key('otpField')), '123');
      await tester.tap(find.byKey(const Key('verifyOtpButton')));
      await tester.pump();

      expect(find.text('Enter the 6-digit code'), findsOneWidget);
      expect(authService.verifiedCodes, isEmpty);
    });

    testWidgets('resend button calls requestOtp again', (tester) async {
      final authService = _FakeAuthService();
      await tester.pumpWidget(_wrapOtpScreen(authService));

      await tester.tap(find.byKey(const Key('resendCodeButton')));
      await tester.pumpAndSettle();

      expect(authService.requestedNumbers, ['9876543210']);
      expect(find.text('Code resent'), findsOneWidget);
    });
  });
}
