import 'package:flutter/material.dart';

import '../career_paths/career_paths_screen.dart';
import '../career_paths/corps_affinity.dart';
import 'aptitude_question.dart';
import 'vertical_fit.dart';

class VerticalFitResultScreen extends StatelessWidget {
  const VerticalFitResultScreen({super.key, required this.assessment, this.corpsOrArm});

  final VerticalFitAssessment assessment;

  /// The officer's Corps/Arm, if given at onboarding — determines whether
  /// ranking uses the general 20 verticals (with soft affinity badges) or a
  /// fully constrained domain universe (medicine, legal practice). See
  /// `corps_affinity.dart`.
  final String? corpsOrArm;

  @override
  Widget build(BuildContext context) {
    final dimensionScores = assessment.dimensionScores;
    final universe = effectiveVerticalUniverse(corpsOrArm);
    final constrained = isDomainConstrained(corpsOrArm);
    final ranked = rankVerticalFit(dimensionScores, universe: universe);
    final top3 = ranked.take(3).toList();
    final softAffinity = constrained ? const <String>[] : (kCorpsSoftAffinity[corpsOrArm] ?? const []);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Career Vertical Fit')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (constrained) ...[
            Container(
              key: const Key('domainConstrainedNotice'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Your results are scoped to $corpsOrArm-relevant career paths, not the general '
                'corporate verticals — your own professional domain carries the most weight here.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text('Your profile', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final group in DimensionGroup.values) ...[
            Text(group.label, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            for (final dimension in AptitudeDimension.values.where((d) => d.group == group))
              _DimensionBar(dimension: dimension, score: dimensionScores[dimension] ?? 0),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 20),
          Text('Your top 3 verticals', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (var i = 0; i < top3.length; i++)
            _VerticalFitCard(
              rank: i + 1,
              fit: top3[i],
              dimensionScores: dimensionScores,
              corpsAffinity: softAffinity.contains(top3[i].vertical.name),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              key: const Key('exploreCareerPathsButton'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CareerPathsScreen(
                    recommendedVerticals: top3.map((f) => f.vertical.name).toSet(),
                  ),
                ),
              ),
              child: const Text('Explore these in Career Paths'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DimensionBar extends StatelessWidget {
  const _DimensionBar({required this.dimension, required this.score});

  final AptitudeDimension dimension;
  final int score;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(dimension.label, style: Theme.of(context).textTheme.bodyMedium)),
              Text('$score', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              key: ValueKey('dimensionBar_${dimension.name}'),
              value: score / 100,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalFitCard extends StatelessWidget {
  const _VerticalFitCard({
    required this.rank,
    required this.fit,
    required this.dimensionScores,
    this.corpsAffinity = false,
  });

  final int rank;
  final VerticalFit fit;
  final Map<AptitudeDimension, int> dimensionScores;

  /// True when this vertical also matches the officer's Corps/Arm — a
  /// corroborating badge only, never a factor in [fit.fitScore] itself.
  final bool corpsAffinity;

  @override
  Widget build(BuildContext context) {
    final topDimensions = fit.topContributingDimensions(dimensionScores);
    final why = topDimensions.isEmpty
        ? 'Broadly aligned with your overall profile.'
        : 'Driven mainly by your strengths in '
            '${topDimensions.map((d) => '${d.label} (${dimensionScores[d]}/100)').join(' and ')}.';
    final confidence = fit.confidence(dimensionScores);
    final colorScheme = Theme.of(context).colorScheme;
    final confidenceColor = switch (confidence) {
      FitConfidence.high => colorScheme.primaryContainer,
      FitConfidence.medium => colorScheme.tertiaryContainer,
      FitConfidence.low => colorScheme.surfaceContainerHighest,
    };

    return Card(
      key: ValueKey('verticalFit_${fit.vertical.name}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 14, child: Text('$rank')),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(fit.vertical.name, style: Theme.of(context).textTheme.titleMedium),
                ),
                Text('${fit.fitScore}/100', style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                Chip(
                  key: ValueKey('confidence_${fit.vertical.name}'),
                  label: Text(confidence.label),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: confidenceColor,
                ),
                if (corpsAffinity)
                  Chip(
                    key: ValueKey('corpsAffinity_${fit.vertical.name}'),
                    label: const Text('Matches your Corps/Arm background'),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: colorScheme.secondaryContainer,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(why, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
