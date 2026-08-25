import 'package:flutter/material.dart';

import 'cv_template.dart';
import 'template_sharer.dart';

/// One section of the recommended CV structure — a major heading plus the
/// sub-points that belong under it. Fixed, hand-authored reference content,
/// the same discipline as the Skill Equivalency Matrix: real guidance, not
/// AI-generated per request.
class _StructureSection {
  const _StructureSection({required this.heading, required this.points});

  final String heading;
  final List<String> points;
}

const _structure = [
  _StructureSection(
    heading: 'Header',
    points: [
      'Full name, city, mobile number, email address, and LinkedIn URL.',
      'No photograph, date of birth, or marital status — not expected on an Indian '
          'corporate CV and irrelevant to hiring decisions.',
    ],
  ),
  _StructureSection(
    heading: 'Target Role / Professional Summary',
    points: [
      'One line naming the type of role you\'re targeting, directly under your name.',
      '3-4 sentences: years of experience, the scale you\'ve operated at (team size, '
          'budget, or scope), your core strength area — in plain civilian language.',
    ],
  ),
  _StructureSection(
    heading: 'Core Skills',
    points: [
      '8-12 specific, role-relevant skills — not a generic list copied between '
          'applications. Tailor this to each target role where you can.',
    ],
  ),
  _StructureSection(
    heading: 'Professional Experience',
    points: [
      'Sub-heading per role: Designation | Organisation (in civilian terms) | Dates '
          'held (Month Year – Month Year).',
      'Responsibilities: what you owned, and at what scale (team size, budget, assets).',
      'Challenges handled: a specific problem you faced, what you did about it, and '
          'the outcome — not just a list of duties.',
      'Achievements: quantified wherever possible — a percentage, a rupee figure, a '
          'headcount, or time saved. This is the single highest-value part of the CV.',
      'Most recent role first. Two to four roles is usually enough — older roles can '
          'be condensed to a line each.',
    ],
  ),
  _StructureSection(
    heading: 'Key Achievements (optional standalone section)',
    points: [
      'Worth pulling out as its own section — 3-4 bullets — if you have strong, '
          'quantified results that would otherwise get buried inside role descriptions.',
    ],
  ),
  _StructureSection(
    heading: 'Education',
    points: ['Degree/programme, institution, and year — most recent or highest first.'],
  ),
  _StructureSection(
    heading: 'Certifications',
    points: ['Certification name, issuing body, and year — only ones relevant to your target roles.'],
  ),
  _StructureSection(
    heading: 'Languages',
    points: ['Language and proficiency level (e.g. Fluent, Working, Conversational).'],
  ),
];

class _Guideline {
  const _Guideline({required this.title, required this.detail});

  final String title;
  final String detail;
}

const _guidelines = [
  _Guideline(
    title: 'Never use defence abbreviations or jargon',
    detail: 'Terms like "GSO", "adm", or unit/formation shorthand mean nothing to a '
        'civilian recruiter. Translate rank, appointment, and scale into plain language '
        '— see the Skill Equivalency Matrix for real course/appointment translations.',
  ),
  _Guideline(
    title: 'Never include ACR, classified, or unit-identifying content',
    detail: 'The same rule that applies everywhere else in this app applies to your CV '
        'too — no service-record documents, no classified details, no unit-identifying '
        'specifics.',
  ),
  _Guideline(
    title: 'Describe challenges, not just duties',
    detail: 'A recruiter wants to see judgement under pressure, not a job description. '
        'For each role, name a specific challenge, what you actually did, and what '
        'happened as a result.',
  ),
  _Guideline(
    title: 'Quantify achievements — build a real KPI-based achievement matrix',
    detail: 'Wherever the real number exists, use it: percentage improvement, rupee '
        'value, headcount managed, time saved, error/defect reduction. "Managed '
        'logistics" is a duty; "Cut average dispatch time by 30% across a 40-person '
        'team" is an achievement.',
  ),
  _Guideline(
    title: 'State designation and exact dates for every role',
    detail: 'Recruiters and ATS systems both expect a clear Month/Year start and end '
        'for each position — gaps or vague ranges read as evasive even when they\'re not.',
  ),
  _Guideline(
    title: 'Keep skills specific, not generic',
    detail: 'List the skills that are actually relevant to the roles you\'re targeting, '
        'ideally echoing language used in real job descriptions you\'ve seen — not a '
        'generic "hardworking, team player" list.',
  ),
  _Guideline(
    title: 'List qualifications, certifications, and languages clearly',
    detail: 'Keep these as their own short, scannable sections rather than folding them '
        'into paragraphs — recruiters and ATS parsers both look for them as distinct '
        'fields.',
  ),
  _Guideline(
    title: 'Keep it to 1-2 pages, and tailor it per job description',
    detail: 'A longer CV rarely reads as more impressive. Use JD Match to see how well '
        'your CV already fits a specific role, and tighten accordingly.',
  ),
  _Guideline(
    title: 'One consistent, readable format throughout',
    detail: 'Stick to one font, consistent heading styles, and a single column — this is '
        'exactly what makes a CV parse reliably through ATS software, not just look tidy.',
  ),
];

class CvWritingGuideScreen extends StatefulWidget {
  const CvWritingGuideScreen({super.key, this.shareTemplate = shareTemplateFile});

  /// Overridable for testing so the platform share sheet is never actually
  /// invoked in a test run.
  final TemplateSharer shareTemplate;

  @override
  State<CvWritingGuideScreen> createState() => _CvWritingGuideScreenState();
}

class _CvWritingGuideScreenState extends State<CvWritingGuideScreen> {
  String? _sharingTemplateName;
  String? _error;

  Future<void> _download(CvTemplate template) async {
    setState(() {
      _sharingTemplateName = template.name;
      _error = null;
    });
    try {
      await widget.shareTemplate(template);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = "Couldn't open the share sheet for ${template.name}: $e");
    } finally {
      if (mounted) setState(() => _sharingTemplateName = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CV Writing Guide')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Six ready-to-use CV templates, plus guidance on structuring and writing your '
            'own — every template is a blank layout with bracketed placeholders for you to '
            'fill in, never sample content to copy.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Text('Download a template', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          for (final template in kCvTemplates) _TemplateCard(
            template: template,
            isSharing: _sharingTemplateName == template.name,
            onDownload: () => _download(template),
          ),
          const SizedBox(height: 12),
          Text('How to structure your CV', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final section in _structure) _StructureCard(section: section),
          const SizedBox(height: 12),
          Text('Guidelines to keep in mind', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final guideline in _guidelines) _GuidelineTile(guideline: guideline),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template, required this.isSharing, required this.onDownload});

  final CvTemplate template;
  final bool isSharing;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey('cvTemplate_${template.name}'),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(template.name, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(template.description, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 12),
            isSharing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : IconButton(
                    key: ValueKey('downloadTemplate_${template.name}'),
                    tooltip: 'Download',
                    onPressed: onDownload,
                    icon: const Icon(Icons.file_download_outlined),
                  ),
          ],
        ),
      ),
    );
  }
}

class _StructureCard extends StatelessWidget {
  const _StructureCard({required this.section});

  final _StructureSection section;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey('cvStructure_${section.heading}'),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(section.heading, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            for (final point in section.points)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(child: Text(point, style: Theme.of(context).textTheme.bodySmall)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GuidelineTile extends StatelessWidget {
  const _GuidelineTile({required this.guideline});

  final _Guideline guideline;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey('cvGuideline_${guideline.title}'),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle_outline, size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(guideline.title, style: Theme.of(context).textTheme.titleSmall)),
              ],
            ),
            const SizedBox(height: 6),
            Text(guideline.detail, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
