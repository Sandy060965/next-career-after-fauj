import 'package:flutter/material.dart';

import '../career_paths/career_paths_screen.dart';
import 'aptitude_question.dart';
import 'vertical_fit.dart';

class VerticalFitResultScreen extends StatelessWidget {
  const VerticalFitResultScreen({super.key, required this.assessment});

  final VerticalFitAssessment assessment;

  @override
  Widget build(BuildContext context) {
    final dimensionScores = assessment.dimensionScores;
    final ranked = rankVerticalFit(dimensionScores);
    final top3 = ranked.take(3).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Your Career Vertical Fit')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Your profile', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final dimension in AptitudeDimension.values)
            _DimensionBar(dimension: dimension, score: dimensionScores[dimension] ?? 0),
          const SizedBox(height: 20),
          Text('Your top 3 verticals', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (var i = 0; i < top3.length; i++)
            _VerticalFitCard(rank: i + 1, fit: top3[i], dimensionScores: dimensionScores),
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
  const _VerticalFitCard({required this.rank, required this.fit, required this.dimensionScores});

  final int rank;
  final VerticalFit fit;
  final Map<AptitudeDimension, int> dimensionScores;

  @override
  Widget build(BuildContext context) {
    final topDimensions = fit.topContributingDimensions(dimensionScores);
    final why = topDimensions.isEmpty
        ? 'Broadly aligned with your overall profile.'
        : 'Driven mainly by your strengths in '
            '${topDimensions.map((d) => '${d.label} (${dimensionScores[d]}/100)').join(' and ')}.';

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
            Text(why, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
