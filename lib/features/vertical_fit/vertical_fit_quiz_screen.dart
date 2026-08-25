import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/profile_repository.dart';
import 'aptitude_question.dart';
import 'vertical_fit.dart';
import 'vertical_fit_result_screen.dart';

class VerticalFitQuizScreen extends StatefulWidget {
  const VerticalFitQuizScreen({super.key});

  @override
  State<VerticalFitQuizScreen> createState() => _VerticalFitQuizScreenState();
}

class _VerticalFitQuizScreenState extends State<VerticalFitQuizScreen> {
  final Map<String, int> _ratings = {
    for (final q in kAptitudeQuestions) q.id: 3,
  };

  void _submit() {
    final assessment = VerticalFitAssessment(ratings: Map.of(_ratings));
    final repo = context.read<ProfileRepository>();
    repo.saveVerticalFitAssessment(assessment);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VerticalFitResultScreen(
          assessment: assessment,
          corpsOrArm: repo.profile?.corpsOrArm,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Career Vertical Fit')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Which corporate verticals suit you?', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Rate how much each statement sounds like you, 1 (strongly disagree) to 5 '
              '(strongly agree). This is for your guidance only — never shared, and never '
              'part of any service record.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            for (final group in DimensionGroup.values) ...[
              Text(group.label, style: Theme.of(context).textTheme.headlineSmall),
              Text(group.description, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              for (final dimension in AptitudeDimension.values.where((d) => d.group == group)) ...[
                Text(dimension.label, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final question in kAptitudeQuestions.where((q) => q.dimension == dimension))
                  _StatementRating(
                    key: ValueKey(question.id),
                    question: question,
                    value: _ratings[question.id]!,
                    onChanged: (v) => setState(() => _ratings[question.id] = v),
                  ),
                const SizedBox(height: 12),
              ],
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('submitVerticalFitButton'),
                onPressed: _submit,
                child: const Text('See my top verticals'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatementRating extends StatelessWidget {
  const _StatementRating({super.key, required this.question, required this.value, required this.onChanged});

  final AptitudeQuestion question;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question.statement, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          SegmentedButton<int>(
            key: ValueKey('rating_${question.id}'),
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
