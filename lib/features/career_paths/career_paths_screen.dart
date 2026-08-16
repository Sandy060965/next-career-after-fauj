import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/officer_profile.dart';
import '../../core/services/profile_repository.dart';
import 'career_vertical.dart';

class CareerPathsScreen extends StatelessWidget {
  const CareerPathsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final segment = context.watch<ProfileRepository>().profile?.segment;

    return Scaffold(
      appBar: AppBar(title: const Text('Career Paths')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
            child: Text(
              segment == null
                  ? 'Browse how each field typically opens up over 10 years.'
                  : 'Your entry level as ${segment.fullLabel} is highlighted in '
                      'each field below — browse freely across all of them.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          ...kCareerVerticals.map(
            (vertical) => _VerticalTile(vertical: vertical, segment: segment),
          ),
        ],
      ),
    );
  }
}

class _VerticalTile extends StatelessWidget {
  const _VerticalTile({required this.vertical, required this.segment});

  final CareerVertical vertical;
  final OfficerSegment? segment;

  @override
  Widget build(BuildContext context) {
    final entryStep = segment == null ? null : vertical.entryIndex[segment];
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ExpansionTile(
        key: PageStorageKey(vertical.name),
        title: Text(vertical.name, style: Theme.of(context).textTheme.titleMedium),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          for (var i = 0; i < vertical.ladder.length; i++)
            _LadderStep(
              role: vertical.ladder[i],
              isLast: i == vertical.ladder.length - 1,
              isYourLevel: i == entryStep,
            ),
        ],
      ),
    );
  }
}

class _LadderStep extends StatelessWidget {
  const _LadderStep({
    required this.role,
    required this.isLast,
    required this.isYourLevel,
  });

  final String role;
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
                    child: Text(
                      role,
                      style: TextStyle(
                        fontWeight: isYourLevel ? FontWeight.bold : FontWeight.normal,
                        color: isYourLevel ? colorScheme.primary : null,
                      ),
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
