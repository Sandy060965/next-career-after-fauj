import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routing/app_routes.dart';
import '../../core/services/file_picker_service.dart';
import '../../core/services/pdf_export.dart';
import '../../core/services/profile_repository.dart';
import '../../core/widgets/home_button.dart';
import '../cv_templates/cv_pdf_fonts.dart';
import '../cv_templates/cv_template_data.dart';
import '../cv_templates/cv_template_registry.dart';

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
    title: 'Never include your Record of Service or confidential/sensitive service information',
    detail: 'The same rule that applies everywhere else in this app applies to your CV too '
        '— no service-record documents, no confidential or sensitive service details, no '
        'classified content.',
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

Future<PickedFile?> _defaultPickPhoto() => pickFileWithBytes(allowedExtensions: const ['jpg', 'jpeg', 'png']);

class CvWritingGuideScreen extends StatefulWidget {
  const CvWritingGuideScreen({
    super.key,
    this.pickPhoto = _defaultPickPhoto,
    this.loadFonts = CvPdfFonts.load,
    this.onDeliverPdf = deliverPdfBytes,
  });

  /// Overridable for testing so the native file-picker channel is never
  /// actually invoked in a test run.
  final Future<PickedFile?> Function() pickPhoto;

  /// Overridable for testing so bundled font assets don't need loading.
  final Future<CvPdfFonts> Function() loadFonts;

  /// Overridable for testing so the platform share/download path is never
  /// actually invoked in a test run.
  final Future<void> Function(Uint8List bytes, String fileName) onDeliverPdf;

  @override
  State<CvWritingGuideScreen> createState() => _CvWritingGuideScreenState();
}

class _CvWritingGuideScreenState extends State<CvWritingGuideScreen> {
  bool _isUpdatingPhoto = false;
  String? _photoError;

  Future<void> _addPhoto() async {
    setState(() {
      _isUpdatingPhoto = true;
      _photoError = null;
    });
    try {
      final picked = await widget.pickPhoto();
      if (picked != null && mounted) {
        await context.read<ProfileRepository>().updatePhoto(photoFileName: picked.name, photoBytes: picked.bytes);
      }
    } on UnsupportedFileTypeException catch (e) {
      if (mounted) setState(() => _photoError = e.message);
    } finally {
      if (mounted) setState(() => _isUpdatingPhoto = false);
    }
  }

  Future<void> _removePhoto() async {
    setState(() => _isUpdatingPhoto = true);
    try {
      await context.read<ProfileRepository>().updatePhoto();
    } finally {
      if (mounted) setState(() => _isUpdatingPhoto = false);
    }
  }

  Future<void> _download(CvPdfTemplate template) async {
    try {
      final data = CvTemplateData.fromRepository(context.read<ProfileRepository>());
      final fonts = await widget.loadFonts();
      final bytes = await template.build(data, fonts).save();
      final safeName = template.name.replaceAll(RegExp(r'[^A-Za-z0-9 _-]'), '').trim();
      await widget.onDeliverPdf(bytes, 'CV_$safeName.pdf');
    } catch (e) {
      if (!mounted) return;
      // A SnackBar rather than an inline error banner — the preview dialog
      // sits above the page content, so an inline message near the top
      // would go unnoticed while it's open.
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text("Couldn't generate ${template.name}: $e")));
    }
  }

  void _openPreview(CvPdfTemplate template, {required bool hasCvData}) {
    showDialog<void>(
      context: context,
      builder: (_) => _TemplatePreviewDialog(
        template: template,
        canDownload: hasCvData,
        onDownload: () => _download(template),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ProfileRepository>();
    final intake = repo.lastCvBuilderIntake;
    final hasCvData = intake != null && intake.workExperience.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CV Writing Guide'),
        actions: const [HomeButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            '20 ready-to-use CV designs, auto-filled from your CV Builder details, plus guidance on '
            'structuring and writing your own.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            key: const Key('goToCvExamplesButton'),
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.cvExamples),
            icon: const Icon(Icons.menu_book_outlined),
            label: const Text('Not sure how to phrase your CV? Browse 54 example CVs by rank and service'),
          ),
          const SizedBox(height: 16),
          _PhotoRow(
            photoBytes: repo.profile?.photoBytes,
            isBusy: _isUpdatingPhoto,
            onAdd: _addPhoto,
            onRemove: _removePhoto,
          ),
          if (_photoError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _photoError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
              ),
            ),
          if (!hasCvData) ...[
            const SizedBox(height: 12),
            Card(
              key: const Key('cvTemplatesNoDataBanner'),
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Build your CV first to unlock templates',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(color: Theme.of(context).colorScheme.onErrorContainer),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Templates are auto-filled from your CV Builder details (role titles, dates, '
                      'responsibilities). Without that, there\'s nothing to put in them — so downloads '
                      'stay off until you\'ve built your CV.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Theme.of(context).colorScheme.onErrorContainer),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      key: const Key('goToCvBuilderButton'),
                      onPressed: () => Navigator.of(context).pushNamed(AppRoutes.cvBuilder),
                      child: const Text('Build my CV'),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text('Choose a template', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Tap a design to see the full page and download it.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: kCvPdfTemplates.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 190,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            itemBuilder: (context, index) {
              final template = kCvPdfTemplates[index];
              return _TemplateThumbnail(
                template: template,
                onTap: () => _openPreview(template, hasCvData: hasCvData),
              );
            },
          ),
          const SizedBox(height: 20),
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

class _PhotoRow extends StatelessWidget {
  const _PhotoRow({required this.photoBytes, required this.isBusy, required this.onAdd, required this.onRemove});

  final Uint8List? photoBytes;
  final bool isBusy;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ClipOval(
              child: photoBytes != null
                  ? Image.memory(photoBytes!, width: 44, height: 44, fit: BoxFit.cover)
                  : Container(
                      width: 44,
                      height: 44,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.person_outline, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                photoBytes != null
                    ? 'Photo added — shown on templates that include one.'
                    : 'Add a photo (optional) — most global corporate CVs skip this; add one only if '
                        'your target market expects it.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(width: 8),
            if (isBusy)
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            else if (photoBytes != null)
              TextButton(key: const Key('removePhotoButton'), onPressed: onRemove, child: const Text('Remove'))
            else
              TextButton(key: const Key('addPhotoButton'), onPressed: onAdd, child: const Text('Add')),
          ],
        ),
      ),
    );
  }
}

/// A compact gallery cell — just the cropped preview and the template name,
/// small enough that several sit on screen together so an officer can
/// compare layouts at a glance. Tapping opens the full-page preview.
class _TemplateThumbnail extends StatelessWidget {
  const _TemplateThumbnail({required this.template, required this.onTap});

  final CvPdfTemplate template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('cvPdfTemplate_${template.id}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 745 / 600,
              child: Image.asset(template.previewAssetPath, fit: BoxFit.cover, alignment: Alignment.topCenter),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 3),
                decoration: BoxDecoration(color: template.swatch.flutter, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  template.name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The enlarged, full-page view of one template — opened by tapping its
/// gallery thumbnail. Shows the name prominently (the thumbnail grid alone
/// made it easy to lose track of which design was which) and carries its
/// own download action, so browsing and downloading are the same tap-through
/// flow instead of a separate button on every grid cell.
class _TemplatePreviewDialog extends StatefulWidget {
  const _TemplatePreviewDialog({required this.template, required this.canDownload, required this.onDownload});

  final CvPdfTemplate template;
  final bool canDownload;
  final Future<void> Function() onDownload;

  @override
  State<_TemplatePreviewDialog> createState() => _TemplatePreviewDialogState();
}

class _TemplatePreviewDialogState extends State<_TemplatePreviewDialog> {
  bool _isGenerating = false;

  Future<void> _handleDownload() async {
    setState(() => _isGenerating = true);
    try {
      await widget.onDownload();
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final template = widget.template;
    final screenSize = MediaQuery.sizeOf(context);
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 460,
          maxHeight: screenSize.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.asset(template.previewFullAssetPath, fit: BoxFit.fitWidth),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(color: template.swatch.flutter, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(template.name, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(template.blurb, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _isGenerating
                        ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                        : FilledButton.icon(
                            key: ValueKey('downloadCvTemplate_${template.id}'),
                            onPressed: widget.canDownload ? _handleDownload : null,
                            icon: const Icon(Icons.file_download_outlined),
                            label: const Text('Download'),
                          ),
                  ),
                ],
              ),
            ),
            if (!widget.canDownload)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Text(
                  'Build your CV first to unlock downloads.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
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
