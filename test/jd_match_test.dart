import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/services/profile_repository.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/fitment/fitment_result.dart';
import 'package:next_career_after_fauj/features/jd_match/jd_match_screen.dart';
import 'package:provider/provider.dart';

const _stubResult = FitmentResult(
  fitmentScore: 8,
  scoreRationale: 'Test rationale',
  requirementBreakdown: [],
  originalCvExcerpt: 'Original excerpt',
  refinedCv: 'Refined excerpt',
  certificationGuidance: [],
);

Future<FitmentResult> _stubAnalyzeFitment({
  required String jdText,
  required String cvFileName,
}) async =>
    _stubResult;

Widget _appUnderTest({
  required Future<String?> Function() pickFile,
  Future<FitmentResult> Function({required String jdText, required String cvFileName})
      analyzeFitment = _stubAnalyzeFitment,
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
    await tester.tap(find.byKey(const Key('checkMatchButton')));
    await tester.pumpAndSettle();
    expect(find.text('Paste a job description to continue'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('jdTextField')),
      'Looking for a logistics manager with 10 years experience.',
    );
    await tester.tap(find.byKey(const Key('checkMatchButton')));
    await tester.pumpAndSettle();

    expect(find.text('Fitment Score'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
  });

  testWidgets('uploading a JD file and checking match navigates to the fitment score screen',
      (tester) async {
    await tester.pumpWidget(_appUnderTest(pickFile: () async => 'job-description.pdf'));

    await tester.tap(find.byKey(const Key('jdInput_upload')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('checkMatchButton')));
    await tester.pumpAndSettle();
    expect(find.text('Upload a job description to continue'), findsOneWidget);

    await tester.tap(find.byKey(const Key('jdBrowseButton')));
    await tester.pumpAndSettle();
    expect(find.text('job-description.pdf'), findsWidgets);

    await tester.tap(find.byKey(const Key('checkMatchButton')));
    await tester.pumpAndSettle();

    expect(find.text('Fitment Score'), findsOneWidget);
  });
}
