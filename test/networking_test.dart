import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/models/officer_profile.dart';
import 'package:next_career_after_fauj/core/services/profile_repository.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/core/utils/date_format.dart';
import 'package:next_career_after_fauj/features/networking/network_directory_screen.dart';
import 'package:next_career_after_fauj/features/networking/network_models.dart';
import 'package:next_career_after_fauj/features/networking/network_opt_in_screen.dart';
import 'package:next_career_after_fauj/features/networking/network_service.dart'
    show NetworkService, NetworkServiceException;
import 'package:provider/provider.dart';

// Never actually used — every method the fake overrides makes an HTTP
// call, so the base class's real profileRepository is never touched.
final _unusedProfileRepository = ProfileRepository();

class _FakeNetworkService extends NetworkService {
  _FakeNetworkService({this.listing, this.optInError, this.optOutError})
      : super(profileRepository: _unusedProfileRepository);

  MentorPledge? listing;
  final Object? optInError;
  final Object? optOutError;

  final List<Map<String, dynamic>> optInCalls = [];
  bool optedOut = false;

  @override
  Future<void> optIn({
    required String displayName,
    required String email,
    required CallFrequency callFrequency,
    required int sessionMinutes,
    String? vertical,
    String? city,
    String? currentCompany,
    DateTime? joiningDate,
  }) async {
    if (optInError != null) throw optInError!;
    optInCalls.add({
      'displayName': displayName,
      'email': email,
      'callFrequency': callFrequency,
      'sessionMinutes': sessionMinutes,
      'vertical': vertical,
      'city': city,
      'currentCompany': currentCompany,
      'joiningDate': joiningDate,
    });
    listing = MentorPledge(
      officerId: 'me',
      displayName: displayName,
      email: email,
      callFrequency: callFrequency,
      sessionMinutes: sessionMinutes,
      vertical: vertical,
      city: city,
      currentCompany: currentCompany,
      joiningDate: joiningDate,
    );
  }

  @override
  Future<void> optOut() async {
    if (optOutError != null) throw optOutError!;
    optedOut = true;
    listing = null;
  }

  @override
  Future<MentorPledge?> myListing() async => listing;
}

OfficerProfile _profile() => OfficerProfile(
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
    );

Widget _wrap(Widget child, {ProfileRepository? repository}) {
  final repo = repository ?? (ProfileRepository()..saveProfile(_profile()));
  return ChangeNotifierProvider<ProfileRepository>.value(
    value: repo,
    child: MaterialApp(theme: AppTheme.light, home: child),
  );
}

void _setTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('NetworkDirectoryScreen', () {
    testWidgets('with no pledge yet, shows the empty state and a CTA to pledge', (tester) async {
      final fake = _FakeNetworkService();
      await tester.pumpWidget(_wrap(NetworkDirectoryScreen(networkService: fake)));
      await tester.pumpAndSettle();

      expect(find.text("You haven't pledged yet"), findsOneWidget);
      expect(find.byKey(const Key('becomeVolunteerButton')), findsOneWidget);
      // The old marketplace UI is gone entirely.
      expect(find.text('Browse Volunteers'), findsNothing);
      expect(find.text('My Sent Requests'), findsNothing);
      expect(find.text('Requests Waiting for You'), findsNothing);
    });

    testWidgets('with an existing pledge, shows its details plus Edit and Withdraw', (tester) async {
      final fake = _FakeNetworkService(
        listing: const MentorPledge(
          officerId: 'me',
          displayName: 'Lt Col A Verma',
          email: 'a.verma@example.com',
          callFrequency: CallFrequency.fortnightly,
          sessionMinutes: 60,
        ),
      );
      await tester.pumpWidget(_wrap(NetworkDirectoryScreen(networkService: fake)));
      await tester.pumpAndSettle();

      expect(find.text("You're pledged as a future mentor"), findsOneWidget);
      expect(find.text('Every fortnight · 60 min sessions'), findsOneWidget);
      expect(find.byKey(const Key('editListingButton')), findsOneWidget);
      expect(find.byKey(const Key('optOutButton')), findsOneWidget);
    });

    testWidgets('shows the joining date when one was pledged', (tester) async {
      final fake = _FakeNetworkService(
        listing: MentorPledge(
          officerId: 'me',
          displayName: 'Lt Col A Verma',
          email: 'a.verma@example.com',
          callFrequency: CallFrequency.weekly,
          sessionMinutes: 30,
          joiningDate: DateTime(2027, 8, 15),
        ),
      );
      await tester.pumpWidget(_wrap(NetworkDirectoryScreen(networkService: fake)));
      await tester.pumpAndSettle();

      expect(find.text('Joining: ${formatDate(DateTime(2027, 8, 15))}'), findsOneWidget);
    });

    testWidgets('tapping Withdraw clears the pledge and shows a confirmation', (tester) async {
      final fake = _FakeNetworkService(
        listing: const MentorPledge(
          officerId: 'me',
          displayName: 'Lt Col A Verma',
          email: 'a.verma@example.com',
          callFrequency: CallFrequency.weekly,
          sessionMinutes: 30,
        ),
      );
      await tester.pumpWidget(_wrap(NetworkDirectoryScreen(networkService: fake)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('optOutButton')));
      await tester.pumpAndSettle();

      expect(fake.optedOut, isTrue);
      expect(find.text("You haven't pledged yet"), findsOneWidget);
      expect(find.text('Your pledge has been withdrawn'), findsOneWidget);
    });

    testWidgets('a withdraw failure shows the error and keeps the pledge visible', (tester) async {
      final fake = _FakeNetworkService(
        listing: const MentorPledge(
          officerId: 'me',
          displayName: 'Lt Col A Verma',
          email: 'a.verma@example.com',
          callFrequency: CallFrequency.weekly,
          sessionMinutes: 30,
        ),
        optOutError: NetworkServiceException('Could not withdraw your pledge.'),
      );
      await tester.pumpWidget(_wrap(NetworkDirectoryScreen(networkService: fake)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('optOutButton')));
      await tester.pumpAndSettle();

      expect(find.text('Could not withdraw your pledge.'), findsOneWidget);
      expect(find.text("You're pledged as a future mentor"), findsOneWidget);
    });

    testWidgets('pledging navigates to the opt-in screen and reloads on save', (tester) async {
      _setTallViewport(tester);
      final fake = _FakeNetworkService();
      await tester.pumpWidget(_wrap(NetworkDirectoryScreen(networkService: fake)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('becomeVolunteerButton')));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Pledge to Mentor'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('saveListingButton')));
      await tester.tap(find.byKey(const Key('saveListingButton')));
      await tester.pumpAndSettle();

      expect(fake.optInCalls, hasLength(1));
      expect(find.text("You're pledged as a future mentor"), findsOneWidget);
    });
  });

  group('NetworkOptInScreen', () {
    testWidgets('prefills name and email from the officer profile', (tester) async {
      final fake = _FakeNetworkService();
      await tester.pumpWidget(_wrap(NetworkOptInScreen(networkService: fake)));

      expect(find.text('Lt Col A Verma'), findsOneWidget);
      expect(find.text('a.verma@example.com'), findsOneWidget);
    });

    testWidgets('requires a display name and a valid email', (tester) async {
      _setTallViewport(tester);
      final fake = _FakeNetworkService();
      await tester.pumpWidget(_wrap(NetworkOptInScreen(networkService: fake)));

      await tester.enterText(find.byKey(const Key('displayNameField')), '');
      await tester.enterText(find.byKey(const Key('emailField')), 'not-an-email');
      await tester.ensureVisible(find.byKey(const Key('saveListingButton')));
      await tester.tap(find.byKey(const Key('saveListingButton')));
      await tester.pumpAndSettle();

      expect(find.text('Required'), findsOneWidget);
      expect(find.text('Enter a valid email'), findsOneWidget);
      expect(fake.optInCalls, isEmpty);
    });

    testWidgets('saves with the chosen frequency, session length, and optional fields', (tester) async {
      _setTallViewport(tester);
      final fake = _FakeNetworkService();
      await tester.pumpWidget(_wrap(NetworkOptInScreen(networkService: fake)));

      await tester.enterText(find.byKey(const Key('verticalField')), 'IT Infrastructure & Cybersecurity');
      await tester.enterText(find.byKey(const Key('cityField')), 'Pune');
      await tester.enterText(find.byKey(const Key('companyField')), 'Acme Corp');

      await tester.tap(find.byKey(const Key('frequencyDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Every month').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('60 min'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('saveListingButton')));
      await tester.tap(find.byKey(const Key('saveListingButton')));
      await tester.pumpAndSettle();

      expect(fake.optInCalls, hasLength(1));
      final call = fake.optInCalls.single;
      expect(call['displayName'], 'Lt Col A Verma');
      expect(call['callFrequency'], CallFrequency.monthly);
      expect(call['sessionMinutes'], 60);
      expect(call['vertical'], 'IT Infrastructure & Cybersecurity');
      expect(call['city'], 'Pune');
      expect(call['currentCompany'], 'Acme Corp');
      expect(call['joiningDate'], isNull);
    });

    testWidgets('defaults to a 30-minute weekly pledge with no channel choice shown', (tester) async {
      _setTallViewport(tester);
      final fake = _FakeNetworkService();
      await tester.pumpWidget(_wrap(NetworkOptInScreen(networkService: fake)));

      // The old in-transition/transitioned channel radio is gone entirely.
      expect(find.text('Officer in transition'), findsNothing);
      expect(find.text('Already transitioned'), findsNothing);
      // The old day/time call-slot picker and referral toggle are gone.
      expect(find.text('Open to giving referrals'), findsNothing);

      await tester.ensureVisible(find.byKey(const Key('saveListingButton')));
      await tester.tap(find.byKey(const Key('saveListingButton')));
      await tester.pumpAndSettle();

      final call = fake.optInCalls.single;
      expect(call['callFrequency'], CallFrequency.weekly);
      expect(call['sessionMinutes'], 30);
    });

    testWidgets('picking and clearing a joining date works', (tester) async {
      _setTallViewport(tester);
      final fake = _FakeNetworkService();
      await tester.pumpWidget(_wrap(NetworkOptInScreen(networkService: fake)));

      expect(find.text('Not set'), findsOneWidget);

      await tester.tap(find.byKey(const Key('joiningDateField')));
      await tester.pumpAndSettle();
      // Confirm today's date in the picker without navigating months, so
      // the test doesn't depend on a specific target date being reachable.
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('Not set'), findsNothing);
      expect(find.byKey(const Key('clearJoiningDateButton')), findsOneWidget);

      await tester.tap(find.byKey(const Key('clearJoiningDateButton')));
      await tester.pumpAndSettle();

      expect(find.text('Not set'), findsOneWidget);
    });

    testWidgets('editing an existing pledge prefills its fields', (tester) async {
      final fake = _FakeNetworkService();
      final existing = MentorPledge(
        officerId: 'me',
        displayName: 'Lt Col A Verma',
        email: 'a.verma@example.com',
        callFrequency: CallFrequency.fortnightly,
        sessionMinutes: 60,
        vertical: 'Supply Chain & Procurement',
        city: 'Delhi',
        currentCompany: 'Acme Corp',
        joiningDate: DateTime(2027, 8, 15),
      );
      await tester.pumpWidget(_wrap(NetworkOptInScreen(existing: existing, networkService: fake)));

      expect(find.text('Supply Chain & Procurement'), findsOneWidget);
      expect(find.text('Delhi'), findsOneWidget);
      expect(find.text('Acme Corp'), findsOneWidget);
      expect(find.text(formatDate(DateTime(2027, 8, 15))), findsOneWidget);
    });

    testWidgets('a save failure shows the error instead of failing silently', (tester) async {
      _setTallViewport(tester);
      final fake = _FakeNetworkService(optInError: NetworkServiceException('Could not save your pledge.'));
      await tester.pumpWidget(_wrap(NetworkOptInScreen(networkService: fake)));

      await tester.ensureVisible(find.byKey(const Key('saveListingButton')));
      await tester.tap(find.byKey(const Key('saveListingButton')));
      await tester.pumpAndSettle();

      expect(find.text('Could not save your pledge.'), findsOneWidget);
    });
  });
}
