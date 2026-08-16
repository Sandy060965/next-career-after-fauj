import 'package:flutter/material.dart';

import 'certification_timeline_screen.dart';
import 'fitment_result.dart';
import 'refined_cv_screen.dart';

class ScoreGapScreen extends StatelessWidget {
  const ScoreGapScreen({super.key, required this.result});

  final FitmentResult result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fitment Score')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(child: _ScoreDial(score: result.fitmentScore)),
          const SizedBox(height: 12),
          Text(
            result.scoreRationale,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Text('Requirement breakdown', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...result.requirementBreakdown.map((item) => _RequirementTile(item: item)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              key: const Key('viewRefinedCvButton'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => RefinedCvScreen(result: result)),
              ),
              child: const Text('View refined CV'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              key: const Key('viewCertificationGuidanceButton'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => CertificationTimelineScreen(result: result)),
              ),
              child: const Text('View certification guidance'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreDial extends StatelessWidget {
  const _ScoreDial({required this.score});

  final int score;

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
              value: score / 10,
              strokeWidth: 12,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(colorScheme.primary),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: Theme.of(context)
                    .textTheme
                    .displayMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text('out of 10', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _RequirementTile extends StatelessWidget {
  const _RequirementTile({required this.item});

  final RequirementBreakdownItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (chipColor, chipTextColor) = switch (item.status) {
      RequirementStatus.met => (colorScheme.primaryContainer, colorScheme.onPrimaryContainer),
      RequirementStatus.partiallyMet => (
          colorScheme.tertiaryContainer,
          colorScheme.onTertiaryContainer,
        ),
      RequirementStatus.gap => (colorScheme.errorContainer, colorScheme.onErrorContainer),
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        key: ValueKey('requirement_${item.requirement}'),
        title: Text(item.requirement),
        subtitle: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Chip(
              label: Text(item.status.label),
              backgroundColor: chipColor,
              labelStyle: TextStyle(color: chipTextColor, fontSize: 12),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(item.notes),
            ),
          ),
        ],
      ),
    );
  }
}
