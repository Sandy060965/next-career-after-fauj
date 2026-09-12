import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../core/services/pdf_export.dart';
import '../../core/widgets/home_button.dart';
import '../cv_templates/cv_pdf_fonts.dart';
import '../cv_templates/cv_template_registry.dart';
import 'cv_example.dart';
import 'cv_examples_data.dart';

/// Browse the 54-sample CV reference library by Service, Rank, and career
/// track, rendered through the same 20 template designs used for an
/// officer's own CV — so an example looks exactly like what a built CV
/// would look like. Every entry is a fictional composite (see cv_example.dart)
/// and is never presented as real data.
class CvExamplesScreen extends StatefulWidget {
  const CvExamplesScreen({super.key, this.loadFonts = CvPdfFonts.load, this.onDeliverPdf = deliverPdfBytes});

  /// Overridable for testing so bundled font assets don't need loading.
  final Future<CvPdfFonts> Function() loadFonts;

  /// Overridable for testing so the platform share/download path is never
  /// actually invoked in a test run.
  final Future<void> Function(Uint8List bytes, String fileName) onDeliverPdf;

  @override
  State<CvExamplesScreen> createState() => _CvExamplesScreenState();
}

class _CvExamplesScreenState extends State<CvExamplesScreen> {
  String? _service;
  String? _rank;
  CvExampleArchetype? _archetype;

  /// Defaults to the matched example's own assigned template, but the
  /// officer can switch to see the same sample content in a different
  /// design — reusing the exact template gallery already built for CV
  /// Writing Guide.
  String? _templateId;

  List<String> get _services => kCvExamples.map((e) => e.serviceLabel).toSet().toList();

  List<String> get _ranksForService {
    if (_service == null) return const [];
    final ranks = <String>[];
    for (final e in kCvExamples) {
      if (e.serviceLabel == _service && !ranks.contains(e.rank)) ranks.add(e.rank);
    }
    return ranks;
  }

  CvExample? get _match {
    if (_service == null || _rank == null || _archetype == null) return null;
    for (final e in kCvExamples) {
      if (e.serviceLabel == _service && e.rank == _rank && e.archetype == _archetype) return e;
    }
    return null;
  }

  Future<void> _download(CvExample example, CvPdfTemplate template) async {
    try {
      final fonts = await widget.loadFonts();
      final bytes = await template.build(example.data, fonts).save();
      final safeName = '${example.serviceLabel}_${example.rank}_${template.name}'
          .replaceAll(RegExp(r'[^A-Za-z0-9 _-]'), '')
          .trim();
      await widget.onDeliverPdf(bytes, 'CV_Example_$safeName.pdf');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text("Couldn't generate this example: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final match = _match;
    final template = match == null
        ? null
        : kCvPdfTemplates.firstWhere((t) => t.id == (_templateId ?? match.templateId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sample CV Library'),
        actions: const [HomeButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            '54 fictional composite CVs — one for every Service, rank tier, and career '
            'track — to show how a professional CV writer would phrase a CV like yours. '
            'Rendered through the same designs as your own CV templates.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            key: const Key('cvExampleServiceDropdown'),
            initialValue: _service,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Service'),
            items: [
              for (final s in _services) DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (v) => setState(() {
              _service = v;
              _rank = null;
              _templateId = null;
            }),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: const Key('cvExampleRankDropdown'),
            initialValue: _rank,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Rank'),
            items: [
              for (final r in _ranksForService) DropdownMenuItem(value: r, child: Text(r, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: _service == null
                ? null
                : (v) => setState(() {
                      _rank = v;
                      _templateId = null;
                    }),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<CvExampleArchetype>(
            key: const Key('cvExampleArchetypeDropdown'),
            initialValue: _archetype,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Career track'),
            items: [
              for (final a in CvExampleArchetype.values)
                DropdownMenuItem(value: a, child: Text(a.label, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (v) => setState(() {
              _archetype = v;
              _templateId = null;
            }),
          ),
          if (match != null && template != null) ...[
            const SizedBox(height: 20),
            Card(
              key: const Key('cvExampleFictionalNotice'),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Fictional composite — for reference only. Replace every bracketed '
                  'placeholder with your own real, verified details.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: const Key('cvExampleTemplateDropdown'),
              initialValue: template.id,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Design'),
              items: [
                for (final t in kCvPdfTemplates)
                  DropdownMenuItem(value: t.id, child: Text(t.name, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) => setState(() => _templateId = v),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 700,
              child: PdfPreview(
                key: ValueKey('cvExamplePreview_${match.serviceLabel}_${match.rank}_${match.archetype}_${template.id}'),
                useActions: false,
                canChangePageFormat: false,
                canChangeOrientation: false,
                canDebug: false,
                build: (format) async {
                  final fonts = await widget.loadFonts();
                  return template.build(match.data, fonts).save();
                },
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('cvExampleDownloadButton'),
              onPressed: () => _download(match, template),
              icon: const Icon(Icons.file_download_outlined),
              label: const Text('Download this example'),
            ),
          ],
        ],
      ),
    );
  }
}
