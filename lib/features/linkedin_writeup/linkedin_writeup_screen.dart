import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/services/profile_repository.dart';
import 'linkedin_writeup.dart';
import 'linkedin_writeup_service.dart';

class LinkedInWriteupScreen extends StatefulWidget {
  const LinkedInWriteupScreen({super.key, this.generateWriteup = mockGenerateLinkedInWriteup});

  /// Overridable for testing; defaults to sample data until the Worker's
  /// /linkedin-writeup endpoint is wired in.
  final LinkedInWriteupAnalyzer generateWriteup;

  @override
  State<LinkedInWriteupScreen> createState() => _LinkedInWriteupScreenState();
}

class _LinkedInWriteupScreenState extends State<LinkedInWriteupScreen> {
  bool _isLoading = true;
  String? _error;
  LinkedInWriteup? _writeup;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    final profile = context.read<ProfileRepository>().profile;
    try {
      final result = await widget.generateWriteup(
        cvText: profile?.cvExtractedText ?? profile?.cvFileName ?? '',
        cvPdfBytes: profile?.cvPdfBytes,
      );
      if (!mounted) return;
      setState(() {
        _writeup = result;
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
      appBar: AppBar(title: const Text('LinkedIn Write-up')),
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
    final writeup = _writeup!;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          "Reframes what's already in your CV — nothing invented.",
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 20),
        _WriteupSection(
          sectionKey: 'headline',
          title: 'Headline',
          content: writeup.headline,
        ),
        const SizedBox(height: 20),
        _WriteupSection(
          sectionKey: 'aboutSection',
          title: 'About section',
          content: writeup.aboutSection,
        ),
        const SizedBox(height: 20),
        _WriteupSection(
          sectionKey: 'announcementPost',
          title: 'Announcement post',
          content: writeup.announcementPost,
        ),
      ],
    );
  }
}

class _WriteupSection extends StatelessWidget {
  const _WriteupSection({
    required this.sectionKey,
    required this.title,
    required this.content,
  });

  final String sectionKey;
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(content, key: Key('${sectionKey}Text')),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: Key('${sectionKey}CopyButton'),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: content));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text('$title copied to clipboard')));
                  }
                },
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Copy'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
