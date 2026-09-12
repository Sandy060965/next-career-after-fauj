import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routing/app_routes.dart';
import '../../core/routing/module_catalog.dart';
import '../../core/services/profile_repository.dart';
import '../../core/services/transition_readiness.dart';

int _moduleCount(List<ModulePhase> phases) =>
    phases.fold(0, (sum, phase) => sum + phase.modules.length);

/// AI Assistant is deliberately NOT in [kCareerModules]/[kJobsModules]/
/// [kLearnModules] — those three lists double as the real button data for
/// the Career/Jobs/Learn section tabs and the wide-screen sidebar (see
/// core/routing/module_catalog.dart), and AI Assistant isn't opened from a
/// tab list at all: it's the sparkle floating button shown on every screen.
/// This list exists only so "How This App Works" can still count and
/// describe it, without adding a second, redundant entry point anywhere in
/// the app's actual navigation.
const List<ModulePhase> _kAlwaysAvailableModules = [
  ModulePhase(
    title: 'Reachable From Every Screen',
    modules: [
      ModuleEntry(
        keyName: 'aiAssistantButton',
        route: AppRoutes.aiAssistant,
        label: 'AI Assistant',
        description: 'Shown as a separate floating button (the sparkle icon) on every screen, not '
            'just here — ask open-ended questions by typing or speaking, grounded only in your own '
            'real, already-computed data.',
      ),
    ],
  ),
];

/// The app's real, current module count — computed from the same catalog
/// the "How This App Works" guide numbers modules from, so it can never go
/// stale the way a hand-typed number would the next time a module is added,
/// renamed, or retired.
final kTotalModuleCount = _moduleCount(kCareerModules) +
    _moduleCount(kJobsModules) +
    _moduleCount(kLearnModules) +
    _moduleCount(_kAlwaysAvailableModules);

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

  // Incomplete-dimension nudges live in the permanent "Your 3 core
  // assessments" section above this one now, so they're not repeated here.
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
            const SizedBox(height: 20),
            const _InstructionsCard(),
            const SizedBox(height: 24),
            Text('Your 3 core assessments', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'These drive your Transition Readiness Index below — start with whichever '
              'you haven\'t done yet.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            for (final dimension in summary.dimensions) _DimensionActionCard(dimension: dimension),
            const SizedBox(height: 16),
            _ReadinessSummaryCard(summary: summary),
            if (nextActions.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('What\'s next', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (var i = 0; i < nextActions.length; i++)
                _NextActionTile(index: i + 1, action: nextActions[i]),
            ],
          ],
        ),
      ),
    );
  }
}

/// A collapsed-by-default orientation guide — the app's structure, where to
/// start, and how the CV/JD inputs work — kept off to the side of the
/// dashboard's own action items rather than repeating Start Here's onboarding
/// flow. Collapsed by default so it doesn't compete with today's actions for
/// a returning officer, but always one tap away for anyone who wants the map
/// again.
class _InstructionsCard extends StatelessWidget {
  const _InstructionsCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      key: const Key('instructionsCard'),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: const Key('instructionsExpansionTile'),
          leading: Icon(Icons.map_outlined, color: colorScheme.primary),
          title: const Text('How This App Works'),
          subtitle: const Text('The app\'s structure, where to start, and how the CV/JD inputs work'),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A structured path from uniform to civilian career: understand where you '
              'stand, build the documents you need, then run a focused job search. Every '
              'score and recommendation in this app is grounded in what you actually '
              'enter — nothing is guessed or invented.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text('The app in four parts', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              'Every module below, grouped the same way it\'s grouped in the app, with what it '
              'does and the value it adds to your transition.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Numbered 1–$kTotalModuleCount straight through, so you can see at a glance how '
              'much of the app there is — without counting.',
              style: textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 8),
            const _ModuleCategorySection(
              title: 'Career',
              color: kCareerColor,
              intro: 'Understand your options and see where you stand.',
              phases: kCareerModules,
              startNumber: 1,
            ),
            _ModuleCategorySection(
              title: 'Jobs',
              color: kJobsColor,
              intro: 'Execute the search, from first application to first pay cheque.',
              phases: kJobsModules,
              startNumber: 1 + _moduleCount(kCareerModules),
            ),
            _ModuleCategorySection(
              title: 'Learn',
              color: kLearnColor,
              intro: 'Build your documents and your vocabulary.',
              phases: kLearnModules,
              startNumber: 1 + _moduleCount(kCareerModules) + _moduleCount(kJobsModules),
            ),
            _ModuleCategorySection(
              title: 'Always Available',
              color: null,
              intro: 'Not tied to Career, Jobs, or Learn — reachable from anywhere in the app.',
              phases: _kAlwaysAvailableModules,
              startNumber:
                  1 + _moduleCount(kCareerModules) + _moduleCount(kJobsModules) + _moduleCount(kLearnModules),
            ),
            const _ModuleCategorySection(
              title: 'Profile',
              color: null,
              intro: 'Your details, uploaded CV, and every assessment result and document '
                  'you\'ve generated — all kept in one place, editable any time.',
              phases: [],
              // Unused — no modules to number, Profile isn't a module list.
              startNumber: 0,
            ),
            const SizedBox(height: 4),
            const _InstructionSection(
              title: 'Where to start',
              body: 'Begin with the three assessments under Career — everything else in '
                  'the app builds on these:\n\n'
                  '1. Career Fit — how well your background matches different civilian '
                  'career paths.\n'
                  '2. AI Readiness — how prepared you are for an AI-augmented workplace.\n'
                  '3. CV & JD Fit — how well your CV matches a real job description '
                  'you\'re targeting.\n\n'
                  'Together these three feed your Transition Readiness Index, shown just '
                  'below — a single score that updates automatically as you complete each '
                  'assessment, so you always know where you stand overall.\n\n'
                  'None of these are a one-time test — retake any of the three any time (tap '
                  'it again, or use "Retake this assessment" on its result screen), and your '
                  'score and the Index update immediately.\n\n'
                  'Your first attempt is often before you\'ve explored much of the app, so '
                  'it\'s worth deliberately revisiting: retake Career Fit once you\'ve been '
                  'through the Career Vertical Handbook and know which of the 34 verticals '
                  'actually look relevant to you — your answers, informed rather than a '
                  'first guess, will change. Retake CV & JD Fit whenever you\'ve refined your '
                  'CV further or want to check it against a different job description — each '
                  'match is specific to the CV and JD you gave it at the time.',
            ),
            const _InstructionSection(
              title: 'If you don\'t have a CV ready',
              body: 'CV & JD Fit needs a CV to match against a job description. If you '
                  'already added one — at onboarding, or any time via "Add CV" — the app '
                  'uses it automatically. Don\'t have one yet, or want a sharper, '
                  'civilian-ready version first? Use Build My Civilian CV (under Learn) to '
                  'build and download one from what you\'ve actually done. It feeds '
                  'straight back into CV & JD Fit.',
            ),
            const _InstructionSection(
              title: 'If you don\'t have a JD to match',
              body: 'Inside CV & JD Fit, choose "Generate a JD with AI", pick your target '
                  'career vertical, and the app generates a realistic sample job '
                  'description to match against — so you can complete the assessment '
                  'before you\'ve shortlisted a real opening.',
            ),
            const _InstructionSection(
              title: 'Why this matters',
              isLast: true,
              body: 'Transitions usually stall on the same handful of problems: not '
                  'knowing which civilian roles actually fit a Service background, '
                  'struggling to translate rank and appointment language into terms a '
                  'recruiter understands, and finding out about a gap only at interview. '
                  'This app is built to surface exactly those gaps early — one assessment, '
                  'one document, and one clear next step at a time.',
            ),
          ],
        ),
      ),
    );
  }
}

/// One category's block within "The app in four parts" — reads module names
/// and descriptions straight from [ModulePhase]/[ModuleEntry]
/// (core/routing/module_catalog.dart), the same source the Career/Jobs/Learn
/// section screens and the wide-screen sidebar render from, so this guide
/// can never list a module that doesn't exist or drift out of sync with a
/// module that's been renamed or removed. Profile has no catalog entry (it
/// isn't a list of modules), so it's called with an empty [phases] and its
/// [intro] carries the whole description.
///
/// [startNumber] is this category's first module's number in the single
/// 1..[kTotalModuleCount] sequence that runs across all of Career, Jobs and
/// Learn — not restarted per category or per phase — so an officer can see
/// the app's full size at a glance without counting.
class _ModuleCategorySection extends StatelessWidget {
  const _ModuleCategorySection({
    required this.title,
    required this.color,
    required this.intro,
    required this.phases,
    required this.startNumber,
  });

  final String title;
  final Color? color;
  final String intro;
  final List<ModulePhase> phases;
  final int startNumber;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final categoryColor = color ?? Theme.of(context).colorScheme.onSurface;
    var number = startNumber;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: categoryColor),
          ),
          const SizedBox(height: 2),
          Text(intro, style: textTheme.bodyMedium),
          for (final phase in phases) ...[
            const SizedBox(height: 8),
            Text(
              phase.title,
              style: textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            for (final module in phase.modules) _ModuleBulletRow(number: number++, module: module),
          ],
        ],
      ),
    );
  }
}

class _ModuleBulletRow extends StatelessWidget {
  const _ModuleBulletRow({required this.number, required this.module});

  final int number;
  final ModuleEntry module;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 26, child: Text('$number.', style: textTheme.bodyMedium)),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: module.label, style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  TextSpan(text: ' — ${module.description}', style: textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionSection extends StatelessWidget {
  const _InstructionSection({required this.title, required this.body, this.isLast = false});

  final String title;
  final String body;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(body, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// One of the 3 always-shown assessment cards leading the dashboard — same
/// visual language (checkmark once done, chevron with a score otherwise) as
/// Start Here's step cards, since these are the same 3 assessments.
class _DimensionActionCard extends StatelessWidget {
  const _DimensionActionCard({required this.dimension});

  final TransitionReadinessDimension dimension;

  IconData get _icon => switch (dimension.route) {
        AppRoutes.verticalFit => Icons.explore_outlined,
        AppRoutes.aiReadiness => Icons.auto_awesome_outlined,
        _ => Icons.fact_check_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final done = dimension.score != null;
    return Card(
      key: ValueKey('dimensionCard_${dimension.label}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(_icon, color: colorScheme.onPrimaryContainer),
        ),
        title: Text(dimension.label, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dimension.description),
            // A checkmark alone reads as "finished, don't touch again" — say
            // explicitly that tapping re-opens it, since perspective on
            // these assessments is expected to change as an officer explores
            // the rest of the app.
            if (done)
              Text(
                'Tap to retake',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: colorScheme.primary, fontStyle: FontStyle.italic),
              ),
          ],
        ),
        isThreeLine: done,
        trailing: done
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${dimension.score}/100', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(width: 6),
                  Icon(Icons.check_circle, color: colorScheme.primary),
                ],
              )
            : Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
        onTap: () => Navigator.of(context).pushNamed(dimension.route),
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
