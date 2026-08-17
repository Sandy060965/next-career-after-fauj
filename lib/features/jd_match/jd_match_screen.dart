import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/services/file_picker_service.dart';
import '../../core/services/profile_repository.dart';
import '../fitment/fitment_service.dart';
import '../fitment/score_gap_screen.dart';

enum JdInputMethod { paste, upload }

Future<String?> _defaultPickJd() =>
    pickFileName(allowedExtensions: const ['pdf', 'doc', 'docx', 'txt']);

class JdMatchScreen extends StatefulWidget {
  const JdMatchScreen({
    super.key,
    this.pickFile = _defaultPickJd,
    this.analyzeFitment = mockAnalyzeFitment,
  });

  /// Overridable for testing so the native file-picker channel never needs
  /// to be invoked.
  final FileNamePicker pickFile;

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
    final fileName = await widget.pickFile();
    if (fileName != null) {
      setState(() {
        _uploadedFileName = fileName;
        _error = null;
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
      if (_uploadedFileName == null) {
        setState(() => _error = 'Upload a job description to continue');
        return;
      }
      jdSource = _uploadedFileName!;
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
    return Container(
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
              _uploadedFileName ?? 'No file selected',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            key: const Key('jdBrowseButton'),
            onPressed: _pickJdFile,
            child: const Text('Browse'),
          ),
        ],
      ),
    );
  }
}
