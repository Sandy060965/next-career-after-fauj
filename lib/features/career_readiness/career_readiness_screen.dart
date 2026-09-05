import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/profile_repository.dart';
import '../../core/services/transition_readiness.dart';

/// Renders the Transition Readiness Index — the aggregate of the three
/// scoring assessments elsewhere in the app. All computation lives in
/// [TransitionReadinessSummary], shared with the Dashboard so the two
/// screens never disagree on the officer's score.
class CareerReadinessScreen extends StatelessWidget {
  const CareerReadinessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ProfileRepository>();
    final summary = TransitionReadinessSummary.fromRepository(repo);
    final completed = summary.completed;
    final overallScore = summary.overallScore;

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
                : 'Based on ${completed.length} of ${summary.totalCount} assessments completed.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (summary.allCompleted && overallScore != null) ...[
            const SizedBox(height: 16),
            _ReadinessBandCard(score: overallScore, lowest: summary.lowestScoring!),
            const SizedBox(height: 16),
            const _ReadinessBandLegend(),
          ],
          const SizedBox(height: 24),
          Text('By dimension', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final dimension in summary.dimensions) _DimensionCard(dimension: dimension),
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

/// Shown only once all three assessments are complete — the officer's
/// current band, plus the specific dimension pulling the average down the
/// most, so the label is grounded in an actual number rather than reading
/// like an opaque verdict.
class _ReadinessBandCard extends StatelessWidget {
  const _ReadinessBandCard({required this.score, required this.lowest});

  final int score;
  final TransitionReadinessDimension lowest;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final band = readinessBandFor(score);

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
            Text('Where you stand in your transition', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final band in kReadinessBands)
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

  final TransitionReadinessDimension dimension;

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
                  Text('$score/100', style: Theme.of(context).textTheme.titleMedium),
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
