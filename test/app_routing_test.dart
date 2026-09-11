import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/models/officer_account.dart';
import 'package:next_career_after_fauj/core/models/officer_profile.dart';
import 'package:next_career_after_fauj/core/services/profile_repository.dart';
import 'package:next_career_after_fauj/core/services/session_storage.dart';
import 'package:next_career_after_fauj/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

// SessionStorage wraps FlutterSecureStorage, which has no platform
// implementation in a plain `flutter test` VM run — its method-channel calls
// hang rather than failing fast, so saveSession() would otherwise hang this
// test file forever the moment it's called (this is the first test file in
// the suite to ever call saveSession). An in-memory fake avoids the
// platform channel entirely.
class _FakeSessionStorage implements SessionStorage {
  String? token;
  String? refreshToken;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> saveToken(String value) async => token = value;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> saveRefreshToken(String value) async => refreshToken = value;

  @override
  Future<void> clearToken() async {
    token = null;
    refreshToken = null;
  }
}

// Regression coverage for a real incident: a browser that loaded the app at
// a URL naming a specific route directly (rather than a plain, route-less
// visit) skipped phone verification entirely and landed straight on a blank
// onboarding form, with no session ever created. The fix moved every route
// (not just the one Flutter resolves at first launch) through a single
// onGenerateRoute guard — these tests exercise that guard directly, the way
// a real browser navigation would, rather than mounting screens in
// isolation as most other tests in this suite do.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpAppAt(WidgetTester tester, ProfileRepository repo, {String? initialRoute}) async {
    await tester.pumpWidget(
      NextCareerAfterFaujApp(profileRepository: repo, syncProgress: (_) async {}),
    );
    await tester.pumpAndSettle();
    if (initialRoute != null) {
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pushNamedAndRemoveUntil(initialRoute, (route) => false);
      await tester.pumpAndSettle();
    }
  }

  testWidgets('a fresh app with no session lands on phone verification', (tester) async {
    final repo = ProfileRepository();
    await pumpAppAt(tester, repo);

    expect(find.byKey(const Key('googleSignInButton')), findsOneWidget);
  });

  testWidgets(
      'requesting a protected route directly with no session redirects to phone verification, '
      'not the requested screen', (tester) async {
    final repo = ProfileRepository();
    await pumpAppAt(tester, repo, initialRoute: '/career-readiness');

    expect(find.byKey(const Key('googleSignInButton')), findsOneWidget);
    expect(find.text('Transition Readiness Index'), findsNothing);
  });

  testWidgets('the onboarding route with no session also redirects to phone verification',
      (tester) async {
    final repo = ProfileRepository();
    await pumpAppAt(tester, repo, initialRoute: '/');

    expect(find.byKey(const Key('googleSignInButton')), findsOneWidget);
  });

  testWidgets('the admin route is reachable with no officer session', (tester) async {
    final repo = ProfileRepository();
    await pumpAppAt(tester, repo, initialRoute: '/admin');

    expect(find.byKey(const Key('adminKeyField')), findsOneWidget);
  });

  testWidgets('a returning officer with a session and a profile lands on the dashboard, not onboarding',
      (tester) async {
    final repo = ProfileRepository(sessionStorage: _FakeSessionStorage());
    await repo.saveSession(
      'token',
      const OfficerAccount(
        id: 'officer-1',
        mobileNumber: '9876543210',
        entitlementTier: EntitlementTier.free,
        entitlementExpiresAt: null,
      ),
      refreshToken: 'refresh',
    );
    repo.saveProfile(
      OfficerProfile(
        rank: 'Lt Col',
        fullName: 'Lt Col A Verma',
        dateOfBirth: DateTime(1978, 5, 10),
        workExperienceYears: 18,
        workExperienceMonths: 2,
        releaseStatus: ReleaseStatus.tentative,
        releaseDate: DateTime(2027, 6, 30),
        service: OfficerService.army,
        mobileNumber: '9876543210',
        email: 'a.verma@example.com',
        segment: OfficerSegment.pmr,
        cvFileName: 'resume.pdf',
      ),
    );

    await pumpAppAt(tester, repo);

    expect(find.byKey(const Key('mainNavBar')), findsOneWidget);
    expect(find.text('Officer Onboarding'), findsNothing);
  });

  testWidgets('requesting Start Here directly with no session redirects to phone verification',
      (tester) async {
    final repo = ProfileRepository();
    await pumpAppAt(tester, repo, initialRoute: '/start-here');

    expect(find.byKey(const Key('googleSignInButton')), findsOneWidget);
    expect(find.text('Welcome — a few quick steps first'), findsNothing);
  });

  testWidgets('a signed-in officer on Start Here can skip straight to the dashboard, and the '
      'guided-intro flag is remembered', (tester) async {
    final repo = ProfileRepository(sessionStorage: _FakeSessionStorage());
    await repo.saveSession(
      'token',
      const OfficerAccount(
        id: 'officer-1',
        mobileNumber: '9876543210',
        entitlementTier: EntitlementTier.free,
        entitlementExpiresAt: null,
      ),
      refreshToken: 'refresh',
    );
    repo.saveProfile(
      OfficerProfile(
        rank: 'Major',
        fullName: 'Maj A Verma',
        dateOfBirth: DateTime(1988, 5, 10),
        workExperienceYears: 12,
        workExperienceMonths: 0,
        releaseStatus: ReleaseStatus.tentative,
        releaseDate: DateTime(2027, 6, 30),
        service: OfficerService.army,
        mobileNumber: '9876543210',
        email: 'a.verma@example.com',
        segment: OfficerSegment.ssc,
        cvFileName: '',
      ),
    );

    await pumpAppAt(tester, repo, initialRoute: '/start-here');
    expect(find.text('Welcome — a few quick steps first'), findsOneWidget);
    expect(repo.hasSeenGuidedIntro, isFalse);

    await tester.tap(find.byKey(const Key('skipStartHereButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mainNavBar')), findsOneWidget);
    expect(repo.hasSeenGuidedIntro, isTrue);
  });

  testWidgets('a session with no profile yet lands on onboarding, not the dashboard', (tester) async {
    final repo = ProfileRepository(sessionStorage: _FakeSessionStorage());
    await repo.saveSession(
      'token',
      const OfficerAccount(
        id: 'officer-1',
        mobileNumber: '9876543210',
        entitlementTier: EntitlementTier.free,
        entitlementExpiresAt: null,
      ),
      refreshToken: 'refresh',
    );

    await pumpAppAt(tester, repo);

    expect(find.text('Officer Onboarding'), findsOneWidget);
    expect(find.byKey(const Key('mainNavBar')), findsNothing);
    expect(find.byKey(const Key('phoneField')), findsNothing);
  });
}
