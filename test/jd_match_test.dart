import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/models/officer_profile.dart';
import 'package:next_career_after_fauj/core/services/file_picker_service.dart';
import 'package:next_career_after_fauj/core/services/profile_repository.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/cv_civilianizer/civilianized_cv.dart';
import 'package:next_career_after_fauj/features/fitment/fitment_result.dart';
import 'package:next_career_after_fauj/features/fitment/fitment_service.dart';
import 'package:next_career_after_fauj/features/jd_match/jd_match_screen.dart';
import 'package:next_career_after_fauj/features/jd_match/sample_jd_service.dart';
import 'package:provider/provider.dart';

/// Builds real, minimal .docx bytes (a zip containing just word/document.xml)
/// with [bodyText] as a single paragraph — same helper as
/// onboarding_flow_test.dart, so this exercises real extraction, not a stub.
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

const _stubResult = FitmentResult(
  fitmentScore: 8,
  scoreRationale: 'Test rationale',
  requirementBreakdown: [],
  originalCvExcerpt: 'Original excerpt',
  refinedCv: 'Refined excerpt',
  dimensionGaps: [],
  gapRoadmap: [],
);

Future<FitmentResult> _stubAnalyzeFitment({
  required String jdText,
  Uint8List? jdPdfBytes,
  required String cvFileName,
  String? cvExtractedText,
  Uint8List? cvPdfBytes,
}) async =>
    _stubResult;

Future<String> _stubGenerateSampleJd({required String vertical, required String tier}) async =>
    'Generated JD for $vertical at $tier level.';

Widget _appUnderTest({
  required Future<PickedFile?> Function() pickFile,
  FitmentAnalyzer analyzeFitment = _stubAnalyzeFitment,
  SampleJdGenerator generateSampleJd = _stubGenerateSampleJd,
  ProfileRepository? repository,
}) {
  return ChangeNotifierProvider(
    create: (_) => repository ?? ProfileRepository(),
    child: MaterialApp(
      theme: AppTheme.light,
      home: JdMatchScreen(
        pickFile: pickFile,
        analyzeFitment: analyzeFitment,
        generateSampleJd: generateSampleJd,
      ),
      onGenerateRoute: (settings) => MaterialPageRoute(
        builder: (_) => Scaffold(body: Text('route:${settings.name}')),
      ),
    ),
  );
}

void main() {
  testWidgets('the no-CV banner\'s Add CV button opens the CV upload sheet', (tester) async {
    await tester.pumpWidget(_appUnderTest(pickFile: () async => null));

    expect(find.byKey(const Key('jdMatchNoCvBanner')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('jdMatchAddCvButton')));
    await tester.tap(find.byKey(const Key('jdMatchAddCvButton')));
    await tester.pumpAndSettle();

    expect(find.text('Upload your CV'), findsOneWidget);
  });

  testWidgets('the no-CV banner\'s Build CV button navigates to CV Builder', (tester) async {
    await tester.pumpWidget(_appUnderTest(pickFile: () async => null));

    await tester.ensureVisible(find.byKey(const Key('jdMatchBuildCvButton')));
    await tester.tap(find.byKey(const Key('jdMatchBuildCvButton')));
    await tester.pumpAndSettle();

    expect(find.text('route:/cv-builder'), findsOneWidget);
  });

  testWidgets('pasting a JD and checking match navigates to the fitment score screen',
      (tester) async {
    await tester.pumpWidget(_appUnderTest(pickFile: () async => null));

    // Submitting empty shows a validation error instead of a fake result.
    await tester.ensureVisible(find.byKey(const Key('checkMatchButton')));
    await tester.tap(find.byKey(const Key('checkMatchButton')));
    await tester.pumpAndSettle();
    expect(find.text('Paste a job description to continue'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('jdTextField')),
      'Looking for a logistics manager with 10 years experience.',
    );
    await tester.ensureVisible(find.byKey(const Key('checkMatchButton')));
    await tester.tap(find.byKey(const Key('checkMatchButton')));
    await tester.pumpAndSettle();

    expect(find.text('Fitment Score'), findsOneWidget);
    // Scaled to /100 to match the Transition Index's "CV & JD Fit" display.
    expect(find.text('80'), findsOneWidget);
  });

  testWidgets('tapping "Paste from clipboard" fills the JD field from the clipboard',
      (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall methodCall) async {
        if (methodCall.method == 'Clipboard.getData') {
          return {'text': 'Looking for a supply chain lead with ERP experience.'};
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(_appUnderTest(pickFile: () async => null));

    // No CV on this fresh repository, so the "add a CV" banner pushes the
    // paste button further down than the default test viewport shows.
    await tester.ensureVisible(find.byKey(const Key('jdPasteButton')));
    await tester.tap(find.byKey(const Key('jdPasteButton')));
    await tester.pumpAndSettle();

    expect(find.text('Looking for a supply chain lead with ERP experience.'), findsOneWidget);
  });

  testWidgets('uploading a JD file extracts its real text, not just the filename',
      (tester) async {
    String? capturedJdText;
    Future<FitmentResult> capturingAnalyzeFitment({
      required String jdText,
      Uint8List? jdPdfBytes,
      required String cvFileName,
      String? cvExtractedText,
      Uint8List? cvPdfBytes,
    }) async {
      capturedJdText = jdText;
      return _stubResult;
    }

    final docxBytes = _buildDocxBytes('Looking for a logistics manager with 10 years experience.');

    await tester.pumpWidget(
      _appUnderTest(
        pickFile: () async => PickedFile(name: 'job-description.docx', bytes: docxBytes),
        analyzeFitment: capturingAnalyzeFitment,
      ),
    );

    await tester.tap(find.byKey(const Key('jdInput_upload')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('checkMatchButton')));
    await tester.tap(find.byKey(const Key('checkMatchButton')));
    await tester.pumpAndSettle();
    expect(find.text('Upload a job description to continue'), findsOneWidget);

    await tester.tap(find.byKey(const Key('jdBrowseButton')));
    await tester.pumpAndSettle();
    expect(find.text('job-description.docx'), findsWidgets);

    await tester.ensureVisible(find.byKey(const Key('checkMatchButton')));
    await tester.tap(find.byKey(const Key('checkMatchButton')));
    await tester.pumpAndSettle();

    expect(find.text('Fitment Score'), findsOneWidget);
    // The regression this guards: the analyzer must receive the real
    // extracted text, not the bare filename it used to get.
    expect(capturedJdText, 'Looking for a logistics manager with 10 years experience.');
  });

  testWidgets('uploading a JD PDF sends the raw bytes and caches them for reuse', (tester) async {
    String? capturedJdText;
    Uint8List? capturedJdPdfBytes;
    Future<FitmentResult> capturingAnalyzeFitment({
      required String jdText,
      Uint8List? jdPdfBytes,
      required String cvFileName,
      String? cvExtractedText,
      Uint8List? cvPdfBytes,
    }) async {
      capturedJdText = jdText;
      capturedJdPdfBytes = jdPdfBytes;
      return _stubResult;
    }

    final pdfBytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46]); // "%PDF" — content is opaque to the app.
    final repository = ProfileRepository();

    await tester.pumpWidget(
      ChangeNotifierProvider<ProfileRepository>.value(
        value: repository,
        child: MaterialApp(
          theme: AppTheme.light,
          home: JdMatchScreen(
            pickFile: () async => PickedFile(name: 'job-description.pdf', bytes: pdfBytes),
            analyzeFitment: capturingAnalyzeFitment,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('jdInput_upload')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('jdBrowseButton')));
    await tester.pumpAndSettle();
    expect(find.text('job-description.pdf'), findsWidgets);
    // No client-side extraction for PDF — no "reading" spinner/error state.
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('checkMatchButton')));
    await tester.tap(find.byKey(const Key('checkMatchButton')));
    await tester.pumpAndSettle();

    expect(find.text('Fitment Score'), findsOneWidget);
    expect(capturedJdPdfBytes, pdfBytes);
    // jdText is just the filename fallback when bytes are sent — the
    // backend ignores it once jdPdfBase64 is present.
    expect(capturedJdText, 'job-description.pdf');

    // Cached for downstream reuse (Interview Prep, Compensation) the same
    // way a PDF CV's bytes are cached — not as a bare, useless filename
    // string under lastJdText.
    expect(repository.lastJdPdfBytes, pdfBytes);
    expect(repository.lastJdText, isNull);
  });

  testWidgets('a JD PDF larger than the size limit is rejected with a clear reason', (tester) async {
    final oversized = Uint8List(kMaxUploadPdfBytes + 1);

    await tester.pumpWidget(
      _appUnderTest(pickFile: () async => PickedFile(name: 'huge-jd.pdf', bytes: oversized)),
    );

    await tester.tap(find.byKey(const Key('jdInput_upload')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('jdBrowseButton')));
    await tester.pumpAndSettle();

    expect(find.textContaining('larger than $kMaxUploadPdfMb MB'), findsOneWidget);
    expect(find.text('huge-jd.pdf'), findsNothing);
  });

  testWidgets(
      'prefers a civilianized/built CV over the raw uploaded CV when the officer has completed one',
      (tester) async {
    String? capturedCvText;
    Uint8List? capturedCvPdfBytes;
    Future<FitmentResult> capturingAnalyzeFitment({
      required String jdText,
      Uint8List? jdPdfBytes,
      required String cvFileName,
      String? cvExtractedText,
      Uint8List? cvPdfBytes,
    }) async {
      capturedCvText = cvExtractedText;
      capturedCvPdfBytes = cvPdfBytes;
      return _stubResult;
    }

    final repository = ProfileRepository()
      ..saveProfile(
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
          cvExtractedText: 'Raw military-language CV text',
        ),
      );
    await repository.saveCivilianizedCv(
      const CivilianizedCv(civilianizedCv: 'Civilian-ready CV text', translations: []),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<ProfileRepository>.value(
        value: repository,
        child: MaterialApp(
          theme: AppTheme.light,
          home: JdMatchScreen(
            pickFile: () async => null,
            analyzeFitment: capturingAnalyzeFitment,
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('jdTextField')),
      'Looking for a logistics manager with 10 years experience.',
    );
    await tester.ensureVisible(find.byKey(const Key('checkMatchButton')));
    await tester.tap(find.byKey(const Key('checkMatchButton')));
    await tester.pumpAndSettle();

    expect(find.text('Fitment Score'), findsOneWidget);
    expect(capturedCvText, 'Civilian-ready CV text');
    // The civilianized CV is text-only — the original PDF bytes must not
    // be sent alongside it, or the backend would analyse the raw CV instead.
    expect(capturedCvPdfBytes, isNull);
  });

  testWidgets('a .docx that fails to extract shows an error instead of silently using the filename',
      (tester) async {
    await tester.pumpWidget(
      _appUnderTest(
        pickFile: () async => PickedFile(name: 'corrupt.docx', bytes: Uint8List.fromList([1, 2, 3])),
      ),
    );

    await tester.tap(find.byKey(const Key('jdInput_upload')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('jdBrowseButton')));
    await tester.pumpAndSettle();

    expect(find.textContaining("Couldn't read this file's text"), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('checkMatchButton')));
    await tester.tap(find.byKey(const Key('checkMatchButton')));
    await tester.pumpAndSettle();
    expect(find.text('Fitment Score'), findsNothing);
  });

  group('Generate a JD with AI', () {
    testWidgets('selecting it hides Check match and shows the vertical picker', (tester) async {
      await tester.pumpWidget(_appUnderTest(pickFile: () async => null));

      await tester.tap(find.byKey(const Key('jdInput_generate')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('checkMatchButton')), findsNothing);
      expect(find.byKey(const Key('generateVerticalDropdown')), findsOneWidget);
      expect(find.byKey(const Key('generateJdButton')), findsOneWidget);
    });

    testWidgets('the picker still populates with no completed Vertical Fit assessment',
        (tester) async {
      await tester.pumpWidget(_appUnderTest(pickFile: () async => null));

      await tester.tap(find.byKey(const Key('jdInput_generate')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('generateVerticalDropdown')));
      await tester.tap(find.byKey(const Key('generateVerticalDropdown')));
      await tester.pumpAndSettle();

      // The full (unranked) universe is offered as dropdown menu items.
      expect(find.text('Operations & Process Excellence — Operations Manager'), findsWidgets);
    });

    testWidgets('picking a vertical and generating shows the JD with Copy/Download',
        (tester) async {
      await tester.pumpWidget(_appUnderTest(pickFile: () async => null));

      await tester.tap(find.byKey(const Key('jdInput_generate')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('generateVerticalDropdown')));
      await tester.tap(find.byKey(const Key('generateVerticalDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Operations & Process Excellence — Operations Manager').last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('generateJdButton')));
      await tester.tap(find.byKey(const Key('generateJdButton')));
      await tester.pumpAndSettle();

      expect(
        find.text('Generated JD for Operations & Process Excellence at Operations Manager level.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('useGeneratedJdButton')), findsOneWidget);
      expect(find.byKey(const Key('copyGeneratedJdButton')), findsOneWidget);
      expect(find.byKey(const Key('downloadGeneratedJdButton')), findsOneWidget);
      expect(find.byKey(const Key('checkMatchButton')), findsNothing);
    });

    testWidgets('Use this JD carries the text into Paste and reveals Check match', (tester) async {
      await tester.pumpWidget(_appUnderTest(pickFile: () async => null));

      await tester.tap(find.byKey(const Key('jdInput_generate')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('generateVerticalDropdown')));
      await tester.tap(find.byKey(const Key('generateVerticalDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Operations & Process Excellence — Operations Manager').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('generateJdButton')));
      await tester.tap(find.byKey(const Key('generateJdButton')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('useGeneratedJdButton')));
      await tester.tap(find.byKey(const Key('useGeneratedJdButton')));
      await tester.pumpAndSettle();

      // Back on the Paste tab, pre-filled, with Check match available again —
      // no manual re-navigation or retyping needed.
      expect(find.byKey(const Key('jdInput_paste')), findsOneWidget);
      final field = tester.widget<TextFormField>(find.byKey(const Key('jdTextField')));
      expect(
        field.controller!.text,
        'Generated JD for Operations & Process Excellence at Operations Manager level.',
      );
      expect(find.byKey(const Key('checkMatchButton')), findsOneWidget);
    });

    testWidgets('tapping Generate with no vertical picked shows an inline error', (tester) async {
      await tester.pumpWidget(_appUnderTest(pickFile: () async => null));

      await tester.tap(find.byKey(const Key('jdInput_generate')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('generateJdButton')));
      await tester.tap(find.byKey(const Key('generateJdButton')));
      await tester.pumpAndSettle();

      expect(find.text('Pick a vertical to continue'), findsOneWidget);
    });

    testWidgets('Copy shows a confirmation snackbar', (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async => null,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await tester.pumpWidget(_appUnderTest(pickFile: () async => null));

      await tester.tap(find.byKey(const Key('jdInput_generate')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('generateVerticalDropdown')));
      await tester.tap(find.byKey(const Key('generateVerticalDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Operations & Process Excellence — Operations Manager').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('generateJdButton')));
      await tester.tap(find.byKey(const Key('generateJdButton')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('copyGeneratedJdButton')));
      await tester.tap(find.byKey(const Key('copyGeneratedJdButton')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('JD copied to clipboard'), findsOneWidget);
    });
  });
}
