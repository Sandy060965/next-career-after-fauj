import 'package:flutter/material.dart';

import '../../core/widgets/home_button.dart';
import 'corporate_language_term.dart';

class CorporateLanguageDetailScreen extends StatelessWidget {
  const CorporateLanguageDetailScreen({super.key, required this.entry});

  final CorporateLanguageTerm entry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(entry.term), actions: const [HomeButton()]),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (entry.fullForm != '—') ...[
            Text(entry.fullForm, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(entry.category), visualDensity: VisualDensity.compact),
              for (final c in entry.crossCategories)
                Chip(
                  label: Text(c),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                ),
              if (entry.priorityTier > 0)
                Chip(
                  key: const Key('priorityTierChip'),
                  label: Text(switch (entry.priorityTier) {
                    1 => 'Learn before Day 1',
                    2 => 'Learn within the first month',
                    _ => 'Build depth over time',
                  }),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: colorScheme.primaryContainer,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(entry.meaning, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 8),
          Text(
            'Where you\'ll see it: ${entry.whereSeen}',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          _Section(title: 'In Indian corporate practice', child: Text(entry.indianContext)),
          const SizedBox(height: 20),
          _Section(title: 'Military bridge', child: Text(entry.militaryEquivalent)),
          const SizedBox(height: 20),
          Text('You might hear', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              entry.dialogueSnippet,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(height: 20),
          Text('Trap for officers', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Container(
            key: const Key('trapForOfficersBox'),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(entry.trapForOfficers),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
