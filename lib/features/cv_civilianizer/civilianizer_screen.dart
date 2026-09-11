import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/services/pdf_export.dart';
import '../../core/services/profile_repository.dart';
import '../../core/widgets/analysis_loading_indicator.dart';
import '../../core/widgets/home_button.dart';
import 'civilianized_cv.dart';
import 'civilianizer_service.dart';

class CivilianizerScreen extends StatefulWidget {
  const CivilianizerScreen({super.key, this.civilianizeCv = mockCivilianizeCv});

  /// Overridable for testing; defaults to sample data until the Worker's
  /// /civilianize-cv endpoint is wired in.
  final CvCivilianizer civilianizeCv;

  @override
  State<CivilianizerScreen> createState() => _CivilianizerScreenState();
}

class _CivilianizerScreenState extends State<CivilianizerScreen> {
  bool _isLoading = true;
  String? _error;
  CivilianizedCv? _result;

  @override
  void initState() {
    super.initState();
    final cached = context.read<ProfileRepository>().lastCivilianizedCv;
    if (cached != null) {
      _result = cached;
      _isLoading = false;
    } else {
      _generate();
    }
  }

  Future<void> _generate() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final profile = context.read<ProfileRepository>().profile;
    try {
      final result = await widget.civilianizeCv(
        cvText: profile?.cvExtractedText ?? profile?.cvFileName ?? '',
        cvPdfBytes: profile?.cvPdfBytes,
      );
      if (!mounted) return;
      context.read<ProfileRepository>().saveCivilianizedCv(result);
      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Base CV, Civilianized'),
        actions: [
          IconButton(
            key: const Key('regenerateCivilianizedCvButton'),
            icon: const Icon(Icons.refresh),
            tooltip: 'Regenerate',
            onPressed: _isLoading ? null : _generate,
          ),
          const HomeButton(),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: AnalysisLoadingIndicator(
          messages: [
            'Reading your CV...',
            'Reframing military language into civilian terms...',
            'Keeping every real detail, just rewritten...',
          ],
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }
    final result = _result!;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'A general-purpose civilian version of your CV — for before you have a '
          "specific job description. Reframes what's already there; nothing invented.",
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Civilianized CV', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(result.civilianizedCv, key: const Key('civilianizedCvText')),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('copyCivilianizedCvButton'),
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: result.civilianizedCv));
                          if (mounted) {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(const SnackBar(content: Text('CV copied to clipboard')));
                          }
                        },
                        icon: const Icon(Icons.copy_outlined),
                        label: const Text('Copy'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('downloadCivilianizedCvButton'),
                        onPressed: () => exportTextAsPdf(
                          title: 'Civilianized CV',
                          body: result.civilianizedCv,
                        ),
                        icon: const Icon(Icons.download_outlined),
                        label: const Text('Download PDF'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (result.translations.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Military-to-corporate translation', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'What changed, and why it reads as corporate experience rather than a military '
            'record.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          for (final translation in result.translations)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.close,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            translation.before,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check, size: 16, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(child: Text(translation.after)),
                      ],
                    ),
                    if (translation.skillTags.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final tag in translation.skillTags)
                            Chip(
                              label: Text(tag, style: Theme.of(context).textTheme.labelSmall),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: EdgeInsets.zero,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}
