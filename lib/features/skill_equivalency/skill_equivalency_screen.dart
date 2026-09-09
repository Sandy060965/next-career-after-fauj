import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/cv_redaction_scanner.dart';
import '../../core/services/profile_repository.dart';
import '../onboarding/cv_redaction_review_sheet.dart';
import 'course_civilianization.dart';
import 'course_civilianization_http_service.dart';
import 'course_civilianization_service.dart';
import 'skill_equivalency.dart';

class SkillEquivalencyScreen extends StatefulWidget {
  const SkillEquivalencyScreen({
    super.key,
    this.civilianizeCourse = mockCivilianizeCourse,
    this.fetchApprovedEquivalencies = httpFetchApprovedEquivalencies,
  });

  /// Overridable for testing; defaults to sample data until the Worker's
  /// /civilianize-course endpoint is wired in.
  final CourseCivilianizer civilianizeCourse;

  /// Overridable for testing; defaults to the real backend call. Courses
  /// admin-approved from officer submissions, fetched fresh so the list
  /// grows over time without needing a new app release.
  final Future<List<SkillEquivalency>> Function() fetchApprovedEquivalencies;

  @override
  State<SkillEquivalencyScreen> createState() => _SkillEquivalencyScreenState();
}

class _SkillEquivalencyScreenState extends State<SkillEquivalencyScreen> {
  final _courseNameController = TextEditingController();
  final _courseDescController = TextEditingController();
  final _searchController = TextEditingController();

  bool _isSubmitting = false;
  String? _error;
  CourseCivilianizationResult? _result;
  String? _submittedCourseName;
  String _searchQuery = '';
  List<SkillEquivalency> _approvedEquivalencies = const [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
    _loadApprovedEquivalencies();
  }

  Future<void> _loadApprovedEquivalencies() async {
    try {
      final approved = await widget.fetchApprovedEquivalencies();
      if (!mounted) return;
      setState(() => _approvedEquivalencies = approved);
    } catch (_) {
      // Best-effort — the curated list on its own is still a complete,
      // useful screen without these.
    }
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    _courseDescController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<SkillEquivalency> get _allEntries => [...kSkillEquivalencies, ..._approvedEquivalencies];

  /// A simple, fast keyword match rather than an AI call on every screen
  /// load — catches most real cases (the course name, or a common short
  /// form of it, actually appearing in the CV text) without the latency or
  /// cost of a semantic match for something that should feel instant.
  bool _mentionedInCv(SkillEquivalency entry, String? cvText) {
    if (cvText == null || cvText.isEmpty) return false;
    return cvText.toLowerCase().contains(entry.militaryTerm.toLowerCase());
  }

  List<SkillEquivalency> _visibleEntries(String? cvText) {
    final query = _searchQuery.trim().toLowerCase();
    final entries = query.isEmpty
        ? _allEntries
        : _allEntries
            .where(
              (e) =>
                  e.militaryTerm.toLowerCase().contains(query) ||
                  e.civilianEquivalent.toLowerCase().contains(query),
            )
            .toList();
    // Courses mentioned in the officer's own CV surface first, so the ones
    // actually relevant to them don't require scrolling or searching.
    final sorted = [...entries];
    sorted.sort((a, b) {
      final aIn = _mentionedInCv(a, cvText);
      final bIn = _mentionedInCv(b, cvText);
      if (aIn == bIn) return 0;
      return aIn ? -1 : 1;
    });
    return sorted;
  }

  Future<void> _submitCourse() async {
    final name = _courseNameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter the course or training name to continue');
      return;
    }

    var description = _courseDescController.text.trim();
    if (description.isNotEmpty) {
      final matches = scanForRedactions(description);
      if (matches.isNotEmpty) {
        final reviewed = await showCvRedactionReview(
          context,
          extractedText: description,
          matches: matches,
        );
        if (!mounted) return;
        if (reviewed == null) {
          // Officer chose to reconsider rather than review — don't submit
          // unreviewed text.
          return;
        }
        description = reviewed;
      }
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
      _result = null;
    });

    final mobileNumber = context.read<ProfileRepository>().profile?.mobileNumber;
    try {
      final result = await widget.civilianizeCourse(
        courseName: name,
        courseDescription: description.isEmpty ? null : description,
        mobileNumber: mobileNumber,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _submittedCourseName = name;
        _isSubmitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _isSubmitting = false;
      });
    }
  }

  void _submitAnother() {
    setState(() {
      _result = null;
      _submittedCourseName = null;
      _error = null;
      _courseNameController.clear();
      _courseDescController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cvText = context.watch<ProfileRepository>().profile?.cvExtractedText;
    final visibleEntries = _visibleEntries(cvText);
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Skill Equivalency Matrix')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'How your military courses, commands, and appointments map to civilian '
            'corporate roles and language.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('skillEquivalencySearchField'),
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search a course, institution, or civilian role',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear search',
                      onPressed: () => _searchController.clear(),
                    ),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          if (visibleEntries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                "No match in the list — name it below and we'll look it up for you.",
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            )
          else
            for (final entry in visibleEntries)
              _EquivalencyCard(
                entry: entry,
                // Only ever flags a caution (verified: false) — a genuinely
                // verified entry shows no badge at all, since being in this
                // list at all already implies it's been vetted.
                verified: entry.verified ? null : false,
                sourceNote: entry.verified
                    ? null
                    : 'A real, named course/institution, but resting on a single non-official '
                        'source rather than multiple corroborating sources.',
                inCv: _mentionedInCv(entry, cvText),
              ),
          const SizedBox(height: 12),
          _buildNotListedSection(context),
        ],
      ),
    );
  }

  Widget _buildNotListedSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (_result != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Don't see your course?", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _EquivalencyCard(
            entry: SkillEquivalency(
              militaryTerm: _submittedCourseName ?? '',
              civilianEquivalent: _result!.civilianEquivalent,
              description: _result!.description,
            ),
            verified: _result!.verified,
            sourceNote: _result!.sourceNote,
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: const Key('submitAnotherCourseButton'),
            onPressed: _submitAnother,
            child: const Text('Look up another course'),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Don't see your course?", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            "Name it below — we'll look it up and translate it, even if it isn't in the "
            'list above yet.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('courseNameField'),
            controller: _courseNameController,
            decoration: const InputDecoration(labelText: 'Course or training name'),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('courseDescriptionField'),
            controller: _courseDescController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Briefly, what did it cover? (optional)',
              alignLabelWithHint: true,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: colorScheme.error, fontSize: 12)),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const Key('submitCourseButton'),
              onPressed: _isSubmitting ? null : _submitCourse,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Look this up'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EquivalencyCard extends StatelessWidget {
  const _EquivalencyCard({required this.entry, this.verified, this.sourceNote, this.inCv = false});

  final SkillEquivalency entry;

  /// Non-null only for an officer-submitted lookup — true/false renders a
  /// badge distinguishing a web-verified translation from one based solely
  /// on the officer's own description. Null (the curated-list case) shows
  /// no badge at all.
  final bool? verified;
  final String? sourceNote;

  /// True when this course appears to be mentioned in the officer's own CV
  /// (a plain keyword match, not an AI judgement) — highlighted so the
  /// entries actually relevant to them don't require searching or
  /// scrolling to find.
  final bool inCv;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      key: ValueKey('equivalency_${entry.militaryTerm}'),
      margin: const EdgeInsets.only(bottom: 12),
      shape: inCv
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.primary, width: 1.5),
            )
          : null,
      color: inCv ? colorScheme.primaryContainer.withValues(alpha: 0.25) : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (inCv) ...[
              Chip(
                key: const Key('inCvBadge'),
                avatar: Icon(Icons.check_circle, size: 16, color: colorScheme.primary),
                label: const Text('In your CV'),
                visualDensity: VisualDensity.compact,
                backgroundColor: colorScheme.primaryContainer,
              ),
              const SizedBox(height: 8),
            ],
            Text(entry.militaryTerm, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.arrow_downward, size: 16, color: colorScheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    entry.civilianEquivalent,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(entry.description, style: Theme.of(context).textTheme.bodySmall),
            if (verified != null) ...[
              const SizedBox(height: 8),
              Chip(
                key: const Key('courseVerifiedBadge'),
                label: Text(verified! ? 'Verified via web search' : 'Not independently verified'),
                visualDensity: VisualDensity.compact,
                backgroundColor: verified! ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
              ),
              if (sourceNote != null && sourceNote!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  sourceNote!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontStyle: FontStyle.italic, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
