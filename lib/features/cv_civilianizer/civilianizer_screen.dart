import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/services/profile_repository.dart';
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
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
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
                SizedBox(
                  width: double.infinity,
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
              ],
            ),
          ),
        ),
        if (result.translationNotes.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('What changed', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final note in result.translationNotes)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('•  $note'),
            ),
        ],
      ],
    );
  }
}
