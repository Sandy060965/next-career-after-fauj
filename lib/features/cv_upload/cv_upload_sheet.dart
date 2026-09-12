import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/document_text_extractor.dart';
import '../../core/services/file_picker_service.dart';
import '../../core/services/profile_repository.dart';
import '../../core/utils/privacy_copy.dart';

Future<PickedFile?> _defaultPickCv() =>
    pickFileWithBytes(allowedExtensions: const ['pdf', 'docx']);

/// Opens a bottom sheet letting an officer who already has a saved profile
/// attach or replace their CV directly — the same pick/size-guard/DOCX-
/// extraction logic onboarding uses, without re-entering the full
/// onboarding wizard. Returns true once a CV has been saved.
Future<bool> showCvUploadSheet(
  BuildContext context, {
  Future<PickedFile?> Function() pickFile = _defaultPickCv,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => CvUploadSheet(pickFile: pickFile),
  );
  return result ?? false;
}

class CvUploadSheet extends StatefulWidget {
  const CvUploadSheet({super.key, this.pickFile = _defaultPickCv});

  /// Overridable for testing so the native file-picker channel never needs
  /// to be invoked.
  final Future<PickedFile?> Function() pickFile;

  @override
  State<CvUploadSheet> createState() => _CvUploadSheetState();
}

class _CvUploadSheetState extends State<CvUploadSheet> {
  String? _uploadedFileName;
  String? _cvExtractedText;
  Uint8List? _cvPdfBytes;
  String? _error;
  bool _isProcessing = false;
  bool _isSaving = false;

  Future<void> _pickCv() async {
    final file = await widget.pickFile();
    if (file == null) return;

    final extension = file.name.split('.').last.toLowerCase();
    setState(() {
      _uploadedFileName = file.name;
      _error = null;
      _cvExtractedText = null;
      _cvPdfBytes = null;
    });

    if (extension == 'pdf') {
      // Mirrors onboarding_screen.dart's guard — a very large PDF can take
      // long enough to base64-encode client-side that later analysis looks
      // permanently stuck rather than just slow.
      if (file.bytes.lengthInBytes > kMaxUploadPdfBytes) {
        setState(() {
          _uploadedFileName = null;
          _error = 'This PDF is larger than $kMaxUploadPdfMb MB, which can make analysis '
              'hang. Try a smaller/compressed PDF, or a Word (.docx) version instead.';
        });
        return;
      }
      // Claude reads PDFs natively — no client-side extraction needed.
      setState(() => _cvPdfBytes = file.bytes);
      return;
    }

    if (extension == 'docx') {
      setState(() => _isProcessing = true);
      try {
        final text = await extractDocxText(file.bytes);
        if (!mounted) return;

        setState(() {
          _cvExtractedText = text;
          _isProcessing = false;
        });
      } on DocxExtractionException catch (e) {
        if (!mounted) return;
        setState(() {
          _isProcessing = false;
          _error = "Couldn't read this file's text ($e). The filename is saved, "
              'but try a different file for a full analysis.';
        });
      }
    }
  }

  Future<void> _save() async {
    final fileName = _uploadedFileName;
    if (fileName == null) {
      setState(() => _error = 'Choose a file to continue');
      return;
    }
    final repo = context.read<ProfileRepository>();
    final current = repo.profile;
    if (current == null) return;

    setState(() => _isSaving = true);
    await repo.saveProfile(
      current.withUpdatedCv(
        cvFileName: fileName,
        cvExtractedText: _cvExtractedText,
        cvPdfBytes: _cvPdfBytes,
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('Upload your CV', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            kCvSourceDisclaimer,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.description_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _uploadedFileName ?? 'No file selected (PDF or Word)',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_isProcessing)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  TextButton(
                    key: const Key('cvUploadSheetBrowseButton'),
                    onPressed: _pickCv,
                    child: const Text('Browse'),
                  ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, style: TextStyle(color: colorScheme.error, fontSize: 12)),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const Key('cvUploadSheetSaveButton'),
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save CV'),
            ),
          ),
        ],
      ),
    );
  }
}
