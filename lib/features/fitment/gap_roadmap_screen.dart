import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/officer_profile.dart';
import '../../core/services/profile_repository.dart';
import '../../core/utils/date_format.dart';
import 'fitment_result.dart';

class GapRoadmapScreen extends StatelessWidget {
  const GapRoadmapScreen({super.key, required this.result});

  final FitmentResult result;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileRepository>().profile;
    final sortedRoadmap = [...result.gapRoadmap]..sort((a, b) => a.priority.compareTo(b.priority));

    return Scaffold(
      appBar: AppBar(title: const Text('Gap Roadmap')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'How your CV measures up against the JD on experience, education, skills, '
            'and certifications — and a prioritized plan to close what matters most.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Text('Where you stand', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final dimension in GapDimension.values) _DimensionCard(assessment: _forDimension(dimension)),
          const SizedBox(height: 20),
          Text('Your roadmap', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final item in sortedRoadmap) _RoadmapStep(item: item),
          _ReleaseMarker(profile: profile),
        ],
      ),
    );
  }

  DimensionAssessment _forDimension(GapDimension dimension) {
    return result.dimensionGaps.firstWhere(
      (d) => d.dimension == dimension,
      orElse: () => DimensionAssessment(
        dimension: dimension,
        status: RequirementStatus.gap,
        notes: 'Not assessed.',
      ),
    );
  }
}

class _DimensionCard extends StatelessWidget {
  const _DimensionCard({required this.assessment});

  final DimensionAssessment assessment;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (chipColor, chipTextColor) = switch (assessment.status) {
      RequirementStatus.met => (colorScheme.primaryContainer, colorScheme.onPrimaryContainer),
      RequirementStatus.partiallyMet => (
          colorScheme.tertiaryContainer,
          colorScheme.onTertiaryContainer,
        ),
      RequirementStatus.gap => (colorScheme.errorContainer, colorScheme.onErrorContainer),
    };
    return Card(
      key: ValueKey('dimension_${assessment.dimension.name}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    assessment.dimension.label,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Chip(
                  label: Text(assessment.status.label),
                  backgroundColor: chipColor,
                  labelStyle: TextStyle(color: chipTextColor, fontSize: 12),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(assessment.notes, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _RoadmapStep extends StatelessWidget {
  const _RoadmapStep({required this.item});

  final GapRoadmapItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(shape: BoxShape.circle, color: colorScheme.primary),
              ),
              Expanded(child: Container(width: 2, color: colorScheme.outlineVariant)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Card(
              key: ValueKey('roadmap_${item.title}'),
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(item.title, style: Theme.of(context).textTheme.titleMedium),
                        ),
                        Chip(
                          label: Text(item.dimension.label),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Closes: ${item.closesGap}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Time to acquire: ${item.timeToAcquire}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReleaseMarker extends StatelessWidget {
  const _ReleaseMarker({required this.profile});

  final OfficerProfile? profile;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final profileValue = profile;
    final label = profileValue == null
        ? 'Release date not set'
        : profileValue.releaseStatus == ReleaseStatus.alreadyReleased
            ? 'Already released (${formatDate(profileValue.releaseDate)})'
            : 'Target: release on ${formatDate(profileValue.releaseDate)}';

    return Row(
      key: const Key('releaseMarker'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 14,
          height: 14,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(shape: BoxShape.circle, color: colorScheme.secondary),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: Theme.of(context).textTheme.titleSmall)),
      ],
    );
  }
}
