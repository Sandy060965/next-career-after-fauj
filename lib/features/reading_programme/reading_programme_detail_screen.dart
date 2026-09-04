import 'package:flutter/material.dart';

import 'reading_programme_book.dart';

class ReadingProgrammeDetailScreen extends StatelessWidget {
  const ReadingProgrammeDetailScreen({super.key, required this.book});

  final ReadingProgrammeBook book;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(book.title)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(book.author, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                key: const Key('priorityChip'),
                label: Text(book.priority),
                visualDensity: VisualDensity.compact,
                backgroundColor: switch (book.priority) {
                  'ESSENTIAL' => colorScheme.primaryContainer,
                  'HIGHLY RECOMMENDED' => colorScheme.secondaryContainer,
                  _ => colorScheme.surfaceContainerHighest,
                },
              ),
              Chip(label: Text(book.theme), visualDensity: VisualDensity.compact),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            book.reviewSignal,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          _Section(title: 'Why read it', child: Text(book.whyItBelongs)),
          const SizedBox(height: 20),
          _Section(title: 'What you\'ll learn', child: Text(book.whatYoudLearn)),
          const SizedBox(height: 20),
          _Section(
            title: 'Military-to-corporate gap addressed',
            child: Text(book.militaryTranslation),
          ),
          const SizedBox(height: 20),
          _Section(
            title: 'When to read',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book.bestTiming),
                const SizedBox(height: 4),
                Text(
                  book.howToRead,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _Section(
            title: 'Key takeaways',
            child: _BulletList(items: book.keyTakeaways),
          ),
          const SizedBox(height: 20),
          Text('30-minute summary', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Container(
            key: const Key('thirtyMinuteSummaryBox'),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(book.thirtyMinuteSummary),
          ),
          const SizedBox(height: 20),
          _Section(
            title: 'Self-assessment questions',
            child: _BulletList(items: book.selfAssessmentQuestions, icon: Icons.help_outline),
          ),
          const SizedBox(height: 20),
          Text(
            'First practical step: ${book.practicalApplication}',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic),
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

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items, this.icon = Icons.check_circle_outline});

  final List<String> items;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(item)),
              ],
            ),
          ),
      ],
    );
  }
}
