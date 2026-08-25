import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/models/officer_profile.dart';
import 'package:next_career_after_fauj/core/routing/app_routes.dart';
import 'package:next_career_after_fauj/core/services/file_picker_service.dart';
import 'package:next_career_after_fauj/core/services/profile_repository.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/core/utils/date_format.dart';
import 'package:next_career_after_fauj/features/onboarding/onboarding_screen.dart';
import 'package:next_career_after_fauj/features/profile/profile_screen.dart';
import 'package:provider/provider.dart';

Widget _appUnderTest({required Future<PickedFile?> Function() pickFile, ProfileRepository? repository}) {
  return ChangeNotifierProvider(
    create: (_) => repository ?? ProfileRepository(),
    child: MaterialApp(
      theme: AppTheme.light,
      initialRoute: AppRoutes.onboarding,
      routes: {
        AppRoutes.onboarding: (_) => OnboardingScreen(pickFile: pickFile),
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
/// — factored out so the redaction-review tests below don't repeat the
/// full ~15-step sequence the happy-path test above already covers in full.
Future<void> _completeStepsUpToCvUpload(WidgetTester tester) async {
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
    'CV-upload onboarding flow creates a profile and lands on Profile screen',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _appUnderTest(
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
      final expectedDob = formatDate(DateTime(now.year - 30, now.month, now.day));
      final expectedReleaseDate = formatDate(now);

      expect(find.text('My Profile'), findsOneWidget);
      expect(find.text('Major'), findsOneWidget);
      expect(find.text('Maj. A Verma'), findsOneWidget);
      expect(find.text(expectedDob), findsOneWidget);
      expect(find.text('12 yrs 5 mos'), findsOneWidget);
      expect(find.text('Tentative release date'), findsOneWidget);
      expect(find.text(expectedReleaseDate), findsOneWidget);
      expect(find.text('Army'), findsOneWidget);
      expect(find.text(OfficerSegment.pmr.fullLabel), findsOneWidget);
      expect(find.text('9876543210'), findsOneWidget);
      expect(find.text('a.verma@example.com'), findsOneWidget);
      expect(find.text('resume.pdf'), findsOneWidget);
      expect(find.text('Service number'), findsNothing);
    },
  );

  testWidgets(
    'pressing Continue with required fields empty shows a visible SnackBar, '
    'not just an off-screen inline error',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1400);
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

  testWidgets(
    'a .docx with flagged content shows the redaction review; confirming redacts checked '
    'items but keeps unchecked ones',
    (tester) async {
      tester.view.physicalSize = const Size(430, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = ProfileRepository();
      final docxBytes = _buildDocxBytes(
        'Experienced leader. Contact officer.name@example.com. Commanded a Battalion.',
      );

      await tester.pumpWidget(
        _appUnderTest(
          repository: repository,
          pickFile: () async => PickedFile(name: 'resume.docx', bytes: docxBytes),
        ),
      );
      await _completeStepsUpToCvUpload(tester);

      // Not pumpAndSettle: the upload panel's spinner animates indefinitely
      // while _pickCv awaits the dialog below, which would time out settle.
      await tester.tap(find.byKey(const Key('browseButton')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // The review dialog should appear with one row per unique flagged term.
      expect(find.text('Review before continuing'), findsOneWidget);
      expect(find.byKey(const Key('redactionCheckbox_officer.name@example.com')), findsOneWidget);
      expect(find.byKey(const Key('redactionCheckbox_Battalion')), findsOneWidget);

      // Uncheck the email — keep it; leave the unit term checked — redact it.
      // Still not pumpAndSettle: the dialog hasn't closed yet, so the
      // upload panel's spinner underneath is still animating.
      await tester.tap(find.byKey(const Key('redactionCheckbox_officer.name@example.com')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('confirmRedactionReviewButton')));
      await tester.pumpAndSettle();

      expect(find.text('Review before continuing'), findsNothing);
      expect(find.text('resume.docx'), findsOneWidget);

      await tester.tap(find.byKey(const Key('continueButton')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 6));

      final savedText = repository.profile?.cvExtractedText ?? '';
      expect(savedText, contains('officer.name@example.com'));
      expect(savedText, contains('[REDACTED]'));
      expect(savedText, isNot(contains('Battalion')));
    },
  );

  testWidgets('choosing "a different file" on the redaction review discards the upload',
      (tester) async {
    tester.view.physicalSize = const Size(430, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final docxBytes = _buildDocxBytes('Commanded a Battalion during operations.');

    await tester.pumpWidget(
      _appUnderTest(pickFile: () async => PickedFile(name: 'resume.docx', bytes: docxBytes)),
    );
    await _completeStepsUpToCvUpload(tester);

    await tester.tap(find.byKey(const Key('browseButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Review before continuing'), findsOneWidget);
    await tester.tap(find.byKey(const Key('cancelRedactionReviewButton')));
    await tester.pumpAndSettle();

    expect(find.text('Review before continuing'), findsNothing);
    expect(find.text('No file selected (PDF or Word)'), findsOneWidget);
  });

  testWidgets('a clean .docx with nothing flagged skips the review entirely', (tester) async {
    tester.view.physicalSize = const Size(430, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final docxBytes = _buildDocxBytes('Experienced operations leader with a strong record.');

    await tester.pumpWidget(
      _appUnderTest(pickFile: () async => PickedFile(name: 'resume.docx', bytes: docxBytes)),
    );
    await _completeStepsUpToCvUpload(tester);

    await tester.tap(find.byKey(const Key('browseButton')));
    await tester.pumpAndSettle();

    expect(find.text('Review before continuing'), findsNothing);
    expect(find.text('resume.docx'), findsOneWidget);
  });
}
