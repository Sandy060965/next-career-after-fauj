import 'package:flutter/material.dart';

import 'ai_course.dart';
import 'ai_readiness.dart';
import 'ai_readiness_review_screen.dart';
import 'ai_readiness_scenario.dart';

/// A deterministic (non-LLM) suggestion for where to start, keyed to the
/// topic that scored lowest — a concrete first move, not just a label.
String _nextStepFor(AiReadinessTopic topic) => switch (topic) {
      AiReadinessTopic.fundamentals =>
        'Start with the basics: spend an hour learning what LLMs, hallucination, context '
            'windows, and retrieval actually mean — the rest of AI use builds on these.',
      AiReadinessTopic.toolSelection =>
        'Before your next AI-assisted task, pause and ask what the task actually needs '
            '(current information? images? a long document?) before picking a tool.',
      AiReadinessTopic.prompting =>
        'Practice giving AI real context, constraints, and examples instead of a one-line '
            'request, and treat the first response as a draft to refine, not a final answer.',
      AiReadinessTopic.researchAndDecisions =>
        'Before using an AI-generated number or claim in a report, build the habit of '
            'checking it against one primary source first.',
      AiReadinessTopic.workflowsAndAgents =>
        'Pick one repetitive, well-defined task and map its steps before considering how '
            'AI or automation could take any of them over.',
      AiReadinessTopic.governance =>
        "Before entering any sensitive data into an AI tool, check where that data goes and "
            "whether your organisation's policy actually allows it.",
    };

class AiReadinessResultScreen extends StatelessWidget {
  const AiReadinessResultScreen({
    super.key,
    required this.result,
    this.reviewQuestions,
    this.reviewAnswers,
  });

  final AiReadinessResult result;

  /// The exact questions and answers from the attempt that produced
  /// [result], if available — lets the officer jump to the answer review.
  final List<ScenarioQuestion>? reviewQuestions;
  final Map<String, dynamic>? reviewAnswers;

  @override
  Widget build(BuildContext context) {
    final entries = AiReadinessTopic.values
        .map((t) => MapEntry(t, result.topicScores[t] ?? 0))
        .toList();
    final strongest = entries.reduce((a, b) => b.value > a.value ? b : a);
    final weakest = entries.reduce((a, b) => b.value < a.value ? b : a);

    return Scaffold(
      appBar: AppBar(title: const Text('Your AI Readiness')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(child: _ScoreDial(score: result.readinessScore)),
          const SizedBox(height: 12),
          Text(
            result.scoreRationale,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (reviewQuestions != null && reviewAnswers != null) ...[
            const SizedBox(height: 12),
            Center(
              child: OutlinedButton.icon(
                key: const Key('reviewAnswersButton'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AiReadinessReviewScreen(
                      questions: reviewQuestions!,
                      answers: reviewAnswers!,
                    ),
                  ),
                ),
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Review your answers'),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text('Your capabilities', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final entry in entries) _CapabilityRow(topic: entry.key, score: entry.value),
          const SizedBox(height: 12),
          Card(
            key: const Key('capabilitySummaryCard'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SummaryLine(
                    icon: Icons.trending_up,
                    label: 'Strongest capability',
                    text: '${strongest.key.label} (${strongest.value}/100)',
                  ),
                  const SizedBox(height: 8),
                  _SummaryLine(
                    icon: Icons.trending_down,
                    label: 'Biggest gap',
                    text: '${weakest.key.label} (${weakest.value}/100)',
                  ),
                  const SizedBox(height: 8),
                  _SummaryLine(
                    icon: Icons.arrow_forward,
                    label: 'Recommended next step',
                    text: _nextStepFor(weakest.key),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Priority gaps', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final gap in result.skillGaps) _SkillGapTile(gap: gap),
          const SizedBox(height: 24),
          Card(
            key: const Key('cvAiBridgeCard'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('How your experience already applies', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Text(result.cvAiBridge, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Your 90-day roadmap', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final phase in RoadmapPhase.values) ..._roadmapSection(context, phase),
        ],
      ),
    );
  }

  List<Widget> _roadmapSection(BuildContext context, RoadmapPhase phase) {
    final items = result.roadmap.where((item) => item.phase == phase).toList();
    if (items.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Text(phase.label, style: Theme.of(context).textTheme.titleSmall),
      ),
      for (final item in items) _RoadmapTile(item: item),
    ];
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
              value: score / 100,
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
                key: const Key('readinessScoreText'),
                style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text('out of 100', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _CapabilityRow extends StatelessWidget {
  const _CapabilityRow({required this.topic, required this.score});

  final AiReadinessTopic topic;
  final int score;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(topic.label, style: Theme.of(context).textTheme.bodyMedium)),
              Text(
                '$score/100',
                key: ValueKey('capabilityScore_${topic.name}'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              key: ValueKey('capabilityBar_${topic.name}'),
              value: score / 100,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.icon, required this.label, required this.text});

  final IconData icon;
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
                TextSpan(text: text),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SkillGapTile extends StatelessWidget {
  const _SkillGapTile({required this.gap});

  final SkillGap gap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (chipColor, chipTextColor) = switch (gap.severity) {
      GapSeverity.high => (colorScheme.errorContainer, colorScheme.onErrorContainer),
      GapSeverity.medium => (colorScheme.tertiaryContainer, colorScheme.onTertiaryContainer),
      GapSeverity.low => (colorScheme.surfaceContainerHighest, colorScheme.onSurfaceVariant),
    };
    return Card(
      key: ValueKey('skillGap_${gap.competency.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(gap.competency.name),
        subtitle: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Chip(
              label: Text(gap.severity.label),
              backgroundColor: chipColor,
              labelStyle: TextStyle(color: chipTextColor, fontSize: 12),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Align(alignment: Alignment.centerLeft, child: Text(gap.reason)),
          ),
        ],
      ),
    );
  }
}

class _RoadmapTile extends StatelessWidget {
  const _RoadmapTile({required this.item});

  final RoadmapItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    AiCourse? course;
    if (item.courseId != null) {
      for (final c in kAiCourses) {
        if (c.id == item.courseId) {
          course = c;
          break;
        }
      }
    }

    return IntrinsicHeight(
      child: Row(
        key: ValueKey('roadmapItem_${item.title}'),
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
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(item.description, style: Theme.of(context).textTheme.bodyMedium),
                    if (course != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${course.name} — ${course.provider} · ${course.duration} · ${course.cost.label}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(course.url, style: Theme.of(context).textTheme.bodySmall),
                    ],
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
