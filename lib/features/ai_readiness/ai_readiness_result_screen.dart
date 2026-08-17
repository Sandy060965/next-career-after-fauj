import 'package:flutter/material.dart';

import 'ai_competency.dart';
import 'ai_course.dart';
import 'ai_readiness.dart';

class AiReadinessResultScreen extends StatelessWidget {
  const AiReadinessResultScreen({super.key, required this.result});

  final AiReadinessResult result;

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 24),
          Text('By dimension', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final dimension in AiDimension.values)
            _DimensionBar(dimension: dimension, score: result.dimensionScores[dimension] ?? 0),
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

class _DimensionBar extends StatelessWidget {
  const _DimensionBar({required this.dimension, required this.score});

  final AiDimension dimension;
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
              Expanded(child: Text(dimension.label, style: Theme.of(context).textTheme.bodyMedium)),
              Text('$score', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              key: ValueKey('dimensionBar_${dimension.name}'),
              value: score / 100,
              minHeight: 6,
            ),
          ),
        ],
      ),
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
