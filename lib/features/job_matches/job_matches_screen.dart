import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/profile_repository.dart';
import '../../core/utils/date_format.dart';
import '../application_tracker/add_edit_application_screen.dart';
import 'india_cities.dart';
import 'job_match.dart';
import 'job_matches_service.dart';

class JobMatchesScreen extends StatefulWidget {
  const JobMatchesScreen({super.key, this.analyzeJobMatches = mockAnalyzeJobMatches});

  /// Overridable for testing; defaults to sample data until the Worker's
  /// /job-matches endpoint is wired in.
  final JobMatchesAnalyzer analyzeJobMatches;

  @override
  State<JobMatchesScreen> createState() => _JobMatchesScreenState();
}

class _JobMatchesScreenState extends State<JobMatchesScreen> {
  CityTier? _selectedTier;
  bool _isLoading = false;
  String? _error;
  List<JobMatch>? _matches;

  @override
  void initState() {
    super.initState();
    _runSearch();
  }

  Future<void> _runSearch() async {
    final profile = context.read<ProfileRepository>().profile;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await widget.analyzeJobMatches(
        cvText: profile?.cvExtractedText ?? profile?.cvFileName ?? '',
        cityTier: _selectedTier,
        cvPdfBytes: profile?.cvPdfBytes,
      );
      if (!mounted) return;
      setState(() {
        _matches = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Job Matches')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Open roles matched against your CV, from Naukri, Indeed, and LinkedIn.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                SegmentedButton<CityTier?>(
                  key: const Key('cityTierFilter'),
                  segments: const [
                    ButtonSegment(value: null, label: Text('All cities')),
                    ButtonSegment(value: CityTier.tier1, label: Text('Tier 1')),
                    ButtonSegment(value: CityTier.tier2, label: Text('Tier 2')),
                  ],
                  selected: {_selectedTier},
                  onSelectionChanged: (selection) {
                    setState(() => _selectedTier = selection.first);
                    _runSearch();
                  },
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }
    final matches = _matches ?? const [];
    if (matches.isEmpty) {
      return const Center(child: Text('No matching listings found.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      itemCount: matches.length,
      itemBuilder: (context, index) => _JobMatchCard(match: matches[index]),
    );
  }
}

class _JobMatchCard extends StatelessWidget {
  const _JobMatchCard({required this.match});

  final JobMatch match;

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
            Text(match.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    match.company,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                if (match.isTopCompany)
                  Chip(
                    key: const Key('topCompanyBadge'),
                    label: const Text('Top company'),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: colorScheme.tertiaryContainer,
                    labelStyle: TextStyle(color: colorScheme.onTertiaryContainer, fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Chip(
                  label: Text(match.portal.label),
                  visualDensity: VisualDensity.compact,
                ),
                if (match.location != null)
                  Chip(label: Text(match.location!), visualDensity: VisualDensity.compact),
                if (_formatPostedDate(match.postedDate) != null)
                  Chip(
                    label: Text(_formatPostedDate(match.postedDate)!),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'CTC: ${match.ctcRange ?? "Not disclosed"}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(match.fitReason, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                key: ValueKey('viewListing_${match.applyUrl}'),
                onPressed: () => launchUrl(Uri.parse(match.applyUrl), mode: LaunchMode.externalApplication),
                child: const Text('View listing'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                key: ValueKey('trackApplication_${match.applyUrl}'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddEditApplicationScreen(
                      initialCompanyName: match.company,
                      initialRoleTitle: match.title,
                      initialSource: 'Job Matches',
                    ),
                  ),
                ),
                child: const Text('Track this application'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Parses the ISO 8601 timestamp JSearch returns and renders it in the
/// app's standard date format. Falls back to the raw value if it can't be
/// parsed, rather than hiding a real (if oddly formatted) posted date.
String? _formatPostedDate(String? raw) {
  if (raw == null) return null;
  final parsed = DateTime.tryParse(raw);
  return parsed == null ? raw : formatDate(parsed);
}
