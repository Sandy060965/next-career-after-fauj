import 'package:flutter/material.dart';

import 'success_roadmap_item.dart';

class NinetyDayRoadmapScreen extends StatelessWidget {
  const NinetyDayRoadmapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your First 90 Days')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'A general-purpose plan for succeeding after you join a new organisation — '
            'not tied to any specific employer.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          for (final phase in RoadmapPhase.values) ..._phaseSection(context, phase),
        ],
      ),
    );
  }

  List<Widget> _phaseSection(BuildContext context, RoadmapPhase phase) {
    final items = kNinetyDaySuccessPlan.where((item) => item.phase == phase).toList();
    return [
      Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Text(phase.label, style: Theme.of(context).textTheme.titleMedium),
      ),
      for (final item in items) _RoadmapStep(item: item),
    ];
  }
}

class _RoadmapStep extends StatelessWidget {
  const _RoadmapStep({required this.item});

  final SuccessRoadmapItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return IntrinsicHeight(
      child: Row(
        key: ValueKey('successStep_${item.title}'),
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
