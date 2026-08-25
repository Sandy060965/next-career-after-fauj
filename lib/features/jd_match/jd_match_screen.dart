import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/services/document_text_extractor.dart';
import '../../core/services/file_picker_service.dart';
import '../../core/services/profile_repository.dart';
import '../fitment/fitment_service.dart';
import '../fitment/score_gap_screen.dart';

enum JdInputMethod { paste, upload }

// PDF is deliberately not offered here: unlike the CV upload (where Claude
// reads PDF bytes natively), every backend endpoint that consumes a JD
// expects plain text, and there's no client-side PDF text extraction in
// this app. Offering PDF upload without either would silently send just a
// filename as if it were the JD — exactly the bug this fixed. A PDF-sourced
// JD should go through Paste instead.
Future<PickedFile?> _defaultPickJd() => pickFileWithBytes(allowedExtensions: const ['docx', 'txt']);

class JdMatchScreen extends StatefulWidget {
  const JdMatchScreen({
    super.key,
    this.pickFile = _defaultPickJd,
    this.analyzeFitment = mockAnalyzeFitment,
  });

  /// Overridable for testing so the native file-picker channel never needs
  /// to be invoked.
  final Future<PickedFile?> Function() pickFile;

  /// Overridable for testing; defaults to sample data until the Cloudflare
  /// Worker backend is wired in.
  final FitmentAnalyzer analyzeFitment;

  @override
  State<JdMatchScreen> createState() => _JdMatchScreenState();
}

class _JdMatchScreenState extends State<JdMatchScreen> {
  final TextEditingController _jdTextController = TextEditingController();

  JdInputMethod _inputMethod = JdInputMethod.paste;
  String? _uploadedFileName;
  String? _uploadedJdText;
  bool _isProcessingUpload = false;
  String? _error;
  bool _isAnalyzing = false;

  @override
  void dispose() {
    _jdTextController.dispose();
    super.dispose();
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
    final file = await widget.pickFile();
    if (file == null) return;

    setState(() {
      _uploadedFileName = file.name;
      _uploadedJdText = null;
      _error = null;
    });

    final extension = file.name.split('.').last.toLowerCase();
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
    if (_inputMethod == JdInputMethod.paste) {
      final text = _jdTextController.text.trim();
      if (text.isEmpty) {
        setState(() => _error = 'Paste a job description to continue');
        return;
      }
      jdSource = text;
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

    final profile = context.read<ProfileRepository>().profile;
    try {
      final result = await widget.analyzeFitment(
        jdText: jdSource,
        cvFileName: profile?.cvFileName ?? 'uploaded CV',
        cvExtractedText: profile?.cvExtractedText,
        cvPdfBytes: profile?.cvPdfBytes,
      );
      if (!mounted) return;
      context.read<ProfileRepository>().saveFitmentResult(result, jdText: jdSource);
      setState(() => _isAnalyzing = false);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ScoreGapScreen(result: result, originalCvText: profile?.cvExtractedText),
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
    return Scaffold(
      appBar: AppBar(title: const Text('JD Match')),
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
                        title: Text(
                          method == JdInputMethod.paste
                              ? 'Paste job description'
                              : 'Upload job description',
                        ),
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
            ] else
              _buildUploadPanel(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: colorScheme.error, fontSize: 12),
                ),
              ),
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
        ),
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
                  _uploadedFileName ?? 'No file selected (DOCX or TXT)',
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
        const SizedBox(height: 4),
        Text(
          'Have a PDF job posting? Copy its text and use Paste instead.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
