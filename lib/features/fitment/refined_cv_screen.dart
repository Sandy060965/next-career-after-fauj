import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'fitment_result.dart';

enum CvView { original, refined }

class RefinedCvScreen extends StatefulWidget {
  const RefinedCvScreen({super.key, required this.result, this.originalCvText});

  final FitmentResult result;

  /// The officer's actual, complete extracted CV text (client-side, never
  /// touched by the LLM). Preferred over [FitmentResult.originalCvExcerpt]
  /// (a short, model-generated excerpt) whenever available — null only for
  /// PDF CVs, where no local text extraction happens.
  final String? originalCvText;

  @override
  State<RefinedCvScreen> createState() => _RefinedCvScreenState();
}

class _RefinedCvScreenState extends State<RefinedCvScreen> {
  CvView _view = CvView.refined;

  @override
  Widget build(BuildContext context) {
    final originalText = widget.originalCvText ?? widget.result.originalCvExcerpt;
    final text = _view == CvView.original ? originalText : widget.result.refinedCv;

    return Scaffold(
      appBar: AppBar(title: const Text('Refined CV')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Only reframes what your original CV already says — nothing is invented.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<CvView>(
              key: const Key('cvViewToggle'),
              segments: const [
                ButtonSegment(value: CvView.original, label: Text('Original')),
                ButtonSegment(value: CvView.refined, label: Text('Refined')),
              ],
              selected: {_view},
              onSelectionChanged: (selection) => setState(() => _view = selection.first),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Text(text, key: const Key('cvText')),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const Key('copyCvButton'),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: widget.result.refinedCv));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        const SnackBar(content: Text('Refined CV copied to clipboard')),
                      );
                  }
                },
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Copy refined CV'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
