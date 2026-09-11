import 'package:flutter/material.dart';

import '../../core/models/learning_resource.dart';
import '../../core/widgets/home_button.dart';
import 'learning_resource_detail_screen.dart';
import 'learning_resources_data.dart';

List<LearningResource> _resourcesForCategory(String category) =>
    kLearningResources.where((r) => r.category == category).toList();

class LearningResourcesScreen extends StatefulWidget {
  const LearningResourcesScreen({super.key});

  @override
  State<LearningResourcesScreen> createState() => _LearningResourcesScreenState();
}

class _LearningResourcesScreenState extends State<LearningResourcesScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final results = query.isEmpty
        ? const <LearningResource>[]
        : kLearningResources
            .where(
              (r) =>
                  r.name.toLowerCase().contains(query) ||
                  r.provider.toLowerCase().contains(query) ||
                  r.description.toLowerCase().contains(query) ||
                  r.tags.any((t) => t.toLowerCase().contains(query)),
            )
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Resources Library'),
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
                  'Hand-verified free, low-cost and professional learning resources to close the '
                  'specific gaps your assessments identify — not a certificate collection, a way to '
                  'become capable of the work a target role actually requires.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('learningResourcesSearchField'),
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search a resource, provider, skill or topic',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ],
            ),
          ),
          if (query.isNotEmpty) ...[
            if (results.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 16, 24, 4),
                child: Text('No resources match that search.'),
              )
            else
              for (final entry in results)
                ListTile(
                  key: Key('searchResult_${entry.id}'),
                  title: Text(entry.name),
                  subtitle: Text('${entry.provider} · ${entry.cost.label}', maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => LearningResourceDetailScreen(resource: entry)),
                  ),
                ),
          ] else ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
              child: Text('Browse by category', style: Theme.of(context).textTheme.titleSmall),
            ),
            for (final category in kLearningResourceCategories)
              ListTile(
                key: Key('category_$category'),
                title: Text(category),
                subtitle: Text('${_resourcesForCategory(category).length} resources'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _ResourceListScreen(
                      title: category,
                      resources: _resourcesForCategory(category),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ResourceListScreen extends StatelessWidget {
  const _ResourceListScreen({required this.title, required this.resources});

  final String title;
  final List<LearningResource> resources;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: const [HomeButton()]),
      body: ListView(
        children: [
          for (final entry in resources)
            ListTile(
              key: Key('resourceListEntry_${entry.id}'),
              title: Text(entry.name),
              subtitle: Text('${entry.provider} · ${entry.cost.label}', maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => LearningResourceDetailScreen(resource: entry)),
              ),
            ),
        ],
      ),
    );
  }
}
