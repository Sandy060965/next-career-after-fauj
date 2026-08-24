import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/profile_repository.dart';
import 'transition_phase_content.dart';

class TransitionPlanScreen extends StatelessWidget {
  const TransitionPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ProfileRepository>();
    final profile = repo.profile;

    if (profile == null) {
      return const Scaffold(body: Center(child: Text('No profile found yet.')));
    }

    final monthsUntilRelease =
        (profile.releaseDate.difference(DateTime.now()).inDays / 30).round();
    final currentPhase = currentTransitionPhase(monthsUntilRelease);

    final completion = <String, bool>{
      'verticalFit': repo.lastVerticalFitAssessment != null,
      'aiReadiness': repo.lastAiReadinessResult != null,
      'jdMatch': repo.lastFitmentResult != null,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('My Transition Plan')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Your transition timeline', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            monthsUntilRelease <= 0
                ? "You're released — here's what to focus on now."
                : 'About $monthsUntilRelease months until your release date. '
                    "Here's what to focus on now, and what's next.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          for (final phase in kTransitionPlan)
            _PhaseCard(
              phase: phase,
              isCurrent: phase.monthsBeforeRelease == currentPhase.monthsBeforeRelease,
              isLast: phase == kTransitionPlan.last,
              completion: completion,
            ),
        ],
      ),
    );
  }
}

class _PhaseCard extends StatelessWidget {
  const _PhaseCard({
    required this.phase,
    required this.isCurrent,
    required this.isLast,
    required this.completion,
  });

  final TransitionPhaseContent phase;
  final bool isCurrent;
  final bool isLast;
  final Map<String, bool> completion;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return IntrinsicHeight(
      child: Row(
        key: ValueKey('phaseCard_${phase.label}'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCurrent ? colorScheme.primary : colorScheme.outlineVariant,
                ),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: colorScheme.outlineVariant)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Card(
              margin: const EdgeInsets.only(bottom: 16),
              color: isCurrent ? colorScheme.primaryContainer.withValues(alpha: 0.35) : null,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(phase.label, style: Theme.of(context).textTheme.titleSmall),
                        if (isCurrent) ...[
                          const SizedBox(width: 8),
                          Chip(
                            key: const Key('currentPhaseChip'),
                            label: const Text('Current focus'),
                            visualDensity: VisualDensity.compact,
                            backgroundColor: colorScheme.primary,
                            labelStyle: TextStyle(color: colorScheme.onPrimary, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(phase.headline, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    for (final action in phase.actions)
                      _ActionRow(
                        action: action,
                        isDone: action.completionCheck != null &&
                            (completion[action.completionCheck] ?? false),
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

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.action, required this.isDone});

  final TransitionAction action;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      key: ValueKey('transitionAction_${action.title}'),
      onTap: () => Navigator.of(context).pushNamed(action.route),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              isDone ? Icons.check_circle : Icons.circle_outlined,
              size: 18,
              color: isDone ? colorScheme.primary : colorScheme.outlineVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                action.title,
                style: TextStyle(
                  decoration: isDone ? TextDecoration.lineThrough : null,
                  color: isDone ? colorScheme.onSurfaceVariant : null,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 18),
          ],
        ),
      ),
    );
  }
}
