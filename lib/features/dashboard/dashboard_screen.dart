import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routing/app_routes.dart';
import '../../core/services/profile_repository.dart';
import '../../core/services/transition_readiness.dart';

/// A single deterministic next-action candidate — always tied to real,
/// persisted state (never a fabricated count or invented recommendation).
class _NextAction {
  const _NextAction({required this.title, required this.subtitle, required this.route});

  final String title;
  final String subtitle;
  final String route;
}

/// Builds the officer's next-action candidates in priority order, then the
/// caller takes the first three. Every candidate is grounded in something
/// the officer has (or hasn't) actually done — no invented job-match counts
/// or skill scores that don't exist anywhere else in the app.
List<_NextAction> _buildNextActions(ProfileRepository repo, TransitionReadinessSummary summary) {
  final candidates = <_NextAction>[];

  for (final dimension in summary.dimensions) {
    if (dimension.score == null) {
      candidates.add(
        _NextAction(
          title: 'Complete the ${dimension.label} assessment',
          subtitle: dimension.description,
          route: dimension.route,
        ),
      );
    }
  }

  final lowest = summary.lowestScoring;
  if (summary.allCompleted && lowest != null) {
    candidates.add(
      _NextAction(
        title: 'Strengthen your biggest gap: ${lowest.label} (${lowest.score}/100)',
        subtitle: 'This is the single biggest lever to move your overall score up.',
        route: lowest.route,
      ),
    );
  }

  if (repo.lastFitmentResult != null) {
    candidates.add(
      const _NextAction(
        title: 'Review your Gap Roadmap',
        subtitle: 'See the prioritised plan to close the gaps found in your last JD Match.',
        route: AppRoutes.gapRoadmap,
      ),
    );
  }

  if (repo.lastTargetRoleStrategy == null) {
    candidates.add(
      const _NextAction(
        title: 'Explore your Target Role Strategy',
        subtitle: 'Build a shortlist of target roles based on your Career Vertical Fit.',
        route: AppRoutes.targetRoleStrategy,
      ),
    );
  }

  if (repo.lastFinancialPlanInput == null) {
    candidates.add(
      const _NextAction(
        title: 'Plan your compensation & cost-of-living',
        subtitle: 'Compare your military package against a corporate offer.',
        route: AppRoutes.financialPlanner,
      ),
    );
  }

  if (repo.applications.isEmpty) {
    candidates.add(
      const _NextAction(
        title: 'Explore Job Matches',
        subtitle: 'See roles matched against your CV and start applying.',
        route: AppRoutes.jobMatches,
      ),
    );
  }

  candidates.add(
    const _NextAction(
      title: 'Review your Transition Plan',
      subtitle: 'See where you stand across the full journey, phase by phase.',
      route: AppRoutes.transitionPlan,
    ),
  );

  return candidates;
}

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ProfileRepository>();
    final profile = repo.profile;
    final summary = TransitionReadinessSummary.fromRepository(repo);
    final nextActions = _buildNextActions(repo, summary).take(3).toList();
    final surname = profile?.fullName.trim().split(RegExp(r'\s+')).last;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
          children: [
            Text(
              profile == null ? _greeting() : '${_greeting()}, ${profile.rank} $surname',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Here\'s where your transition stands today.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            _ReadinessSummaryCard(summary: summary),
            const SizedBox(height: 24),
            Text('Your next 3 actions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (var i = 0; i < nextActions.length; i++)
              _NextActionTile(index: i + 1, action: nextActions[i]),
          ],
        ),
      ),
    );
  }
}

class _ReadinessSummaryCard extends StatelessWidget {
  const _ReadinessSummaryCard({required this.summary});

  final TransitionReadinessSummary summary;

  @override
  Widget build(BuildContext context) {
    final score = summary.overallScore;
    final band = score == null ? null : readinessBandFor(score);

    return Card(
      key: const Key('dashboardReadinessCard'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transition Readiness', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  score == null ? '—' : '$score',
                  key: const Key('dashboardReadinessScoreText'),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 6, bottom: 8),
                  child: Text('/ 100', style: Theme.of(context).textTheme.bodyMedium),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              band?.label ?? 'Complete an assessment to see your score',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (band != null) ...[
              const SizedBox(height: 8),
              Text(band.description, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 16),
            for (final dimension in summary.dimensions) _CompactDimensionBar(dimension: dimension),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const Key('viewFullReadinessBreakdown'),
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.careerReadiness),
                child: const Text('View full breakdown'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactDimensionBar extends StatelessWidget {
  const _CompactDimensionBar({required this.dimension});

  final TransitionReadinessDimension dimension;

  @override
  Widget build(BuildContext context) {
    final score = dimension.score;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(dimension.label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: score == null ? 0 : score / 100, minHeight: 6),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              score == null ? '—' : '$score',
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _NextActionTile extends StatelessWidget {
  const _NextActionTile({required this.index, required this.action});

  final int index;
  final _NextAction action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      key: ValueKey('nextAction_$index'),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).pushNamed(action.route),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                child: Text('$index', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(action.title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(action.subtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
