import 'package:flutter/material.dart';

import 'corporate_language_detail_screen.dart';
import 'corporate_language_support.dart';
import 'corporate_language_term.dart';
import 'corporate_language_terms.dart';

const List<String> kCorporateLanguageCategories = [
  'Essential Corporate Abbreviations',
  'General Management & Strategy',
  'Finance & Accounting',
  'Sales & Marketing',
  'Operations, Supply Chain & Procurement',
  'Project & Program Management',
  'HR & People',
  'Technology, Data, AI & Cyber',
  'Procurement, Contracts, Legal & Governance',
  'Quality, Risk & Performance',
  'Consulting',
  'Banking & Financial Services',
  'Manufacturing, Engineering & Infrastructure',
  'Aerospace, Defence & Security',
  'Retail, FMCG, E-commerce & Consumer',
  'Healthcare & Pharma',
  'Telecom, IT Services & Shared Services',
  'Start-ups, Product, VC & PE',
  'PSU, Government & India-Specific Corporate',
  'Corporate Meeting, Email & Workplace Language',
];

List<CorporateLanguageTerm> _termsForCategory(String category) => kCorporateLanguageTerms
    .where((t) => t.category == category || t.crossCategories.contains(category))
    .toList();

List<CorporateLanguageTerm> _termsByName(List<String> names) => [
      for (final name in names)
        ...kCorporateLanguageTerms.where((t) => t.term == name),
    ];

/// "TERM" when there's no full form to expand, else "TERM (Full Form)" —
/// used everywhere a term is shown as a short list row, so the abbreviation
/// is never left unexplained.
String _titleWithFullForm(CorporateLanguageTerm t) =>
    t.fullForm == '—' ? t.term : '${t.term} (${t.fullForm})';

/// Every real abbreviation (a glossary term with a genuine full form) that
/// appears as a whole word in [text], each as "TERM = Full Form", in the
/// order they first appear in [text] — used to expand abbreviations that
/// show up bare inside a quoted phrase or a "X vs Y" pairing rather than as
/// a list row of their own.
List<String> _expandAbbreviationsIn(String text) {
  final matches = <(int, String)>[];
  final seen = <String>{};
  for (final t in kCorporateLanguageTerms) {
    if (t.fullForm == '—' || seen.contains(t.term)) continue;
    final pattern = RegExp('(?<![A-Za-z0-9])${RegExp.escape(t.term)}(?![A-Za-z0-9])');
    final match = pattern.firstMatch(text);
    if (match != null) {
      seen.add(t.term);
      matches.add((match.start, '${t.term} = ${t.fullForm}'));
    }
  }
  matches.sort((a, b) => a.$1.compareTo(b.$1));
  return [for (final m in matches) m.$2];
}

class CorporateLanguageGuideScreen extends StatefulWidget {
  const CorporateLanguageGuideScreen({super.key});

  @override
  State<CorporateLanguageGuideScreen> createState() => _CorporateLanguageGuideScreenState();
}

class _CorporateLanguageGuideScreenState extends State<CorporateLanguageGuideScreen> {
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
        ? const <CorporateLanguageTerm>[]
        : kCorporateLanguageTerms
            .where(
              (t) =>
                  t.term.toLowerCase().contains(query) ||
                  t.fullForm.toLowerCase().contains(query) ||
                  t.meaning.toLowerCase().contains(query),
            )
            .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Corporate Language Guide')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You already know leadership, planning, operations, logistics, people '
                  'management, risk, accountability and execution. This bridges the terminology '
                  'gap so you can follow how civilian organisations describe, measure and report '
                  'the same things.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('corporateLanguageSearchField'),
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search a term, abbreviation or meaning',
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
                child: Text('No terms match that search.'),
              )
            else
              for (final entry in results)
                ListTile(
                  key: Key('searchResult_${entry.term}'),
                  title: Text(_titleWithFullForm(entry)),
                  subtitle: Text(entry.meaning, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => CorporateLanguageDetailScreen(entry: entry)),
                  ),
                ),
          ] else ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton.icon(
                key: const Key('priorityTier1Button'),
                icon: const Icon(Icons.looks_one_outlined),
                label: const Text('Learn before Day 1 (50 terms)'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const _TermListScreen(
                      title: 'Learn before Day 1',
                      terms: null,
                      tier: 1,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                key: const Key('priorityTier2Button'),
                icon: const Icon(Icons.looks_two_outlined),
                label: const Text('Learn within the first month (50 terms)'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const _TermListScreen(
                      title: 'Learn within the first month',
                      terms: null,
                      tier: 2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                key: const Key('priorityTier3Button'),
                icon: const Icon(Icons.trending_up),
                label: const Text('Build depth as your role develops'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const _TermListScreen(
                      title: 'Build depth as your role develops',
                      terms: null,
                      tier: 3,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                key: const Key('mindsetBridgeButton'),
                icon: const Icon(Icons.compare_arrows),
                label: const Text('Military-to-corporate mindset bridge'),
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const _MindsetBridgeScreen())),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                key: const Key('confusedTermsButton'),
                icon: const Icon(Icons.help_outline),
                label: const Text('Commonly confused terms'),
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const _ConfusedTermsScreen())),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                key: const Key('meetingPhrasesButton'),
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('What you\'ll hear in your first meetings'),
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const _MeetingPhrasesScreen())),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                key: const Key('roleQuickReferenceButton'),
                icon: const Icon(Icons.badge_outlined),
                label: const Text('Role-specific quick reference'),
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const _RoleListScreen())),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
              child: Text('Browse by category', style: Theme.of(context).textTheme.titleSmall),
            ),
            for (final category in kCorporateLanguageCategories)
              ListTile(
                key: Key('category_$category'),
                title: Text(category),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _TermListScreen(title: category, terms: _termsForCategory(category)),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _TermListScreen extends StatelessWidget {
  const _TermListScreen({required this.title, required this.terms, this.tier});

  final String title;
  final List<CorporateLanguageTerm>? terms;
  final int? tier;

  @override
  Widget build(BuildContext context) {
    final items = terms ?? kCorporateLanguageTerms.where((t) => t.priorityTier == tier).toList();
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        children: [
          for (final entry in items)
            ListTile(
              key: Key('termListEntry_${entry.term}'),
              title: Text(_titleWithFullForm(entry)),
              subtitle: Text(entry.meaning, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => CorporateLanguageDetailScreen(entry: entry)),
              ),
            ),
        ],
      ),
    );
  }
}

class _MindsetBridgeScreen extends StatelessWidget {
  const _MindsetBridgeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mindset bridge')),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: kMindsetBridge.length,
        separatorBuilder: (_, __) => const Divider(height: 24),
        itemBuilder: (context, i) {
          final b = kMindsetBridge[i];
          return Row(
            children: [
              Expanded(child: Text(b.military, style: Theme.of(context).textTheme.bodyMedium)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward, size: 16),
              ),
              Expanded(child: Text(b.corporate, style: Theme.of(context).textTheme.bodyMedium)),
            ],
          );
        },
      ),
    );
  }
}

class _ConfusedTermsScreen extends StatelessWidget {
  const _ConfusedTermsScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Commonly confused terms')),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: kConfusedTermPairs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, i) {
          final c = kConfusedTermPairs[i];
          final expansions = _expandAbbreviationsIn(c.pair);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.pair, style: Theme.of(context).textTheme.titleSmall),
              if (expansions.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  expansions.join('  •  '),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 4),
              Text(c.distinction),
            ],
          );
        },
      ),
    );
  }
}

class _MeetingPhrasesScreen extends StatelessWidget {
  const _MeetingPhrasesScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('What you\'ll hear in your first meetings')),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: kMeetingPhrases.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, i) {
          final m = kMeetingPhrases[i];
          final expansions = _expandAbbreviationsIn(m.heard);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(m.heard, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontStyle: FontStyle.italic)),
              if (expansions.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  expansions.join('  •  '),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 4),
              Text(m.means),
            ],
          );
        },
      ),
    );
  }
}

class _RoleListScreen extends StatelessWidget {
  const _RoleListScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Role-specific quick reference')),
      body: ListView(
        children: [
          for (final r in kRoleQuickReferences)
            ListTile(
              key: Key('role_${r.role}'),
              title: Text(r.role),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _TermListScreen(title: r.role, terms: _termsByName(r.terms)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
