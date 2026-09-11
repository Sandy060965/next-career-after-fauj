import 'package:flutter/material.dart';

import '../../core/widgets/home_button.dart';
import '../career_paths/career_vertical.dart';
import '../career_paths/corps_affinity.dart';
import '../corporate_language/corporate_language_guide_screen.dart';
import '../corps_matrix/corps_matrix_screen.dart';
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
      appBar: AppBar(
        title: const Text('Career Vertical Handbook'),
        actions: const [HomeButton()],
      ),
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
            child: FilledButton.icon(
              key: const Key('openCorpsMatrixButton'),
              icon: const Icon(Icons.grid_view_outlined),
              label: const Text('Focus your search: Corps/Arm/Branch Fit Matrix'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CorpsMatrixScreen()),
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
              label: const Text('Corporate Language Guide'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CorporateLanguageGuideScreen()),
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
      appBar: AppBar(
        title: const Text('Compare all 34 verticals'),
        actions: const [HomeButton()],
      ),
      // Nested scroll views: the outer one is vertical so all 34 rows are
      // reachable, the inner one horizontal so the wide table can still be
      // panned sideways on narrow screens — a bare horizontal
      // SingleChildScrollView around a DataTable never scrolls vertically,
      // silently clipping every row past the viewport height.
      body: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('#')),
              DataColumn(label: Text('Vertical')),
              DataColumn(label: Text('Category')),
              DataColumn(label: Text('Restriction')),
              DataColumn(label: Text('Bridge certifications')),
            ],
            rows: [
              for (var i = 0; i < rows.length; i++)
                DataRow(
                  key: ValueKey('comparisonRow_${rows[i].name}'),
                  cells: [
                    DataCell(Text('${i + 1}')),
                    DataCell(SizedBox(width: 200, child: Text(rows[i].name))),
                    DataCell(SizedBox(width: 160, child: Text(rows[i].category))),
                    DataCell(Text(rows[i].restriction ?? '—')),
                    DataCell(SizedBox(width: 260, child: Text(rows[i].bridgeCertifications.join(', ')))),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
