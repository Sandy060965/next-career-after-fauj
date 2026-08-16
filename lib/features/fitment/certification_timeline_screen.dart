import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/officer_profile.dart';
import '../../core/services/profile_repository.dart';
import '../../core/utils/date_format.dart';
import 'fitment_result.dart';

class CertificationTimelineScreen extends StatelessWidget {
  const CertificationTimelineScreen({super.key, required this.result});

  final FitmentResult result;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileRepository>().profile;
    final sorted = [...result.certificationGuidance]
      ..sort((a, b) => a.priority.compareTo(b.priority));

    return Scaffold(
      appBar: AppBar(title: const Text('Certification Guidance')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Recommended certifications to close the gaps identified above, '
            'prioritized by impact.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          for (final recommendation in sorted) _TimelineStep(recommendation: recommendation),
          _ReleaseMarker(profile: profile),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({required this.recommendation});

  final CertificationRecommendation recommendation;

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
              key: ValueKey('certification_${recommendation.name}'),
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(recommendation.name, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Closes: ${recommendation.closesGap}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Time to acquire: ${recommendation.timeToAcquire}',
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
