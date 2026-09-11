import '../routing/app_routes.dart';
import 'profile_repository.dart';

/// One dimension of the Transition Readiness Index — either completed (a
/// real score computed from that module's own result) or not yet attempted,
/// in which case [score] is null rather than a fabricated/default value.
class TransitionReadinessDimension {
  const TransitionReadinessDimension({
    required this.label,
    required this.description,
    required this.score,
    required this.route,
    required this.actionLabel,
  });

  final String label;
  final String description;
  final int? score;
  final String route;
  final String actionLabel;
}

/// Aggregates the scores already computed by other modules into one
/// weighted index. Every number here is read straight from a result the
/// officer has actually generated — nothing is invented, and any assessment
/// not yet completed shows as an open call to action instead of a score.
/// The single source of truth for this computation, shared by the
/// Transition Readiness Index screen and the Dashboard, so the two never
/// disagree.
class TransitionReadinessSummary {
  const TransitionReadinessSummary({
    required this.dimensions,
    required this.overallScore,
    required this.completedCount,
  });

  final List<TransitionReadinessDimension> dimensions;

  /// Equal-weighted average of completed dimensions — null until at least
  /// one exists.
  final int? overallScore;
  final int completedCount;

  int get totalCount => dimensions.length;
  bool get allCompleted => completedCount == totalCount;

  List<TransitionReadinessDimension> get completed =>
      dimensions.where((d) => d.score != null).toList();

  /// The dimension pulling the average down the most — only meaningful once
  /// at least one dimension is complete.
  TransitionReadinessDimension? get lowestScoring {
    final done = completed;
    if (done.isEmpty) return null;
    return done.reduce((a, b) => a.score! <= b.score! ? a : b);
  }

  factory TransitionReadinessSummary.fromRepository(ProfileRepository repo) {
    final verticalFit = repo.lastVerticalFitAssessment;
    final careerFitScore = verticalFit == null
        ? null
        : (verticalFit.dimensionScores.values.fold<int>(0, (a, b) => a + b) /
                verticalFit.dimensionScores.length)
            .round();

    final fitmentResult = repo.lastFitmentResult;
    final cvJdFitScore = fitmentResult == null ? null : fitmentResult.fitmentScore * 10;

    final aiReadiness = repo.lastAiReadinessResult;
    final aiReadinessScore = aiReadiness?.readinessScore;

    final dimensions = [
      TransitionReadinessDimension(
        label: 'Career Fit',
        description: 'How well your aptitude matches the corporate verticals you\'re considering.',
        score: careerFitScore,
        route: AppRoutes.verticalFit,
        actionLabel: 'Take the Career Vertical Fit assessment',
      ),
      TransitionReadinessDimension(
        label: 'AI Readiness',
        description: 'How prepared you are to work alongside AI tools in a corporate role.',
        score: aiReadinessScore,
        route: AppRoutes.aiReadiness,
        actionLabel: 'Take the AI Readiness assessment',
      ),
      TransitionReadinessDimension(
        label: 'CV & JD Fit',
        description: 'How closely your CV matches the last job description you checked.',
        score: cvJdFitScore,
        route: AppRoutes.jdMatch,
        actionLabel: 'Run a JD Match',
      ),
    ];

    final completed = dimensions.where((d) => d.score != null).toList();
    final overallScore = completed.isEmpty
        ? null
        : (completed.fold<int>(0, (total, d) => total + d.score!) / completed.length).round();

    return TransitionReadinessSummary(
      dimensions: dimensions,
      overallScore: overallScore,
      completedCount: completed.length,
    );
  }
}

/// A fixed, deterministic interpretation band for the overall 0-100 score —
/// never AI-generated, so it reads the same way every time for the same
/// score. Bands are informational context, not a verdict: the underlying
/// per-dimension scores and the officer's own judgement always matter more
/// than which band a rounded average happens to fall into.
class ReadinessBand {
  const ReadinessBand({required this.label, required this.range, required this.description});

  final String label;
  final String range;
  final String description;
}

const kReadinessBands = [
  ReadinessBand(
    label: 'Early stage',
    range: 'Below 40',
    description: "You're at the start of the transition journey, with meaningful gaps across "
        'more than one dimension. Focus on the fundamentals — understanding your options and '
        'building a baseline — before applying in earnest.',
  ),
  ReadinessBand(
    label: 'Developing',
    range: '40–49',
    description: 'Some transferable strengths are showing, but real gaps remain in your '
        'positioning and readiness. Worth closing these before applying broadly.',
  ),
  ReadinessBand(
    label: 'Fair foundation',
    range: '50–59',
    description: 'A workable base to build from, though noticeable gaps remain. You can start '
        'exploring roles while you keep closing them.',
  ),
  ReadinessBand(
    label: 'Moderately prepared',
    range: '60–69',
    description: 'Good overall progress, with a few gaps still worth addressing before you '
        'lean heavily on this profile in the job market.',
  ),
  ReadinessBand(
    label: 'Well positioned',
    range: '70–79',
    description: "A strong foundation with a few identifiable gaps. You're ready to actively "
        'pursue opportunities — closing your lowest-scoring area will sharpen your '
        'competitiveness further.',
  ),
  ReadinessBand(
    label: 'Highly prepared',
    range: '80 and above',
    description: 'Well prepared across the board. The focus now shifts from closing gaps to '
        'targeting the right roles and converting opportunities into offers.',
  ),
];

ReadinessBand readinessBandFor(int score) {
  if (score < 40) return kReadinessBands[0];
  if (score < 50) return kReadinessBands[1];
  if (score < 60) return kReadinessBands[2];
  if (score < 70) return kReadinessBands[3];
  if (score < 80) return kReadinessBands[4];
  return kReadinessBands[5];
}
