import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/profile_repository.dart';
import 'career_vertical.dart';

class CareerPathsScreen extends StatelessWidget {
  const CareerPathsScreen({super.key, this.recommendedVerticals = const {}});

  /// Vertical names from the Career Vertical Fit assessment, if the officer
  /// arrived here from those results — shown first, with a badge.
  final Set<String> recommendedVerticals;

  @override
  Widget build(BuildContext context) {
    final workExperienceYears = context.watch<ProfileRepository>().profile?.workExperienceYears;
    final verticals = [...kCareerVerticals]..sort((a, b) {
        final aRecommended = recommendedVerticals.contains(a.name);
        final bRecommended = recommendedVerticals.contains(b.name);
        if (aRecommended == bRecommended) return 0;
        return aRecommended ? -1 : 1;
      });

    return Scaffold(
      appBar: AppBar(title: const Text('Career Paths')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
            child: Text(
              workExperienceYears == null
                  ? 'Browse how each field typically opens up from 10 to 40+ years of experience.'
                  : 'Your level at $workExperienceYears years of experience is highlighted in '
                      'each field below — browse freely across all of them.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          ...verticals.map(
            (vertical) => _VerticalTile(
              vertical: vertical,
              workExperienceYears: workExperienceYears,
              isRecommended: recommendedVerticals.contains(vertical.name),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalTile extends StatelessWidget {
  const _VerticalTile({
    required this.vertical,
    required this.workExperienceYears,
    this.isRecommended = false,
  });

  final CareerVertical vertical;
  final int? workExperienceYears;
  final bool isRecommended;

  @override
  Widget build(BuildContext context) {
    final yourLevel =
        workExperienceYears == null ? null : vertical.levelForExperience(workExperienceYears!);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ExpansionTile(
        key: PageStorageKey(vertical.name),
        title: Row(
          children: [
            Expanded(child: Text(vertical.name, style: Theme.of(context).textTheme.titleMedium)),
            if (isRecommended)
              Chip(
                key: const Key('recommendedVerticalBadge'),
                label: const Text('Recommended'),
                visualDensity: VisualDensity.compact,
                backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                labelStyle: TextStyle(color: Theme.of(context).colorScheme.onTertiaryContainer, fontSize: 12),
              ),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          for (final level in vertical.levels)
            _LadderStep(
              level: level,
              isLast: level.tier == vertical.levels.length,
              isYourLevel: level.tier == yourLevel?.tier,
            ),
          if (vertical.bridgeCertifications.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Bridge certifications: ${vertical.bridgeCertifications.join(', ')}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LadderStep extends StatelessWidget {
  const _LadderStep({
    required this.level,
    required this.isLast,
    required this.isYourLevel,
  });

  final CareerLevel level;
  final bool isLast;
  final bool isYourLevel;

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
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isYourLevel ? colorScheme.primary : colorScheme.outlineVariant,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: colorScheme.outlineVariant),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          level.title,
                          style: TextStyle(
                            fontWeight: isYourLevel ? FontWeight.bold : FontWeight.normal,
                            color: isYourLevel ? colorScheme.primary : null,
                          ),
                        ),
                        Text(
                          '${level.expMin}-${level.expMax == 42 ? '42+' : level.expMax} yrs',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  if (isYourLevel)
                    Chip(
                      key: const Key('yourLevelChip'),
                      label: const Text('Your level'),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: colorScheme.primaryContainer,
                      labelStyle: TextStyle(color: colorScheme.onPrimaryContainer),
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
