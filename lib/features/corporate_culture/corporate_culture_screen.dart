import 'package:flutter/material.dart';

import '../../core/widgets/home_button.dart';
import 'corporate_culture_detail_screen.dart';
import 'corporate_culture_sections.dart';

class CorporateCultureScreen extends StatelessWidget {
  const CorporateCultureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Corporate Culture & Work Environment'),
        actions: const [HomeButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
            child: Text(
              'A practical guide to the everyday differences you may encounter after '
              'transition — how authority, decisions and performance are read '
              'differently in a corporate or PSU environment — so you can adapt faster '
              'without losing the strengths you bring from service.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < kCorporateCultureSections.length; i++)
            ListTile(
              key: Key('corporateCultureEntry_${kCorporateCultureSections[i].title}'),
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  '${i + 1}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              title: Text(kCorporateCultureSections[i].title),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CorporateCultureDetailScreen(section: kCorporateCultureSections[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
