import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/services/profile_repository.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/fitment/fitment_result.dart';
import 'package:next_career_after_fauj/features/start_here/start_here_screen.dart';
import 'package:next_career_after_fauj/features/vertical_fit/vertical_fit.dart';
import 'package:provider/provider.dart';

/// Every navigation target is rendered as a placeholder Scaffold naming the
/// route, rather than pulling in each real destination screen (and its own
/// backend-call defaults) just to confirm Start Here navigates correctly.
Widget _wrap(ProfileRepository repository) {
  return ChangeNotifierProvider<ProfileRepository>.value(
    value: repository,
    child: MaterialApp(
      theme: AppTheme.light,
      home: const StartHereScreen(),
      onGenerateRoute: (settings) => MaterialPageRoute(
        builder: (_) => Scaffold(body: Text('route:${settings.name}')),
      ),
    ),
  );
}

void _setTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('renders all 3 steps, none marked done for a fresh officer', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(ProfileRepository()));

    expect(find.byKey(const Key('startHereStep_verticalFit')), findsOneWidget);
    expect(find.byKey(const Key('startHereStep_aiReadiness')), findsOneWidget);
    expect(find.byKey(const Key('startHereStep_cvJdFit')), findsOneWidget);
    expect(find.text('0 of 3'), findsOneWidget);
  });

  testWidgets(
      'the CV & JD Fit card shows the exact required message, the upload instruction, and all '
      'three actions', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(ProfileRepository()));

    expect(
      find.text(
        'Your overall Transition Index needs your CV matched against a real job '
        'description to finish — match it now if you have one, or build your CV '
        'first and come back to complete it.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('cvUploadInstruction')), findsOneWidget);
    expect(find.byKey(const Key('startHereUploadCvButton')), findsOneWidget);
    expect(find.byKey(const Key('startHereMatchNowButton')), findsOneWidget);
    expect(find.byKey(const Key('startHereBuildCvButton')), findsOneWidget);
  });

  testWidgets('Upload CV opens the CV upload sheet', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(ProfileRepository()));

    await tester.tap(find.byKey(const Key('startHereUploadCvButton')));
    await tester.pumpAndSettle();

    expect(find.text('Upload your CV'), findsOneWidget);
    expect(find.byKey(const Key('cvUploadSheetBrowseButton')), findsOneWidget);
  });

  testWidgets('tapping each step card navigates to its route', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(ProfileRepository()));

    await tester.tap(find.byKey(const Key('startHereStep_verticalFit')));
    await tester.pumpAndSettle();
    expect(find.text('route:/vertical-fit'), findsOneWidget);
  });

  testWidgets('Match now navigates to JD Match', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(ProfileRepository()));

    await tester.tap(find.byKey(const Key('startHereMatchNowButton')));
    await tester.pumpAndSettle();
    expect(find.text('route:/jd-match'), findsOneWidget);
  });

  testWidgets('Build my CV first navigates to CV Builder', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(ProfileRepository()));

    await tester.tap(find.byKey(const Key('startHereBuildCvButton')));
    await tester.pumpAndSettle();
    expect(find.text('route:/cv-builder'), findsOneWidget);
  });

  testWidgets('Skip to the app marks the guided intro seen and goes to Profile', (tester) async {
    _setTallViewport(tester);
    final repository = ProfileRepository();
    await tester.pumpWidget(_wrap(repository));

    expect(repository.hasSeenGuidedIntro, isFalse);
    await tester.tap(find.byKey(const Key('skipStartHereButton')));
    await tester.pumpAndSettle();

    expect(find.text('route:/profile'), findsOneWidget);
    expect(repository.hasSeenGuidedIntro, isTrue);
  });

  testWidgets('progress reflects completed steps from repository state', (tester) async {
    _setTallViewport(tester);
    final repository = ProfileRepository();
    await repository.saveVerticalFitAssessment(
      const VerticalFitAssessment(ratings: {}),
    );
    await repository.saveFitmentResult(
      const FitmentResult(
        fitmentScore: 7,
        scoreRationale: 'Strong operational background.',
        requirementBreakdown: [],
        originalCvExcerpt: '',
        refinedCv: '',
        dimensionGaps: [],
        gapRoadmap: [],
      ),
    );

    await tester.pumpWidget(_wrap(repository));

    expect(find.text('2 of 3'), findsOneWidget);
  });
}
