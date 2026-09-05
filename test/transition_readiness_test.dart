import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/services/profile_repository.dart';
import 'package:next_career_after_fauj/core/services/transition_readiness.dart';
import 'package:next_career_after_fauj/features/ai_readiness/ai_competency.dart';
import 'package:next_career_after_fauj/features/ai_readiness/ai_readiness.dart';
import 'package:next_career_after_fauj/features/ai_readiness/ai_readiness_scenario.dart';
import 'package:next_career_after_fauj/features/fitment/fitment_result.dart';
import 'package:next_career_after_fauj/features/vertical_fit/vertical_fit.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _fitmentResult = FitmentResult(
  fitmentScore: 7,
  scoreRationale: 'Solid overall match.',
  requirementBreakdown: [],
  originalCvExcerpt: '',
  refinedCv: '',
  dimensionGaps: [],
  gapRoadmap: [],
);

final _aiReadinessResult = AiReadinessResult(
  readinessScore: 55,
  scoreRationale: 'Developing.',
  topicScores: {for (final t in AiReadinessTopic.values) t: 55},
  skillGaps: [
    SkillGap(competency: kAiCompetencies.first, severity: GapSeverity.high, reason: 'Needs practice.'),
  ],
  cvAiBridge: 'Bridge text.',
  roadmap: const [],
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('TransitionReadinessSummary.fromRepository', () {
    test('is empty/null when nothing has been completed', () {
      final summary = TransitionReadinessSummary.fromRepository(ProfileRepository());

      expect(summary.overallScore, isNull);
      expect(summary.completedCount, 0);
      expect(summary.totalCount, 3);
      expect(summary.allCompleted, isFalse);
      expect(summary.lowestScoring, isNull);
    });

    test('computes a partial average when only some assessments are done', () {
      final repo = ProfileRepository();
      repo.saveVerticalFitAssessment(const VerticalFitAssessment(ratings: {}));
      // All ratings default to 3 -> (3/5)*100 = 60 per dimension.

      final summary = TransitionReadinessSummary.fromRepository(repo);

      expect(summary.completedCount, 1);
      expect(summary.overallScore, 60);
      expect(summary.allCompleted, isFalse);
    });

    test('computes the full weighted average once all three are done', () {
      final repo = ProfileRepository();
      repo.saveVerticalFitAssessment(const VerticalFitAssessment(ratings: {}));
      repo.saveFitmentResult(_fitmentResult); // 7 * 10 = 70
      repo.saveAiReadinessResult(_aiReadinessResult); // 55

      final summary = TransitionReadinessSummary.fromRepository(repo);

      // Career Fit 60, CV & JD Fit 70, AI Readiness 55 -> avg 61.67 -> 62.
      expect(summary.completedCount, 3);
      expect(summary.overallScore, 62);
      expect(summary.allCompleted, isTrue);
      expect(summary.lowestScoring?.label, 'AI Readiness');
    });
  });

  group('readinessBandFor', () {
    test('maps scores to the correct band', () {
      expect(readinessBandFor(10).label, 'Early stage');
      expect(readinessBandFor(45).label, 'Developing');
      expect(readinessBandFor(55).label, 'Fair foundation');
      expect(readinessBandFor(65).label, 'Moderately prepared');
      expect(readinessBandFor(75).label, 'Well positioned');
      expect(readinessBandFor(90).label, 'Highly prepared');
    });
  });
}
