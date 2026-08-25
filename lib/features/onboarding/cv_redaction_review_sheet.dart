import 'package:flutter/material.dart';

import '../../core/services/cv_redaction_scanner.dart';

/// Shown after .docx text extraction when [scanForRedactions] found
/// something. Returns the (possibly redacted) text if the officer hits
/// Continue, or null if they cancel — the caller should treat null as
/// "discard this upload," not "keep the original text unreviewed."
Future<String?> showCvRedactionReview(
  BuildContext context, {
  required String extractedText,
  required List<RedactionMatch> matches,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CvRedactionReviewDialog(extractedText: extractedText, matches: matches),
  );
}

class _CvRedactionReviewDialog extends StatefulWidget {
  const _CvRedactionReviewDialog({required this.extractedText, required this.matches});

  final String extractedText;
  final List<RedactionMatch> matches;

  @override
  State<_CvRedactionReviewDialog> createState() => _CvRedactionReviewDialogState();
}

class _CvRedactionReviewDialogState extends State<_CvRedactionReviewDialog> {
  late Set<String> _checked;

  @override
  void initState() {
    super.initState();
    // Default to redacting everything flagged — the officer opts out per
    // item, rather than opting in, since the safer default matters more
    // here than convenience.
    _checked = widget.matches.map((m) => m.text).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Review before continuing'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We found text that looks like personal or unit-identifying information. '
              "Checked items will be replaced with [REDACTED] — uncheck anything that's "
              'actually fine to keep.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.matches.length,
                itemBuilder: (context, i) {
                  final m = widget.matches[i];
                  return CheckboxListTile(
                    key: ValueKey('redactionCheckbox_${m.text}'),
                    value: _checked.contains(m.text),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (v) => setState(() {
                      if (v == true) {
                        _checked.add(m.text);
                      } else {
                        _checked.remove(m.text);
                      }
                    }),
                    title: Text('${m.category.label}: "${m.text}"'),
                    subtitle: Text(
                      m.count > 1 ? '${m.count} occurrences — "…${m.context}…"' : '"…${m.context}…"',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('cancelRedactionReviewButton'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Choose a different file'),
        ),
        ElevatedButton(
          key: const Key('confirmRedactionReviewButton'),
          onPressed: () =>
              Navigator.of(context).pop(applyRedactions(widget.extractedText, _checked)),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
