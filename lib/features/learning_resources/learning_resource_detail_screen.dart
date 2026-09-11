import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/learning_resource.dart';
import '../../core/widgets/home_button.dart';

class LearningResourceDetailScreen extends StatelessWidget {
  const LearningResourceDetailScreen({super.key, required this.resource});

  final LearningResource resource;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(resource.name), actions: const [HomeButton()]),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(resource.provider, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                key: const Key('costChip'),
                label: Text(resource.cost.label),
                visualDensity: VisualDensity.compact,
                backgroundColor: switch (resource.cost) {
                  ResourceCost.free => colorScheme.primaryContainer,
                  ResourceCost.freeToLearnPaidCertificate => colorScheme.secondaryContainer,
                  ResourceCost.paid => colorScheme.surfaceContainerHighest,
                },
              ),
              Chip(label: Text(resource.resourceType.label), visualDensity: VisualDensity.compact),
              Chip(label: Text(resource.level), visualDensity: VisualDensity.compact),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            resource.duration,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          Text('About', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(resource.description),
          if (resource.practicalProject != null) ...[
            const SizedBox(height: 20),
            Text('Practical project', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              key: const Key('practicalProjectBox'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(resource.practicalProject!),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            key: const Key('openResourceButton'),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open resource'),
            onPressed: () => launchUrl(Uri.parse(resource.url), mode: LaunchMode.externalApplication),
          ),
          const SizedBox(height: 8),
          Text(
            'Last verified ${resource.lastVerified}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
