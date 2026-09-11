import 'package:flutter/material.dart';

import '../../core/routing/app_routes.dart';
import '../../core/routing/guided_sequence.dart';
import '../../core/widgets/home_button.dart';
import 'fitment_result.dart';
import 'gap_roadmap_screen.dart';
import 'refined_cv_screen.dart';

class ScoreGapScreen extends StatelessWidget {
  const ScoreGapScreen({super.key, required this.result, this.originalCvText});

  final FitmentResult result;

  /// The officer's actual, complete extracted CV text (client-side, never
  /// touched by the LLM). Null for PDF CVs, where no local text extraction
  /// happens — the Refined CV screen falls back to the model's excerpt.
  final String? originalCvText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fitment Score'), actions: const [HomeButton()]),
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
          const SizedBox(height: 12),
          Center(
            child: OutlinedButton.icon(
              // A fresh CV, a different target JD, or simply a better sense
              // of what the role needs after exploring the rest of the app
              // all change this score — matching again is always available,
              // not a one-time check.
              key: const Key('retakeJdMatchButton'),
              onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.jdMatch),
              icon: const Icon(Icons.refresh),
              label: const Text('Match against a different JD'),
            ),
          ),
          const SizedBox(height: 16),
          _RecommendationCard(gapCount: result.requirementBreakdown
              .where((item) => item.status == RequirementStatus.gap)
              .length),
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
                MaterialPageRoute(
                  builder: (_) => RefinedCvScreen(result: result, originalCvText: originalCvText),
                ),
              ),
              child: const Text('View refined CV'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              key: const Key('viewGapRoadmapButton'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => GapRoadmapScreen(result: result)),
              ),
              child: const Text('View gap roadmap'),
            ),
          ),
          const SizedBox(height: 12),
          const NextStepButton(completedStepKey: 'cvJdFit'),
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
                // Scaled to /100 to match how this same score is shown as
                // "CV & JD Fit" on the Home dashboard's Transition Index.
                '${score * 10}',
                style: Theme.of(context)
                    .textTheme
                    .displayMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text('out of 100', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

/// A deterministic, gap-count-driven recommendation — never AI-generated,
/// so it's always consistent with the requirement breakdown shown right
/// below it.
class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.gapCount});

  final int gapCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (icon, title, detail) = switch (gapCount) {
      0 => (
          Icons.check_circle_outline,
          'Recommendation: Apply',
          "You meet or partially meet every requirement identified — this role is worth applying to as-is.",
        ),
      1 || 2 => (
          Icons.info_outline,
          'Recommendation: Apply',
          'Worth applying now — be ready to address $gapCount priority gap${gapCount > 1 ? 's' : ''} '
              'if it comes up at interview. See the requirement breakdown below.',
        ),
      _ => (
          Icons.flag_outlined,
          'Recommendation: Apply after addressing your priority gaps',
          '$gapCount gaps were identified against this role\'s requirements. Review the Gap '
              'Roadmap below before applying, so your application reflects your strongest case.',
        ),
    };
    return Card(
      key: const Key('recommendationCard'),
      color: colorScheme.secondaryContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(detail, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
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
