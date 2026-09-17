import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/models/officer_account.dart';
import 'package:next_career_after_fauj/core/models/officer_profile.dart';
import 'package:next_career_after_fauj/core/routing/app_routes.dart';
import 'package:next_career_after_fauj/core/services/file_picker_service.dart';
import 'package:next_career_after_fauj/core/services/profile_repository.dart';
import 'package:next_career_after_fauj/core/services/session_storage.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/onboarding/onboarding_screen.dart';
import 'package:next_career_after_fauj/features/profile/profile_screen.dart';
import 'package:next_career_after_fauj/features/start_here/start_here_screen.dart';
import 'package:provider/provider.dart';

// SessionStorage wraps FlutterSecureStorage, which has no platform
// implementation in a plain `flutter test` VM run — its method-channel calls
// hang rather than failing fast, so saveSession() called directly (not via
// a UI-driven flow) hangs this test forever the moment it's called. An
// in-memory fake avoids the platform channel entirely — same fix as
// app_routing_test.dart's _FakeSessionStorage.
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

Widget _appUnderTest({required Future<PickedFile?> Function() pickFile, ProfileRepository? repository}) {
  return ChangeNotifierProvider(
    create: (_) => repository ?? ProfileRepository(),
    child: MaterialApp(
      theme: AppTheme.light,
      initialRoute: AppRoutes.onboarding,
      routes: {
        AppRoutes.onboarding: (_) => OnboardingScreen(pickFile: pickFile),
        AppRoutes.startHere: (_) => const StartHereScreen(),
        AppRoutes.profile: (_) => const ProfileScreen(),
      },
    ),
  );
}

/// Builds real, minimal .docx bytes (a zip containing just word/document.xml)
/// with [bodyText] as a single paragraph — enough for extractDocxText to
/// parse, so these tests exercise the real extraction + scan path rather
/// than a fake.
Uint8List _buildDocxBytes(String bodyText) {
  const xmlTemplate = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body><w:p><w:r><w:t>{{BODY}}</w:t></w:r></w:p></w:body>
</w:document>''';
  final xml = xmlTemplate.replaceFirst('{{BODY}}', bodyText);
  final archive = Archive();
  final bytes = utf8.encode(xml);
  archive.addFile(ArchiveFile('word/document.xml', bytes.length, bytes));
  return Uint8List.fromList(ZipEncoder().encode(archive)!);
}

/// Drives every onboarding step up to (but not including) picking a CV file
/// — factored out so the CV-upload-focused tests below don't repeat the
/// full ~15-step sequence the happy-path test above already covers in full.
Future<void> _completeStepsUpToCvUpload(WidgetTester tester, {String? corpsOrArm}) async {
  await tester.tap(find.byKey(const Key('serviceDropdown')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Army').last);
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const Key('rankDropdown')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Major').last);
  await tester.pumpAndSettle();

  if (corpsOrArm != null) {
    await tester.tap(find.byKey(const Key('corpsOrArmDropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(corpsOrArm).last);
    await tester.pumpAndSettle();
  }

  await tester.enterText(find.byKey(const Key('nameField')), 'Maj. A Verma');

  await tester.tap(find.byKey(const Key('dobField')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const Key('workExperienceYearsDropdown')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('12').last);
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const Key('workExperienceMonthsDropdown')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('5').last);
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const Key('releaseStatus_tentative')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('releaseDateField')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();

  await tester.enterText(find.byKey(const Key('mobileField')), '9876543210');
  await tester.enterText(find.byKey(const Key('emailField')), 'a.verma@example.com');
  await tester.tap(find.byKey(const Key('consentCheckbox')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('continueButton')));
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const Key('segment_pmr')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('continueButton')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'CV-upload onboarding flow creates a profile and lands on the Start Here guided intro',
    (tester) async {
      tester.view.physicalSize = const Size(430, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = ProfileRepository();
      await tester.pumpWidget(
        _appUnderTest(
          repository: repository,
          pickFile: () async => PickedFile(name: 'resume.pdf', bytes: Uint8List(0)),
        ),
      );

      // Step 1: service verification, in the required
      // service / rank / name / DOB / work experience / mobile / email
      // sequence. Rank is dependent on Service, so Service must be picked
      // first for the Rank dropdown's options to populate.
      await tester.tap(find.byKey(const Key('serviceDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Army').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('rankDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Major').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('nameField')), 'Maj. A Verma');

      await tester.tap(find.byKey(const Key('dobField')));
      await tester.pumpAndSettle();
      // Accept the picker's default initialDate (30 years before today)
      // rather than interacting with the calendar grid.
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('workExperienceYearsDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('12').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('workExperienceMonthsDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('5').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('releaseStatus_tentative')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('releaseDateField')));
      await tester.pumpAndSettle();
      // Accept the picker's default initialDate (today, since none is set).
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('mobileField')), '9876543210');
      await tester.enterText(find.byKey(const Key('emailField')), 'a.verma@example.com');
      await tester.tap(find.byKey(const Key('consentCheckbox')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('continueButton')));
      await tester.pumpAndSettle();

      // Step 2: segment — one of three (SSC / PMR / Superannuation).
      await tester.tap(find.byKey(const Key('segment_pmr')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('continueButton')));
      await tester.pumpAndSettle();

      // Step 3: CV upload — the only intake path (no ACR / service-record
      // field, no structured-entry alternative).
      await tester.tap(find.byKey(const Key('browseButton')));
      await tester.pumpAndSettle();
      expect(find.text('resume.pdf'), findsOneWidget);
      await tester.tap(find.byKey(const Key('continueButton')));
      await tester.pumpAndSettle();
      // Navigation doesn't wait on the background CV-file write (it's
      // best-effort persistence), but its safety-net timeout Timer is
      // still pending in this test's FakeAsync zone — pump it forward so
      // the timer fires and the test doesn't finish with pending timers.
      await tester.pump(const Duration(seconds: 6));

      final now = DateTime.now();
      final expectedDob = DateTime(now.year - 30, now.month, now.day);
      final expectedReleaseDate = DateTime(now.year, now.month, now.day);

      // A brand-new profile lands on the one-time guided intro, not
      // straight back into the app.
      expect(find.text('Welcome — a few quick steps first'), findsOneWidget);
      expect(find.text('My Profile'), findsNothing);

      final profile = repository.profile!;
      expect(profile.rank, 'Major');
      expect(profile.fullName, 'Maj. A Verma');
      expect(profile.dateOfBirth, expectedDob);
      expect(profile.workExperienceYears, 12);
      expect(profile.workExperienceMonths, 5);
      expect(profile.releaseStatus, ReleaseStatus.tentative);
      expect(profile.releaseDate, expectedReleaseDate);
      expect(profile.service, OfficerService.army);
      expect(profile.segment, OfficerSegment.pmr);
      expect(profile.mobileNumber, '9876543210');
      expect(profile.email, 'a.verma@example.com');
      expect(profile.cvFileName, 'resume.pdf');
    },
  );

  testWidgets(
    'submitting onboarding with no CV selected is not blocked and still creates a profile',
    (tester) async {
      tester.view.physicalSize = const Size(430, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = ProfileRepository();
      await tester.pumpWidget(
        _appUnderTest(repository: repository, pickFile: () async => null),
      );
      await _completeStepsUpToCvUpload(tester);

      // No file picked — go straight to submit.
      await tester.tap(find.byKey(const Key('continueButton')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Upload your CV to continue'), findsNothing);
      await tester.pumpAndSettle();

      expect(find.text('Welcome — a few quick steps first'), findsOneWidget);
      expect(repository.profile?.cvFileName, '');
    },
  );

  testWidgets(
    'a free-text self-description is used as the CV when no file is uploaded',
    (tester) async {
      tester.view.physicalSize = const Size(430, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = ProfileRepository();
      await tester.pumpWidget(
        _appUnderTest(repository: repository, pickFile: () async => null),
      );
      await _completeStepsUpToCvUpload(tester);

      await tester.enterText(
        find.byKey(const Key('selfDescriptionField')),
        'Lt Col with 18 years in the Army Service Corps, led logistics for a 500-person unit.',
      );
      await tester.tap(find.byKey(const Key('continueButton')));
      await tester.pumpAndSettle();

      expect(repository.profile?.cvFileName, 'Self-described background');
      expect(
        repository.profile?.cvExtractedText,
        'Lt Col with 18 years in the Army Service Corps, led logistics for a 500-person unit.',
      );
    },
  );

  testWidgets(
    'an uploaded CV takes priority over a free-text self-description',
    (tester) async {
      tester.view.physicalSize = const Size(430, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = ProfileRepository();
      await tester.pumpWidget(
        _appUnderTest(
          repository: repository,
          pickFile: () async => PickedFile(name: 'resume.pdf', bytes: Uint8List.fromList([1, 2, 3])),
        ),
      );
      await _completeStepsUpToCvUpload(tester);

      // Type a self-description first, then upload a file — the file wins.
      await tester.enterText(
        find.byKey(const Key('selfDescriptionField')),
        'Ignored once a real CV is uploaded.',
      );
      await tester.tap(find.byKey(const Key('browseButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('continueButton')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 6));

      expect(repository.profile?.cvFileName, 'resume.pdf');
    },
  );

  testWidgets(
    'the CV upload step offers an explicit "Skip for now" action that creates the profile',
    (tester) async {
      tester.view.physicalSize = const Size(430, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = ProfileRepository();
      await tester.pumpWidget(
        _appUnderTest(repository: repository, pickFile: () async => null),
      );
      await _completeStepsUpToCvUpload(tester);

      expect(find.byKey(const Key('skipCvButton')), findsOneWidget);
      await tester.tap(find.byKey(const Key('skipCvButton')));
      await tester.pumpAndSettle();

      expect(find.text('Welcome — a few quick steps first'), findsOneWidget);
      expect(repository.profile?.cvFileName, '');
    },
  );

  testWidgets(
    'pressing Continue with required fields empty shows a visible SnackBar, '
    'not just an off-screen inline error',
    (tester) async {
      tester.view.physicalSize = const Size(430, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_appUnderTest(pickFile: () async => null));

      await tester.tap(find.byKey(const Key('continueButton')));
      await tester.pump(); // let the SnackBar animation start
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Please fill in all required fields correctly.'), findsOneWidget);
    },
  );

  testWidgets('a .docx CV upload extracts its text and saves it to the profile', (tester) async {
    tester.view.physicalSize = const Size(430, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = ProfileRepository();
    final docxBytes = _buildDocxBytes('Experienced operations leader with a strong record.');

    await tester.pumpWidget(
      _appUnderTest(
        repository: repository,
        pickFile: () async => PickedFile(name: 'resume.docx', bytes: docxBytes),
      ),
    );
    await _completeStepsUpToCvUpload(tester);

    await tester.tap(find.byKey(const Key('browseButton')));
    await tester.pumpAndSettle();

    expect(find.text('resume.docx'), findsOneWidget);

    await tester.tap(find.byKey(const Key('continueButton')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 6));

    expect(repository.profile?.cvExtractedText, contains('Experienced operations leader'));
  });

  testWidgets('an optional Corps/Arm selection is captured and persisted to the profile',
      (tester) async {
    tester.view.physicalSize = const Size(430, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = ProfileRepository();
    await tester.pumpWidget(
      _appUnderTest(
        repository: repository,
        pickFile: () async => PickedFile(name: 'resume.pdf', bytes: Uint8List(0)),
      ),
    );
    await _completeStepsUpToCvUpload(tester, corpsOrArm: 'Corps of Signals');

    await tester.tap(find.byKey(const Key('browseButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('continueButton')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 6));

    expect(repository.profile?.corpsOrArm, 'Corps of Signals');
  });

  testWidgets('leaving Corps/Arm unselected leaves the profile field null', (tester) async {
    tester.view.physicalSize = const Size(430, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = ProfileRepository();
    await tester.pumpWidget(
      _appUnderTest(
        repository: repository,
        pickFile: () async => PickedFile(name: 'resume.pdf', bytes: Uint8List(0)),
      ),
    );
    await _completeStepsUpToCvUpload(tester);

    await tester.tap(find.byKey(const Key('browseButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('continueButton')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 6));

    expect(repository.profile?.corpsOrArm, isNull);
  });

  testWidgets('a PDF larger than the size limit is rejected with a clear reason', (tester) async {
    tester.view.physicalSize = const Size(430, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final oversized = Uint8List(kMaxUploadPdfBytes + 1);
    await tester.pumpWidget(
      _appUnderTest(pickFile: () async => PickedFile(name: 'huge-scan.pdf', bytes: oversized)),
    );
    await _completeStepsUpToCvUpload(tester);

    await tester.tap(find.byKey(const Key('browseButton')));
    await tester.pumpAndSettle();

    expect(find.textContaining('larger than $kMaxUploadPdfMb MB'), findsOneWidget);
    // Rejected — no filename should be shown as if the upload succeeded.
    expect(find.text('huge-scan.pdf'), findsNothing);
  });

  testWidgets(
      'editing a profile whose stored rank/corpsOrArm no longer match the dropdown '
      "lists clears them instead of crashing on Flutter's own DropdownButton assertion",
      (tester) async {
    tester.view.physicalSize = const Size(430, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // A profile whose rank/corpsOrArm are free-form strings that don't
    // exactly match any entry in kRanksByService/kCorpsByService for Army
    // — e.g. data saved before a future wording change to either list, or
    // (as actually happened) a shorthand written directly rather than
    // picked from the dropdown.
    final mismatchedProfile = OfficerProfile(
      rank: 'Col', // real values are the full word, e.g. "Colonel"
      fullName: 'Col A K Sharma',
      dateOfBirth: DateTime(1973, 5, 10),
      workExperienceYears: 22,
      workExperienceMonths: 0,
      releaseStatus: ReleaseStatus.tentative,
      releaseDate: DateTime(2027, 6, 30),
      service: OfficerService.army,
      mobileNumber: '9876543210',
      email: 'a.sharma@example.com',
      segment: OfficerSegment.pmr,
      cvFileName: 'resume.pdf',
      corpsOrArm: 'Not A Real Corps',
    );
    final repository = ProfileRepository()..saveProfile(mismatchedProfile);

    // The crash this guards against happens on the very first build, in
    // initState — reaching this pumpWidget call at all without a thrown
    // exception is the actual regression test.
    await tester.pumpWidget(
      _appUnderTest(repository: repository, pickFile: () async => null),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Colonel'), findsNothing);
    expect(find.text('Select service first'), findsNothing); // service itself is still prefilled
    expect(find.text('Required'), findsNothing); // no validation run yet, just an empty field
  });

  testWidgets(
      'a fresh sign-in with no local profile prefills rank/name/service from a backend-known '
      'progress summary, but still requires consent before continuing',
      (tester) async {
    tester.view.physicalSize = const Size(430, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = ProfileRepository()
      ..setProgressPrefill(
        const OfficerProgressPrefill(
          rank: 'Colonel',
          fullName: 'Col A K Sharma',
          service: 'army',
          segment: 'pmr',
        ),
      );

    await tester.pumpWidget(
      _appUnderTest(repository: repository, pickFile: () async => null),
    );
    await tester.pumpAndSettle();

    // Rank/name/service came from the backend-known summary...
    expect(find.text('Colonel'), findsOneWidget);
    expect(find.text('Col A K Sharma'), findsOneWidget);
    // ...but DOB/release date/mobile/email aren't tracked server-side and
    // are left blank, and consent is never implicitly given by a prefill.
    await tester.tap(find.byKey(const Key('continueButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Please fill in all required fields correctly.'), findsOneWidget);

    // Consumed once — reading it again shouldn't still return the prefill.
    expect(repository.progressPrefill, isNull);
  });

  testWidgets(
      'a fresh Google sign-in prefills the email field from the account instead of asking again',
      (tester) async {
    tester.view.physicalSize = const Size(430, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = ProfileRepository(sessionStorage: _FakeSessionStorage());
    await repository.saveSession(
      'token',
      const OfficerAccount(
        id: 'officer-1',
        email: 'mohit@example.com',
        entitlementTier: EntitlementTier.free,
        entitlementExpiresAt: null,
      ),
      refreshToken: 'refresh-token',
    );

    await tester.pumpWidget(
      _appUnderTest(repository: repository, pickFile: () async => null),
    );
    await tester.pumpAndSettle();

    final emailField = tester.widget<TextFormField>(find.byKey(const Key('emailField')));
    expect(emailField.controller?.text, 'mohit@example.com');
  });
}
