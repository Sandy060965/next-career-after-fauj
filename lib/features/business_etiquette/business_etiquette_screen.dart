import 'package:flutter/material.dart';

import '../../core/widgets/home_button.dart';
import 'business_etiquette_detail_screen.dart';
import 'business_etiquette_sections.dart';

class BusinessEtiquetteScreen extends StatelessWidget {
  const BusinessEtiquetteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Etiquette & Professional Conduct'),
        actions: const [HomeButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
            child: Text(
              'A practical day-to-day guide to everyday etiquette, communication norms and '
              'professional boundaries — to reduce avoidable social and professional friction '
              'during your first months in the corporate workplace. When uncertain, observe '
              'the local norm, choose the more respectful option, and ask rather than assume.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < kBusinessEtiquetteSections.length; i++)
            ListTile(
              key: Key('businessEtiquetteEntry_${kBusinessEtiquetteSections[i].title}'),
              leading: CircleAvatar(
                radius: 14,
                child: Text('${i + 1}', style: Theme.of(context).textTheme.labelSmall),
              ),
              title: Text(kBusinessEtiquetteSections[i].title),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BusinessEtiquetteDetailScreen(section: kBusinessEtiquetteSections[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
