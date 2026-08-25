import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/services/profile_repository.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/ai_readiness/ai_competency.dart';
import 'package:next_career_after_fauj/features/ai_readiness/ai_readiness.dart';
import 'package:next_career_after_fauj/features/ai_readiness/ai_readiness_scenario.dart';
import 'package:next_career_after_fauj/features/career_readiness/career_readiness_screen.dart';
import 'package:next_career_after_fauj/features/fitment/fitment_result.dart';
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
    expect(find.text('Complete the assessments below to see your Career Readiness Score.'),
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
  });
}
