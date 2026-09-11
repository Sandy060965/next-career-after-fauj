import 'package:flutter/material.dart';

import '../../core/models/guide_section.dart';
import '../../core/widgets/guide_scenario_card.dart';
import '../../core/widgets/home_button.dart';

class CorporateCultureDetailScreen extends StatelessWidget {
  const CorporateCultureDetailScreen({super.key, required this.section});

  final GuideSection section;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(section.title), actions: const [HomeButton()]),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          for (final paragraph in section.paragraphs) ...[
            Text(paragraph, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
          ],
          if (section.referenceTable != null) ...[
            _ReferenceTable(table: section.referenceTable!),
            const SizedBox(height: 16),
          ],
          for (final scenario in section.scenarios)
            ScenarioCard(
              heading: scenario.heading,
              situation: scenario.situation,
              whatYouMayEncounter: scenario.whatYouMayEncounter,
              recommendedResponse: scenario.recommendedResponse,
              avoid: scenario.avoid,
            ),
          if (section.translations.isNotEmpty) ...[
            for (final translation in section.translations)
              TranslationRow(from: translation.from, to: translation.to),
            const SizedBox(height: 4),
          ],
          if (section.checklistItems.isNotEmpty) ...[
            _BulletList(items: section.checklistItems),
            const SizedBox(height: 8),
          ],
          if (section.closingNote != null)
            Container(
              key: const Key('closingNoteBox'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                section.closingNote!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReferenceTable extends StatelessWidget {
  const _ReferenceTable({required this.table});

  final GuideReferenceTable table;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(colorScheme.surfaceContainerHighest),
        columns: [
          for (final header in table.columnHeaders)
            DataColumn(label: Text(header, style: Theme.of(context).textTheme.labelLarge)),
        ],
        rows: [
          for (final row in table.rows)
            DataRow(cells: [for (final cell in row) DataCell(SizedBox(width: 200, child: Text(cell)))]),
        ],
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items});

  final List<String> items;

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
                Icon(Icons.check_circle_outline, size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(item)),
              ],
            ),
          ),
      ],
    );
  }
}
