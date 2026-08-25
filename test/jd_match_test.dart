import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/services/file_picker_service.dart';
import 'package:next_career_after_fauj/core/services/profile_repository.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/fitment/fitment_result.dart';
import 'package:next_career_after_fauj/features/fitment/fitment_service.dart';
import 'package:next_career_after_fauj/features/jd_match/jd_match_screen.dart';
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
  required String cvFileName,
  String? cvExtractedText,
  Uint8List? cvPdfBytes,
}) async =>
    _stubResult;

Widget _appUnderTest({
  required Future<PickedFile?> Function() pickFile,
  FitmentAnalyzer analyzeFitment = _stubAnalyzeFitment,
}) {
  return ChangeNotifierProvider(
    create: (_) => ProfileRepository(),
    child: MaterialApp(
      theme: AppTheme.light,
      home: JdMatchScreen(pickFile: pickFile, analyzeFitment: analyzeFitment),
    ),
  );
}

void main() {
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
    expect(find.text('8'), findsOneWidget);
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

    await tester.tap(find.byKey(const Key('jdPasteButton')));
    await tester.pumpAndSettle();

    expect(find.text('Looking for a supply chain lead with ERP experience.'), findsOneWidget);
  });

  testWidgets('uploading a JD file extracts its real text, not just the filename',
      (tester) async {
    String? capturedJdText;
    Future<FitmentResult> capturingAnalyzeFitment({
      required String jdText,
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

    await tester.tap(find.byKey(const Key('checkMatchButton')));
    await tester.pumpAndSettle();
    expect(find.text('Upload a job description to continue'), findsOneWidget);

    await tester.tap(find.byKey(const Key('jdBrowseButton')));
    await tester.pumpAndSettle();
    expect(find.text('job-description.docx'), findsWidgets);

    await tester.tap(find.byKey(const Key('checkMatchButton')));
    await tester.pumpAndSettle();

    expect(find.text('Fitment Score'), findsOneWidget);
    // The regression this guards: the analyzer must receive the real
    // extracted text, not the bare filename it used to get.
    expect(capturedJdText, 'Looking for a logistics manager with 10 years experience.');
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

    await tester.tap(find.byKey(const Key('checkMatchButton')));
    await tester.pumpAndSettle();
    expect(find.text('Fitment Score'), findsNothing);
  });
}
