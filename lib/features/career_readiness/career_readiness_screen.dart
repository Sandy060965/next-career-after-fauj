import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routing/app_routes.dart';
import '../../core/services/profile_repository.dart';

/// One dimension of the Transition Readiness Index — either completed (a
/// real score computed from that module's own result) or not yet attempted,
/// in which case we show a call to action rather than a fabricated number.
class _ReadinessDimension {
  const _ReadinessDimension({
    required this.label,
    required this.description,
    required this.score,
    required this.route,
    required this.actionLabel,
  });

  final String label;
  final String description;

  /// Null means the officer hasn't completed this assessment yet — never
  /// filled in with a guessed or default value.
  final int? score;
  final String route;
  final String actionLabel;
}

/// Aggregates the scores already computed by other modules into one
/// weighted index. Every number here is read straight from a result the
/// officer has actually generated — nothing is invented, and any assessment
/// not yet completed shows as an open call to action instead of a score.
/// The weighting itself (currently equal) is stated explicitly to the
/// officer in-screen rather than being an invisible implementation detail.
class CareerReadinessScreen extends StatelessWidget {
  const CareerReadinessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ProfileRepository>();

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
      _ReadinessDimension(
        label: 'Career Fit',
        description: 'How well your aptitude matches the corporate verticals you\'re considering.',
        score: careerFitScore,
        route: AppRoutes.verticalFit,
        actionLabel: 'Take the Career Vertical Fit assessment',
      ),
      _ReadinessDimension(
        label: 'CV & JD Fit',
        description: 'How closely your CV matches the last job description you checked.',
        score: cvJdFitScore,
        route: AppRoutes.jdMatch,
        actionLabel: 'Run a JD Match',
      ),
      _ReadinessDimension(
        label: 'AI Readiness',
        description: 'How prepared you are to work alongside AI tools in a corporate role.',
        score: aiReadinessScore,
        route: AppRoutes.aiReadiness,
        actionLabel: 'Take the AI Readiness assessment',
      ),
    ];

    final completed = dimensions.where((d) => d.score != null).toList();
    final overallScore = completed.isEmpty
        ? null
        : (completed.fold<int>(0, (total, d) => total + d.score!) / completed.length).round();
    final allCompleted = completed.length == dimensions.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Transition Readiness Index')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(child: _ScoreDial(score: overallScore, completedCount: completed.length)),
          const SizedBox(height: 12),
          Text(
            overallScore == null
                ? 'Complete the assessments below to see your Transition Readiness Index.'
                : 'Based on ${completed.length} of ${dimensions.length} assessments completed.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (allCompleted && overallScore != null) ...[
            const SizedBox(height: 16),
            _ReadinessBandCard(score: overallScore, dimensions: completed),
            const SizedBox(height: 16),
            const _ReadinessBandLegend(),
          ],
          const SizedBox(height: 24),
          Text('By dimension', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final dimension in dimensions) _DimensionCard(dimension: dimension),
          const SizedBox(height: 24),
          Card(
            key: const Key('methodologyCard'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('How this is calculated', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Text(
                    'Each completed dimension is weighted equally (one-third each) — an '
                    'explicit, visible product choice, not a scientifically derived formula. '
                    "We'll recalibrate these weights once real outcome data exists (interview "
                    'rate, offer rate, time-to-offer) to show which dimension actually predicts '
                    'a successful transition.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A fixed, deterministic interpretation band for the overall 0-100 score —
/// never AI-generated, so it reads the same way every time for the same
/// score. Bands are informational context, not a verdict: the underlying
/// per-dimension scores and the officer's own judgement always matter more
/// than which band a rounded average happens to fall into.
class _ReadinessBand {
  const _ReadinessBand({required this.label, required this.range, required this.description});

  final String label;
  final String range;
  final String description;
}

const _readinessBands = [
  _ReadinessBand(
    label: 'Early stage',
    range: 'Below 40',
    description: 'Sizeable gaps across more than one dimension — worth focusing on the '
        'fundamentals before actively applying.',
  ),
  _ReadinessBand(
    label: 'Developing',
    range: '40–49',
    description: 'Meaningful gaps remain in at least one dimension — worth closing before '
        'applying in earnest.',
  ),
  _ReadinessBand(
    label: 'Fair fitment',
    range: '50–59',
    description: 'A workable foundation, but noticeable gaps remain — expect real preparation '
        'before you\'re competitive.',
  ),
  _ReadinessBand(
    label: 'Moderate fitment',
    range: '60–69',
    description: 'Reasonably well positioned overall, with a few gaps worth addressing first.',
  ),
  _ReadinessBand(
    label: 'Good fitment',
    range: '70–79',
    description: 'Strong overall positioning — a few minor gaps to address before you\'re '
        'fully ready.',
  ),
  _ReadinessBand(
    label: 'Excellent fitment',
    range: '80 and above',
    description: 'Very strong positioning across the board — at most 2-3 minor gaps left to '
        'round out your profile.',
  ),
];

_ReadinessBand _bandForScore(int score) {
  if (score < 40) return _readinessBands[0];
  if (score < 50) return _readinessBands[1];
  if (score < 60) return _readinessBands[2];
  if (score < 70) return _readinessBands[3];
  if (score < 80) return _readinessBands[4];
  return _readinessBands[5];
}

/// Shown only once all three assessments are complete — the officer's
/// current band, plus the specific dimension pulling the average down the
/// most, so the label is grounded in an actual number rather than reading
/// like an opaque verdict.
class _ReadinessBandCard extends StatelessWidget {
  const _ReadinessBandCard({required this.score, required this.dimensions});

  final int score;
  final List<_ReadinessDimension> dimensions;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final band = _bandForScore(score);
    final lowest = dimensions.reduce((a, b) => a.score! <= b.score! ? a : b);

    return Card(
      key: const Key('readinessBandCard'),
      color: colorScheme.secondaryContainer.withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    band.label,
                    key: const Key('readinessBandLabel'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Text('${band.range} / 100', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 6),
            Text(band.description, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 10),
            Text(
              'Lowest-scoring dimension: ${lowest.label} (${lowest.score}/100) — this is the '
              'single biggest lever to move your overall score up.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}

/// The full band reference table — always the same six bands, shown
/// alongside the officer's own result so they can see exactly where the
/// thresholds sit, not just the one label that applied to them.
class _ReadinessBandLegend extends StatelessWidget {
  const _ReadinessBandLegend();

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('readinessBandLegend'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What your score means', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final band in _readinessBands)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 92,
                      child: Text(band.range, style: Theme.of(context).textTheme.bodySmall),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(band.label, style: Theme.of(context).textTheme.bodyMedium),
                          Text(
                            band.description,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScoreDial extends StatelessWidget {
  const _ScoreDial({required this.score, required this.completedCount});

  final int? score;
  final int completedCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: CircularProgressIndicator(
              value: score == null ? 0 : score! / 100,
              strokeWidth: 12,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(
                completedCount == 0 ? colorScheme.outlineVariant : colorScheme.primary,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                score == null ? '—' : '$score',
                key: const Key('overallReadinessScoreText'),
                style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text('out of 100', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _DimensionCard extends StatelessWidget {
  const _DimensionCard({required this.dimension});

  final _ReadinessDimension dimension;

  @override
  Widget build(BuildContext context) {
    final score = dimension.score;
    return Card(
      key: ValueKey('readinessDimension_${dimension.label}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(dimension.label, style: Theme.of(context).textTheme.titleMedium)),
                if (score != null)
                  Text('$score', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 4),
            Text(dimension.description, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 10),
            if (score != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: score / 100, minHeight: 6),
              )
            else
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  key: ValueKey('readinessAction_${dimension.label}'),
                  onPressed: () => Navigator.of(context).pushNamed(dimension.route),
                  child: Text(dimension.actionLabel),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
