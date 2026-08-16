import 'package:flutter/material.dart';

import '../../core/services/file_picker_service.dart';

enum JdInputMethod { paste, upload }

Future<String?> _defaultPickJd() =>
    pickFileName(allowedExtensions: const ['pdf', 'doc', 'docx', 'txt']);

class JdMatchScreen extends StatefulWidget {
  const JdMatchScreen({super.key, this.pickFile = _defaultPickJd});

  /// Overridable for testing so the native file-picker channel never needs
  /// to be invoked.
  final FileNamePicker pickFile;

  @override
  State<JdMatchScreen> createState() => _JdMatchScreenState();
}

class _JdMatchScreenState extends State<JdMatchScreen> {
  final TextEditingController _jdTextController = TextEditingController();

  JdInputMethod _inputMethod = JdInputMethod.paste;
  String? _uploadedFileName;
  String? _error;
  String? _submittedSummary;

  @override
  void dispose() {
    _jdTextController.dispose();
    super.dispose();
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

  void _checkMatch() {
    if (_inputMethod == JdInputMethod.paste) {
      final text = _jdTextController.text.trim();
      if (text.isEmpty) {
        setState(() => _error = 'Paste a job description to continue');
        return;
      }
      setState(() {
        _error = null;
        _submittedSummary = text;
      });
    } else {
      if (_uploadedFileName == null) {
        setState(() => _error = 'Upload a job description to continue');
        return;
      }
      setState(() {
        _error = null;
        _submittedSummary = _uploadedFileName;
      });
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
            if (_inputMethod == JdInputMethod.paste)
              TextFormField(
                key: const Key('jdTextField'),
                controller: _jdTextController,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Job description',
                  alignLabelWithHint: true,
                ),
              )
            else
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
                onPressed: _checkMatch,
                child: const Text('Check match'),
              ),
            ),
            if (_submittedSummary != null) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Received', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        _submittedSummary!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Match scoring and keyword-gap analysis are coming in a future '
                        "release — this build only captures what you've provided.",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
