import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/profile_repository.dart';
import 'ai_competency.dart';
import 'ai_readiness.dart';
import 'ai_readiness_result_screen.dart';
import 'ai_readiness_service.dart';

class AiReadinessQuizScreen extends StatefulWidget {
  const AiReadinessQuizScreen({
    super.key,
    this.analyzeAiReadiness = mockAnalyzeAiReadiness,
  });

  /// Overridable for testing; defaults to sample data until the Cloudflare
  /// Worker backend is wired in.
  final AiReadinessAnalyzer analyzeAiReadiness;

  @override
  State<AiReadinessQuizScreen> createState() => _AiReadinessQuizScreenState();
}

class _AiReadinessQuizScreenState extends State<AiReadinessQuizScreen> {
  final Map<AiDimension, int> _ratings = {
    for (final dimension in AiDimension.values) dimension: 3,
  };

  bool _isAnalyzing = false;

  Future<void> _submit() async {
    setState(() => _isAnalyzing = true);
    final assessment = AiSelfAssessment(ratings: Map.of(_ratings));
    final profile = context.read<ProfileRepository>().profile;
    try {
      final result = await widget.analyzeAiReadiness(
        assessment: assessment,
        cvFileName: profile?.cvFileName ?? 'uploaded CV',
        cvExtractedText: profile?.cvExtractedText,
        cvPdfBytes: profile?.cvPdfBytes,
        releaseDate: profile?.releaseDate,
      );
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AiReadinessResultScreen(result: result)),
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
    return Scaffold(
      appBar: AppBar(title: const Text('AI Readiness')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rate your comfort with AI', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Rate yourself 1 (not familiar) to 5 (very confident) on each area. '
              'Your score is calculated directly from these ratings.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            for (final dimension in AiDimension.values) _DimensionRating(
              dimension: dimension,
              value: _ratings[dimension]!,
              onChanged: (v) => setState(() => _ratings[dimension] = v),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('submitAssessmentButton'),
                onPressed: _isAnalyzing ? null : _submit,
                child: _isAnalyzing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('See my readiness roadmap'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DimensionRating extends StatelessWidget {
  const _DimensionRating({
    required this.dimension,
    required this.value,
    required this.onChanged,
  });

  final AiDimension dimension;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dimension.label, style: Theme.of(context).textTheme.titleMedium),
          Text(dimension.description, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            key: ValueKey('rating_${dimension.name}'),
            segments: const [
              ButtonSegment(value: 1, label: Text('1')),
              ButtonSegment(value: 2, label: Text('2')),
              ButtonSegment(value: 3, label: Text('3')),
              ButtonSegment(value: 4, label: Text('4')),
              ButtonSegment(value: 5, label: Text('5')),
            ],
            selected: {value},
            onSelectionChanged: (selection) => onChanged(selection.first),
          ),
        ],
      ),
    );
  }
}
