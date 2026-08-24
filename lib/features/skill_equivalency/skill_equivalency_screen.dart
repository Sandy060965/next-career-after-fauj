import 'package:flutter/material.dart';

import 'skill_equivalency.dart';

class SkillEquivalencyScreen extends StatelessWidget {
  const SkillEquivalencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Skill Equivalency Matrix')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'How your military courses, commands, and appointments map to civilian '
            'corporate roles and language.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          for (final entry in kSkillEquivalencies) _EquivalencyCard(entry: entry),
        ],
      ),
    );
  }
}

class _EquivalencyCard extends StatelessWidget {
  const _EquivalencyCard({required this.entry});

  final SkillEquivalency entry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      key: ValueKey('equivalency_${entry.militaryTerm}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.militaryTerm, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.arrow_downward, size: 16, color: colorScheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    entry.civilianEquivalent,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(entry.description, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
