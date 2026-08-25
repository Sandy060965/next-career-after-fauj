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
