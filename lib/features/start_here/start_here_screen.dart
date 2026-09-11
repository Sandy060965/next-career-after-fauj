import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routing/app_routes.dart';
import '../../core/routing/guided_sequence.dart';
import '../../core/services/profile_repository.dart';
import '../cv_upload/cv_upload_sheet.dart';

/// A one-time interstitial shown right after onboarding, nudging a
/// first-time officer through the four steps that give the fastest,
/// most personalised payoff before anything else in the app: Career
/// Vertical Fit, Skill Equivalency, AI Readiness, then CV & JD Fit.
///
/// Steps are nudged, not gated — every card is reachable immediately, in
/// any order, and "Skip to the app" always works.
class StartHereScreen extends StatelessWidget {
  const StartHereScreen({super.key});

  void _skip(BuildContext context) {
    context.read<ProfileRepository>().markGuidedIntroSeen();
    Navigator.of(context).pushReplacementNamed(AppRoutes.profile);
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ProfileRepository>();
    // Subtitle/icon/done-check are Start-Here-specific presentation, kept
    // local — but key/title/route come from kGuidedSequence so the order
    // and destinations stay a single source of truth shared with the
    // "Next" button on each step's completion screen.
    final stepDone = <String, bool>{
      'verticalFit': repo.lastVerticalFitAssessment != null,
      'aiReadiness': repo.lastAiReadinessResult != null,
    };
    final stepSubtitle = <String, String>{
      'verticalFit': 'A quick quiz — see which civilian verticals actually suit you.',
      'aiReadiness': 'A short assessment of how comfortable you are working with AI tools.',
    };
    final stepIcon = <String, IconData>{
      'verticalFit': Icons.explore_outlined,
      'aiReadiness': Icons.auto_awesome_outlined,
    };
    final steps = [
      for (final s in kGuidedSequence.where((s) => stepDone.containsKey(s.key)))
        _StepData(
          key: s.key,
          title: s.label,
          subtitle: stepSubtitle[s.key]!,
          icon: stepIcon[s.key]!,
          done: stepDone[s.key]!,
          route: s.route,
        ),
    ];
    final fitmentDone = repo.lastFitmentResult != null;
    final completedCount = steps.where((s) => s.done).length + (fitmentDone ? 1 : 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Start Here'),
        actions: [
          TextButton(
            key: const Key('skipStartHereButton'),
            onPressed: () => _skip(context),
            child: const Text('Skip to the app'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        children: [
          Text('Welcome — a few quick steps first', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'These take about 15 minutes and give you a personalised picture before you '
            'touch anything else in the app. Tap any step, in any order.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          _ProgressBar(completed: completedCount, total: steps.length + 1),
          const SizedBox(height: 20),
          for (final step in steps) _StepCard(step: step),
          _CvJdFitCard(done: fitmentDone),
        ],
      ),
    );
  }
}

class _StepData {
  const _StepData({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.done,
    required this.route,
  });

  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool done;
  final String route;
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.completed, required this.total});

  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              key: const Key('startHereProgressBar'),
              value: completed / total,
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text('$completed of $total', style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step});

  final _StepData step;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      key: ValueKey('startHereStep_${step.key}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(step.icon, color: colorScheme.onPrimaryContainer),
        ),
        title: Text(step.title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(step.subtitle),
        trailing: Icon(
          step.done ? Icons.check_circle : Icons.chevron_right,
          color: step.done ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
        onTap: () => Navigator.of(context).pushNamed(step.route),
      ),
    );
  }
}

class _CvJdFitCard extends StatelessWidget {
  const _CvJdFitCard({required this.done});

  final bool done;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      key: const Key('startHereStep_cvJdFit'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(Icons.fact_check_outlined, color: colorScheme.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('CV & JD Fit', style: Theme.of(context).textTheme.titleMedium),
                ),
                if (done) Icon(Icons.check_circle, color: colorScheme.primary),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Your overall Transition Index needs your CV matched against a real job '
              'description to finish — match it now if you have one, or build your CV '
              'first and come back to complete it.',
              key: const Key('cvJdFitMessage'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Already have a CV ready? Upload it directly below. Don\'t have one yet? '
              'Build one from scratch instead.',
              key: const Key('cvUploadInstruction'),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('startHereUploadCvButton'),
                onPressed: () => showCvUploadSheet(context),
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Upload CV'),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('startHereMatchNowButton'),
                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.jdMatch),
                    child: const Text('Match now'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    key: const Key('startHereBuildCvButton'),
                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.cvBuilder),
                    child: const Text('Build my CV first'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
