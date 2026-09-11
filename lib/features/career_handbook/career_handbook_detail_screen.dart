import 'package:flutter/material.dart';

import '../../core/routing/app_routes.dart';
import '../../core/widgets/home_button.dart';
import '../career_paths/career_vertical.dart';
import 'career_handbook_entries.dart';
import 'career_handbook_entry.dart';
import 'career_handbook_support.dart';

const _fallbackEntry = CareerHandbookEntry(
  verticalName: '',
  whatItDoes: 'A full write-up for this vertical is coming soon.',
  careerRoadmap: '',
  whoSucceeds: [],
  whoStruggles: [],
  whatYoudNeed: '',
);

class CareerHandbookDetailScreen extends StatelessWidget {
  const CareerHandbookDetailScreen({super.key, required this.vertical});

  final CareerVertical vertical;

  @override
  Widget build(BuildContext context) {
    final entry = kCareerHandbookEntries.firstWhere(
      (e) => e.verticalName == vertical.name,
      orElse: () => _fallbackEntry,
    );
    final related = relatedVerticals(vertical);
    final restrictionLabel = restrictionLabelFor(vertical);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(vertical.name), actions: const [HomeButton()]),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(vertical.category), visualDensity: VisualDensity.compact),
              if (restrictionLabel != null)
                Chip(
                  key: const Key('handbookRestrictionChip'),
                  label: Text(restrictionLabel),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: colorScheme.errorContainer,
                  labelStyle: TextStyle(color: colorScheme.onErrorContainer),
                ),
            ],
          ),
          if (entry.restrictionNote != null) ...[
            const SizedBox(height: 12),
            Text(
              entry.restrictionNote!,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontStyle: FontStyle.italic, color: colorScheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 20),
          _Section(title: 'What this vertical actually does', child: Text(entry.whatItDoes)),
          const SizedBox(height: 20),
          _Section(title: 'Career roadmap', child: Text(entry.careerRoadmap)),
          const SizedBox(height: 12),
          _LadderSummary(vertical: vertical),
          const SizedBox(height: 20),
          _Section(
            title: 'Who tends to succeed here',
            child: _BulletList(items: entry.whoSucceeds, icon: Icons.check_circle_outline, color: colorScheme.primary),
          ),
          if (entry.whoStruggles.isNotEmpty) ...[
            const SizedBox(height: 16),
            _BulletList(items: entry.whoStruggles, icon: Icons.info_outline, color: colorScheme.error),
          ],
          const SizedBox(height: 20),
          _Section(title: 'What you\'d need to get hired', child: Text(entry.whatYoudNeed)),
          if (vertical.bridgeCertifications.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Bridge certifications: ${vertical.bridgeCertifications.join(', ')}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
          if (related.isNotEmpty) ...[
            const SizedBox(height: 28),
            Text('Also look at', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in related)
                  ActionChip(
                    key: Key('relatedVertical_${r.name}'),
                    label: Text(r.name),
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => CareerHandbookDetailScreen(vertical: r)),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 28),
          Text('See how you compare', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.verticalFit),
                child: const Text('Career Vertical Fit'),
              ),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.cvBuilder),
                child: const Text('Build My Civilian CV'),
              ),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.compensation),
                child: const Text('Compensation Guidance'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LadderSummary extends StatelessWidget {
  const _LadderSummary({required this.vertical});

  final CareerVertical vertical;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final level in vertical.levels)
          Chip(
            visualDensity: VisualDensity.compact,
            backgroundColor: colorScheme.surfaceContainerHighest,
            label: Text('T${level.tier}: ${level.title} (${level.expMin}-${level.expMax == 42 ? '42+' : level.expMax}y)'),
          ),
      ],
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
  const _BulletList({required this.items, required this.icon, required this.color});

  final List<String> items;
  final IconData icon;
  final Color color;

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
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Expanded(child: Text(item)),
              ],
            ),
          ),
      ],
    );
  }
}
