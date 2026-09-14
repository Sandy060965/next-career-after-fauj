import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/routing/app_routes.dart';
import '../../core/services/document_text_extractor.dart';
import '../../core/services/file_picker_service.dart';
import '../../core/services/pdf_export.dart';
import '../../core/services/profile_repository.dart';
import '../../core/widgets/analysis_loading_indicator.dart';
import '../../core/widgets/home_button.dart';
import '../career_paths/career_vertical.dart';
import '../career_paths/corps_affinity.dart';
import '../cv_upload/cv_upload_sheet.dart';
import '../fitment/fitment_service.dart';
import '../fitment/score_gap_screen.dart';
import '../vertical_fit/vertical_fit.dart';
import 'sample_jd_service.dart';

enum JdInputMethod { paste, upload, generate }

// PDF is included alongside DOCX/TXT: Claude reads PDF bytes natively (same
// as the CV upload), so no client-side extraction is needed for it — see
// _pickJdFile.
Future<PickedFile?> _defaultPickJd() =>
    pickFileWithBytes(allowedExtensions: const ['pdf', 'docx', 'txt']);

class JdMatchScreen extends StatefulWidget {
  const JdMatchScreen({
    super.key,
    this.pickFile = _defaultPickJd,
    this.analyzeFitment = mockAnalyzeFitment,
    this.generateSampleJd = mockGenerateSampleJd,
  });

  /// Overridable for testing so the native file-picker channel never needs
  /// to be invoked.
  final Future<PickedFile?> Function() pickFile;

  /// Overridable for testing; defaults to sample data until the Cloudflare
  /// Worker backend is wired in.
  final FitmentAnalyzer analyzeFitment;

  /// Overridable for testing; defaults to sample data until the Cloudflare
  /// Worker backend is wired in.
  final SampleJdGenerator generateSampleJd;

  @override
  State<JdMatchScreen> createState() => _JdMatchScreenState();
}

class _JdMatchScreenState extends State<JdMatchScreen> {
  final TextEditingController _jdTextController = TextEditingController();

  JdInputMethod _inputMethod = JdInputMethod.paste;
  String? _uploadedFileName;
  String? _uploadedJdText;
  Uint8List? _uploadedJdPdfBytes;
  bool _isProcessingUpload = false;
  String? _error;
  bool _isAnalyzing = false;

  late List<VerticalFit> _matchedVerticals;
  CareerVertical? _selectedVertical;
  String? _generatedJd;
  bool _isGeneratingJd = false;
  String? _generateError;

  @override
  void initState() {
    super.initState();
    final repo = context.read<ProfileRepository>();
    final universe = effectiveVerticalUniverse(repo.profile?.corpsOrArm);
    final assessment = repo.lastVerticalFitAssessment;
    _matchedVerticals = assessment == null
        ? [for (final v in universe) VerticalFit(vertical: v, fitScore: 0)]
        : rankVerticalFit(assessment.dimensionScores, universe: universe).take(6).toList();
  }

  @override
  void dispose() {
    _jdTextController.dispose();
    super.dispose();
  }

  String _tierFor(CareerVertical vertical) {
    final years = context.read<ProfileRepository>().profile?.workExperienceYears ?? 10;
    return vertical.levelForExperience(years).title;
  }

  Future<void> _generateJd() async {
    final vertical = _selectedVertical;
    if (vertical == null) {
      setState(() => _generateError = 'Pick a vertical to continue');
      return;
    }
    setState(() {
      _isGeneratingJd = true;
      _generateError = null;
    });
    try {
      final jd = await widget.generateSampleJd(vertical: vertical.name, tier: _tierFor(vertical));
      if (!mounted) return;
      setState(() {
        _generatedJd = jd;
        _isGeneratingJd = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGeneratingJd = false;
        _generateError = '$e';
      });
    }
  }

  void _useGeneratedJd() {
    final generated = _generatedJd;
    if (generated == null) return;
    setState(() {
      _jdTextController.text = generated;
      _inputMethod = JdInputMethod.paste;
      _error = null;
    });
  }

  Future<void> _copyGeneratedJd() async {
    await Clipboard.setData(ClipboardData(text: _generatedJd ?? ''));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('JD copied to clipboard')));
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Clipboard is empty')));
      return;
    }
    setState(() {
      _jdTextController.text = text;
      _error = null;
    });
  }

  Future<void> _pickJdFile() async {
    final PickedFile? picked;
    try {
      picked = await widget.pickFile();
    } on UnsupportedFileTypeException catch (e) {
      setState(() => _error = e.message);
      return;
    }
    if (picked == null) return;
    final file = picked;

    setState(() {
      _uploadedFileName = file.name;
      _uploadedJdText = null;
      _uploadedJdPdfBytes = null;
      _error = null;
    });

    final extension = file.name.split('.').last.toLowerCase();
    if (extension == 'pdf') {
      // A very large PDF can take long enough to base64-encode client-side
      // before the request that "Check match" looks permanently stuck
      // rather than just slow — reject it up front with a clear reason.
      if (file.bytes.lengthInBytes > kMaxUploadPdfBytes) {
        setState(() {
          _uploadedFileName = null;
          _error = 'This PDF is larger than $kMaxUploadPdfMb MB, which can make analysis '
              'hang. Try a smaller/compressed PDF, or paste the text instead.';
        });
        return;
      }
      // Claude reads PDFs natively — no client-side extraction needed.
      setState(() => _uploadedJdPdfBytes = file.bytes);
      return;
    }
    if (extension == 'txt') {
      setState(() => _uploadedJdText = utf8.decode(file.bytes, allowMalformed: true));
      return;
    }

    setState(() => _isProcessingUpload = true);
    try {
      final text = await extractDocxText(file.bytes);
      if (!mounted) return;
      setState(() {
        _uploadedJdText = text;
        _isProcessingUpload = false;
      });
    } on DocxExtractionException catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessingUpload = false;
        _error = "Couldn't read this file's text ($e). Try a different file, or use Paste instead.";
      });
    }
  }

  Future<void> _checkMatch() async {
    final String jdSource;
    Uint8List? jdPdfBytes;
    if (_inputMethod == JdInputMethod.paste) {
      final text = _jdTextController.text.trim();
      if (text.isEmpty) {
        setState(() => _error = 'Paste a job description to continue');
        return;
      }
      jdSource = text;
    } else if (_uploadedJdPdfBytes != null) {
      // Claude reads the PDF natively — jdSource is just the filename,
      // sent alongside so the backend has something to fall back to if
      // the bytes were somehow dropped, mirroring how a CV PDF works.
      jdSource = _uploadedFileName!;
      jdPdfBytes = _uploadedJdPdfBytes;
    } else {
      if (_uploadedJdText == null) {
        setState(
          () => _error = _uploadedFileName == null
              ? 'Upload a job description to continue'
              : "This file's text couldn't be read — try a different file, or use Paste instead.",
        );
        return;
      }
      jdSource = _uploadedJdText!;
    }

    setState(() {
      _error = null;
      _isAnalyzing = true;
    });

    final repo = context.read<ProfileRepository>();
    final profile = repo.profile;
    // Prefer a civilian-ready CV the officer has already produced (Base CV
    // Civilianized or Build My Civilian CV, whichever is more recent) over
    // the raw military-language CV from onboarding — matching it against
    // the JD is more useful once it's actually written in civilian terms.
    // That also means sending plain text rather than the original PDF
    // bytes, since both civilian-CV sources are text-only outputs.
    final preferredCv = repo.preferredCivilianCvText;
    final effectiveCvText = preferredCv ?? profile?.cvExtractedText;
    final effectiveCvPdfBytes = preferredCv == null ? profile?.cvPdfBytes : null;
    try {
      final result = await widget.analyzeFitment(
        jdText: jdSource,
        jdPdfBytes: jdPdfBytes,
        cvFileName: profile?.cvFileName ?? 'uploaded CV',
        cvExtractedText: effectiveCvText,
        cvPdfBytes: effectiveCvPdfBytes,
      );
      if (!mounted) return;
      await repo.saveFitmentResult(
        result,
        jdText: jdPdfBytes == null ? jdSource : null,
        jdPdfBytes: jdPdfBytes,
      );
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ScoreGapScreen(result: result, originalCvText: effectiveCvText),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final repo = context.watch<ProfileRepository>();
    final profile = repo.profile;
    final hasCv = repo.preferredCivilianCvText != null ||
        (profile?.cvExtractedText?.isNotEmpty ?? false) ||
        profile?.cvPdfBytes != null;
    return Scaffold(
      appBar: AppBar(title: const Text('JD Match'), actions: const [HomeButton()]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Check a job description', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Paste the job description text, or upload it as a file.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (!hasCv) ...[
              const SizedBox(height: 12),
              _buildNoCvBanner(context, colorScheme),
            ],
            const SizedBox(height: 20),
            RadioGroup<JdInputMethod>(
              groupValue: _inputMethod,
              onChanged: (v) => setState(() {
                _inputMethod = v!;
                _error = null;
              }),
              child: Column(
                children: JdInputMethod.values
                    .map(
                      (method) => RadioListTile<JdInputMethod>(
                        key: ValueKey('jdInput_${method.name}'),
                        value: method,
                        contentPadding: EdgeInsets.zero,
                        title: Text(switch (method) {
                          JdInputMethod.paste => 'Paste job description',
                          JdInputMethod.upload => 'Upload job description',
                          JdInputMethod.generate => 'Generate a JD with AI',
                        }),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
            if (_inputMethod == JdInputMethod.paste) ...[
              TextFormField(
                key: const Key('jdTextField'),
                controller: _jdTextController,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Job description',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('jdPasteButton'),
                  onPressed: _pasteFromClipboard,
                  icon: const Icon(Icons.content_paste_go_outlined),
                  label: const Text('Paste from clipboard'),
                ),
              ),
            ] else if (_inputMethod == JdInputMethod.upload)
              _buildUploadPanel()
            else
              _buildGeneratePanel(colorScheme),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: colorScheme.error, fontSize: 12),
                ),
              ),
            if (_inputMethod != JdInputMethod.generate) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('checkMatchButton'),
                  onPressed: _isAnalyzing ? null : _checkMatch,
                  child: _isAnalyzing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Check match'),
                ),
              ),
            ],
            if (_isAnalyzing) ...[
              const SizedBox(height: 16),
              const Center(
                child: AnalysisLoadingIndicator(
                  messages: [
                    'Reading your CV and this job description...',
                    'Mapping your experience to its requirements...',
                    'Identifying where you already meet the bar...',
                    'Working out the gaps worth closing...',
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoCvBanner(BuildContext context, ColorScheme colorScheme) {
    return Container(
      key: const Key('jdMatchNoCvBanner'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 20, color: colorScheme.onTertiaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "You haven't added a CV yet — the match will run without it, so the result "
                  "won't be grounded in your real experience.",
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: colorScheme.onTertiaryContainer),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('jdMatchAddCvButton'),
                  onPressed: () => showCvUploadSheet(context),
                  child: const Text('Add CV'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  key: const Key('jdMatchBuildCvButton'),
                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.cvBuilder),
                  child: const Text('Build CV'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.description_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _uploadedFileName ?? 'No file selected (PDF, DOCX, or TXT)',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_isProcessingUpload)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              TextButton(
                key: const Key('jdBrowseButton'),
                onPressed: _isProcessingUpload ? null : _pickJdFile,
                child: const Text('Browse'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGeneratePanel(ColorScheme colorScheme) {
    final generated = _generatedJd;
    if (generated == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Don't have a JD yet? Pick one of your matched verticals and we'll draft a "
            'representative one for that role level.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<CareerVertical>(
            key: const Key('generateVerticalDropdown'),
            initialValue: _selectedVertical,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Vertical'),
            items: [
              for (final fit in _matchedVerticals)
                DropdownMenuItem(
                  value: fit.vertical,
                  child: Text('${fit.vertical.name} — ${_tierFor(fit.vertical)}'),
                ),
            ],
            onChanged: (v) => setState(() {
              _selectedVertical = v;
              _generateError = null;
            }),
          ),
          if (_generateError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _generateError!,
                style: TextStyle(color: colorScheme.error, fontSize: 12),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const Key('generateJdButton'),
              onPressed: _isGeneratingJd ? null : _generateJd,
              child: _isGeneratingJd
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Generate'),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          key: const Key('generatedJdContainer'),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(generated),
        ),
        const SizedBox(height: 8),
        Text(
          'Happy with this? Use it to check your match now — or download/copy it for '
          'later first.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const Key('useGeneratedJdButton'),
            onPressed: _useGeneratedJd,
            child: const Text('Use this JD'),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('copyGeneratedJdButton'),
                onPressed: _copyGeneratedJd,
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Copy'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('downloadGeneratedJdButton'),
                onPressed: () => exportTextAsPdf(
                  title: 'Sample JD - ${_selectedVertical?.name ?? ''}',
                  body: generated,
                ),
                icon: const Icon(Icons.download_outlined),
                label: const Text('Download PDF'),
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const Key('generateAnotherJdButton'),
            onPressed: () => setState(() {
              _generatedJd = null;
              _selectedVertical = null;
            }),
            child: const Text('Pick a different vertical'),
          ),
        ),
      ],
    );
  }
}
