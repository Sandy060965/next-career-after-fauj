import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/services/profile_repository.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/ai_readiness/ai_competency.dart';
import 'package:next_career_after_fauj/features/ai_readiness/ai_readiness.dart';
import 'package:next_career_after_fauj/features/ai_readiness/ai_readiness_scenario.dart';
import 'package:next_career_after_fauj/features/career_readiness/career_readiness_screen.dart';
import 'package:next_career_after_fauj/features/fitment/fitment_result.dart';
import 'package:next_career_after_fauj/features/vertical_fit/aptitude_question.dart';
import 'package:next_career_after_fauj/features/vertical_fit/vertical_fit.dart';
import 'package:provider/provider.dart';

Widget _wrap(ProfileRepository repository) {
  return ChangeNotifierProvider<ProfileRepository>.value(
    value: repository,
    child: MaterialApp(theme: AppTheme.light, home: const CareerReadinessScreen()),
  );
}

const _fitmentResult = FitmentResult(
  fitmentScore: 7,
  scoreRationale: 'Solid overall match.',
  requirementBreakdown: [],
  originalCvExcerpt: 'Original excerpt.',
  refinedCv: 'Refined CV text.',
  dimensionGaps: [],
  gapRoadmap: [],
);

final _aiReadinessResult = AiReadinessResult(
  readinessScore: 60,
  scoreRationale: 'Moderate readiness.',
  tierScores: {for (final t in AiReadinessTier.values) t: 60},
  skillGaps: [
    SkillGap(competency: kAiCompetencies.first, severity: GapSeverity.high, reason: 'Needs practice.'),
  ],
  cvAiBridge: 'Your logistics experience already involves data-driven decisions.',
  roadmap: const [],
);

void main() {
  testWidgets('shows empty state with a CTA per dimension when nothing is completed',
      (tester) async {
    await tester.pumpWidget(_wrap(ProfileRepository()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('overallReadinessScoreText')), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('overallReadinessScoreText'))).data, '—');
    expect(find.text('Complete the assessments below to see your Transition Readiness Index.'),
        findsOneWidget);
    expect(find.byKey(const Key('readinessAction_Career Fit')), findsOneWidget);
    expect(find.byKey(const Key('readinessAction_CV & JD Fit')), findsOneWidget);
    await tester.scrollUntilVisible(find.byKey(const Key('readinessAction_AI Readiness')), 300);
    expect(find.byKey(const Key('readinessAction_AI Readiness')), findsOneWidget);
  });

  testWidgets('shows a partial score when only some assessments are completed', (tester) async {
    final repository = ProfileRepository();
    repository.saveVerticalFitAssessment(const VerticalFitAssessment(ratings: {}));
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    // All ratings default to 3 (missing entries fall back to 3) -> every
    // dimension scores (3/5)*100 = 60, so overall Career Fit is 60.
    expect(tester.widget<Text>(find.byKey(const Key('overallReadinessScoreText'))).data, '60');
    expect(find.text('Based on 1 of 3 assessments completed.'), findsOneWidget);
    expect(find.byKey(const Key('readinessAction_Career Fit')), findsNothing);
    expect(find.byKey(const Key('readinessAction_CV & JD Fit')), findsOneWidget);
  });

  testWidgets('shows the full aggregated score when all three assessments are completed',
      (tester) async {
    final repository = ProfileRepository();
    repository.saveVerticalFitAssessment(const VerticalFitAssessment(ratings: {}));
    repository.saveFitmentResult(_fitmentResult);
    repository.saveAiReadinessResult(_aiReadinessResult);
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    // Career Fit 60, CV & JD Fit 70 (7*10), AI Readiness 60 -> avg 63.33 -> 63.
    expect(tester.widget<Text>(find.byKey(const Key('overallReadinessScoreText'))).data, '63');
    expect(find.text('Based on 3 of 3 assessments completed.'), findsOneWidget);
    expect(find.byKey(const Key('readinessAction_Career Fit')), findsNothing);
    expect(find.byKey(const Key('readinessAction_CV & JD Fit')), findsNothing);
    expect(find.byKey(const Key('readinessAction_AI Readiness')), findsNothing);

    // 63 falls in the 60-69 "Moderate fitment" band.
    expect(find.byKey(const Key('readinessBandCard')), findsOneWidget);
    expect(find.byKey(const Key('readinessBandLabel')), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('readinessBandLabel'))).data, 'Moderate fitment');
    // Career Fit (60) and AI Readiness (60) tie for lowest; either is a
    // correct answer for reduce()'s <= tie-break, so just check the score.
    expect(find.textContaining('/100) — this is the single biggest lever'), findsOneWidget);

    // The full reference legend is shown alongside the officer's own band.
    expect(find.byKey(const Key('readinessBandLegend')), findsOneWidget);
    for (final band in [
      'Early stage',
      'Developing',
      'Fair fitment',
      'Moderate fitment',
      'Good fitment',
      'Excellent fitment',
    ]) {
      // "Moderate fitment" legitimately appears twice — once in the band
      // callout, once in the legend row — everything else appears once.
      expect(find.text(band), findsWidgets);
    }
  });

  testWidgets('band legend and callout are hidden until all three assessments are done',
      (tester) async {
    final repository = ProfileRepository();
    repository.saveVerticalFitAssessment(const VerticalFitAssessment(ratings: {}));
    repository.saveFitmentResult(_fitmentResult);
    // AI Readiness deliberately left incomplete.
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('readinessBandCard')), findsNothing);
    expect(find.byKey(const Key('readinessBandLegend')), findsNothing);
  });

  testWidgets('a low overall score lands in the Early stage band', (tester) async {
    final repository = ProfileRepository();
    // All ratings at minimum -> every Career Fit dimension scores (1/5)*100 = 20.
    final lowRatings = {for (final q in kAptitudeQuestions) q.id: 1};
    repository.saveVerticalFitAssessment(VerticalFitAssessment(ratings: lowRatings));
    repository.saveFitmentResult(const FitmentResult(
      fitmentScore: 1,
      scoreRationale: 'Weak match.',
      requirementBreakdown: [],
      originalCvExcerpt: '',
      refinedCv: '',
      dimensionGaps: [],
      gapRoadmap: [],
    ));
    repository.saveAiReadinessResult(AiReadinessResult(
      readinessScore: 20,
      scoreRationale: 'Low readiness.',
      tierScores: {for (final t in AiReadinessTier.values) t: 20},
      skillGaps: const [],
      cvAiBridge: 'Bridge text.',
      roadmap: const [],
    ));
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    // Career Fit 20, CV & JD Fit 10 (1*10), AI Readiness 20 -> avg 16.67 -> 17.
    expect(tester.widget<Text>(find.byKey(const Key('overallReadinessScoreText'))).data, '17');
    expect(tester.widget<Text>(find.byKey(const Key('readinessBandLabel'))).data, 'Early stage');
  });
}
