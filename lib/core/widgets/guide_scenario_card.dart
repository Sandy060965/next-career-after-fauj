import 'package:flutter/material.dart';

/// One Situation -> [What You May Encounter ->] Recommended Response ->
/// Avoid entry, the format both the Corporate Culture and Business
/// Etiquette guides use throughout. Stacked, labeled blocks rather than a
/// literal wide table — a 4-column table has no usable layout on a phone
/// screen. [whatYouMayEncounter] is nullable since the Corporate Culture
/// guide's tables use a 3-part Situation/Response/Avoid shape while the
/// Business Etiquette guide's use the full 4-part shape — forcing both
/// into one rigid shape would mean inventing content that isn't in the
/// source.
class ScenarioCard extends StatelessWidget {
  const ScenarioCard({
    super.key,
    this.heading,
    required this.situation,
    this.whatYouMayEncounter,
    required this.recommendedResponse,
    required this.avoid,
  });

  final String? heading;
  final String situation;
  final String? whatYouMayEncounter;
  final String recommendedResponse;
  final String avoid;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (heading != null) ...[
              Text(heading!, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 10),
            ],
            _Row(label: 'Situation', text: situation, color: colorScheme.onSurface),
            if (whatYouMayEncounter != null) ...[
              const SizedBox(height: 10),
              _Row(label: 'What you may encounter', text: whatYouMayEncounter!, color: colorScheme.onSurfaceVariant),
            ],
            const SizedBox(height: 10),
            _Row(label: 'Recommended response', text: recommendedResponse, color: colorScheme.primary),
            const SizedBox(height: 10),
            _Row(label: 'Avoid', text: avoid, color: colorScheme.error),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.text, required this.color});

  final String label;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, letterSpacing: 0.6),
        ),
        const SizedBox(height: 2),
        Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

/// A simple "instead of this military-style phrasing -> try this corporate
/// formulation" pair — the phrasing-playbook tables both guides include.
class TranslationRow extends StatelessWidget {
  const TranslationRow({super.key, required this.from, required this.to});

  final String from;
  final String to;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('"$from"', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.arrow_forward, size: 16, color: colorScheme.primary),
              const SizedBox(width: 6),
              Expanded(child: Text('"$to"', style: Theme.of(context).textTheme.bodyMedium)),
            ],
          ),
        ],
      ),
    );
  }
}
