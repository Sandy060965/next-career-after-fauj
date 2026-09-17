import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/profile_repository.dart';
import '../../core/widgets/home_button.dart';
import 'skill_equivalency.dart';

/// A read-only reference for how an officer's courses, institutions and
/// appointments translate to civilian language — separate from CV
/// Builder's course dropdown, which is the only place one of these actually
/// gets added to a CV. Kept deliberately simple (a single searchable list,
/// no per-entry detail screen) since [SkillEquivalency] itself is just a
/// few short strings, unlike the richer Learning Resources model this
/// screen is visually modelled on.
class SkillEquivalencyScreen extends StatefulWidget {
  const SkillEquivalencyScreen({super.key});

  @override
  State<SkillEquivalencyScreen> createState() => _SkillEquivalencyScreenState();
}

class _SkillEquivalencyScreenState extends State<SkillEquivalencyScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cvText = context.watch<ProfileRepository>().profile?.cvExtractedText;
    final query = _query.trim().toLowerCase();
    final results = query.isEmpty
        ? kSkillEquivalencies
        : kSkillEquivalencies
            .where(
              (e) =>
                  e.militaryTerm.toLowerCase().contains(query) ||
                  e.civilianEquivalent.toLowerCase().contains(query) ||
                  e.description.toLowerCase().contains(query),
            )
            .toList();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Skill Equivalency Matrix'), actions: const [HomeButton()]),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A reference for how your courses, institutions and appointments translate to '
                  'civilian language. To actually add one to your CV, use Build My Civilian CV — '
                  'this page is for looking things up.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('skillEquivalencySearchField'),
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search a course, institution or appointment',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ],
            ),
          ),
          if (results.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 4),
              child: Text('No matches for that search.'),
            )
          else
            for (final entry in results)
              ExpansionTile(
                key: Key('skillEquivalencyEntry_${entry.militaryTerm}'),
                leading: cvMentionsEquivalency(cvText, entry)
                    ? Icon(
                        Icons.check_circle,
                        key: Key('cvMatchBadge_${entry.militaryTerm}'),
                        color: colorScheme.primary,
                      )
                    : null,
                title: Text(entry.militaryTerm),
                subtitle: Text(
                  entry.civilianEquivalent,
                  style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.description),
                        if (!entry.verified) ...[
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline, size: 16, color: colorScheme.onSurfaceVariant),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Based on a single source rather than an official one — a real '
                                  'course/institution, but worth double-checking the wording '
                                  'yourself.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
        ],
      ),
    );
  }
}
