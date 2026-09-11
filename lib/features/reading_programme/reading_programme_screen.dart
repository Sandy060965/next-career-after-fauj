import 'package:flutter/material.dart';

import '../../core/widgets/home_button.dart';
import 'reading_programme_book.dart';
import 'reading_programme_books.dart';
import 'reading_programme_detail_screen.dart';
import 'reading_programme_support.dart';

const List<String> kReadingProgrammePriorityOrder = [
  'ESSENTIAL',
  'HIGHLY RECOMMENDED',
  'RECOMMENDED',
];

class ReadingProgrammeScreen extends StatelessWidget {
  const ReadingProgrammeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final byPriority = <String, List<ReadingProgrammeBook>>{};
    for (final b in kReadingProgrammeBooks) {
      byPriority.putIfAbsent(b.priority, () => []).add(b);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Corporate Transition - Reading Programme'),
        actions: const [HomeButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
            child: Text(
              'A staged reading list, not a checklist to finish before you leave service. '
              'It focuses on translating your existing military strengths into corporate '
              'settings — commercial thinking, influence without rank, feedback culture, '
              'finance and strategy.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              key: const Key('fiveBookMinimumCard'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Short on time? The 5-book minimum', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    for (final item in kFiveBookMinimum)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('•  $item'),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              key: const Key('readingSequenceButton'),
              icon: const Icon(Icons.timeline_outlined),
              label: const Text('Recommended reading sequence'),
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const _ReadingSequenceScreen())),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              key: const Key('translationMapButton'),
              icon: const Icon(Icons.compare_arrows),
              label: const Text('Military-to-corporate translation map'),
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const _TranslationMapScreen())),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              key: const Key('cautionsButton'),
              icon: const Icon(Icons.info_outline),
              label: const Text('Important cautions before you start'),
              onPressed: () =>
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const _CautionsScreen())),
            ),
          ),
          const SizedBox(height: 12),
          for (final priority in kReadingProgrammePriorityOrder)
            if (byPriority[priority] != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
                child: Text(priority, style: Theme.of(context).textTheme.titleSmall),
              ),
              for (final book in byPriority[priority]!)
                ListTile(
                  key: Key('readingProgrammeEntry_${book.title}'),
                  title: Text(book.title),
                  subtitle: Text('${book.author} · ${book.theme}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ReadingProgrammeDetailScreen(book: book)),
                  ),
                ),
            ],
        ],
      ),
    );
  }
}

class _ReadingSequenceScreen extends StatelessWidget {
  const _ReadingSequenceScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommended reading sequence'),
        actions: const [HomeButton()],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: kReadingSequence.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, i) {
          final s = kReadingSequence[i];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.phase, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(s.items),
            ],
          );
        },
      ),
    );
  }
}

class _TranslationMapScreen extends StatelessWidget {
  const _TranslationMapScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Military-to-corporate translation map'),
        actions: const [HomeButton()],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: kMilitaryCorporateMap.length,
        separatorBuilder: (_, __) => const Divider(height: 24),
        itemBuilder: (context, i) {
          final m = kMilitaryCorporateMap[i];
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(m.military, style: Theme.of(context).textTheme.bodyMedium)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward, size: 16),
              ),
              Expanded(child: Text(m.corporate, style: Theme.of(context).textTheme.bodyMedium)),
            ],
          );
        },
      ),
    );
  }
}

class _CautionsScreen extends StatelessWidget {
  const _CautionsScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Important cautions'), actions: const [HomeButton()]),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          for (final c in kReadingProgrammeCautions)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(c)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
