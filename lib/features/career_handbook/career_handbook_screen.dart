import 'package:flutter/material.dart';

import '../career_paths/career_vertical.dart';
import '../career_paths/corps_affinity.dart';
import 'career_handbook_detail_screen.dart';
import 'career_handbook_support.dart';

class CareerHandbookScreen extends StatelessWidget {
  const CareerHandbookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final byCategory = <String, List<CareerVertical>>{};
    for (final v in kAllBrowsableVerticals) {
      byCategory.putIfAbsent(v.category, () => []).add(v);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Career Vertical Handbook')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'An orientation guide, not a placement guarantee. Each of the 34 verticals below '
                  'covers what the field actually does, how officers typically grow through it, and '
                  'what it takes to get hired — read alongside Career Vertical Fit and the Skill '
                  'Equivalency Matrix.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  kHandbookTierBandNote,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              key: const Key('hybridFitCard'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Partial match to a vertical?', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 6),
                    const Text(kHandbookHybridFitNote),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              key: const Key('handbookComparisonTableButton'),
              icon: const Icon(Icons.table_chart_outlined),
              label: const Text('Compare all 34 at a glance'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const _ComparisonTableScreen()),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              key: const Key('handbookGlossaryButton'),
              icon: const Icon(Icons.menu_book_outlined),
              label: const Text('Corporate terms glossary'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const _GlossaryScreen()),
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final category in byCategory.keys) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
              child: Text(category, style: Theme.of(context).textTheme.titleSmall),
            ),
            for (final vertical in byCategory[category]!)
              ListTile(
                key: Key('handbookEntry_${vertical.name}'),
                title: Text(vertical.name),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => CareerHandbookDetailScreen(vertical: vertical)),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ComparisonTableScreen extends StatelessWidget {
  const _ComparisonTableScreen();

  @override
  Widget build(BuildContext context) {
    final rows = kHandbookComparisonRows;
    return Scaffold(
      appBar: AppBar(title: const Text('Compare all 34 verticals')),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Vertical')),
            DataColumn(label: Text('Category')),
            DataColumn(label: Text('Restriction')),
            DataColumn(label: Text('Bridge certifications')),
          ],
          rows: [
            for (final row in rows)
              DataRow(
                key: ValueKey('comparisonRow_${row.name}'),
                cells: [
                  DataCell(SizedBox(width: 200, child: Text(row.name))),
                  DataCell(SizedBox(width: 160, child: Text(row.category))),
                  DataCell(Text(row.restriction ?? '—')),
                  DataCell(SizedBox(width: 260, child: Text(row.bridgeCertifications.join(', ')))),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _GlossaryScreen extends StatelessWidget {
  const _GlossaryScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Corporate terms glossary')),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: kHandbookGlossary.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final term = kHandbookGlossary[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(term.term, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(term.definition),
            ],
          );
        },
      ),
    );
  }
}
