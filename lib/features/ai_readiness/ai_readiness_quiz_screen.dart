import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/profile_repository.dart';
import '../../core/widgets/home_button.dart';
import 'ai_readiness.dart';
import 'ai_readiness_result_screen.dart';
import 'ai_readiness_scenario.dart';
import 'ai_readiness_service.dart';

class AiReadinessQuizScreen extends StatefulWidget {
  const AiReadinessQuizScreen({
    super.key,
    this.analyzeAiReadiness = mockAnalyzeAiReadiness,
    this.questionsOverride,
  });

  /// Overridable for testing; defaults to sample data until the Cloudflare
  /// Worker backend is wired in.
  final AiReadinessAnalyzer analyzeAiReadiness;

  /// Overridable for testing, so a test can assert against a known,
  /// reproducible question set instead of a random per-attempt sample.
  final List<ScenarioQuestion>? questionsOverride;

  @override
  State<AiReadinessQuizScreen> createState() => _AiReadinessQuizScreenState();
}

class _AiReadinessQuizScreenState extends State<AiReadinessQuizScreen> {
  late final List<ScenarioQuestion> _questions =
      widget.questionsOverride ?? sampleAiReadinessQuestions();
  final Map<String, dynamic> _answers = {};
  bool _isAnalyzing = false;

  bool _isAnswered(ScenarioQuestion q) {
    final answer = _answers[q.id];
    if (q.type == QuestionType.multipleChoice) return answer is int;
    return answer is String && answer.trim().isNotEmpty;
  }

  Future<void> _submit() async {
    if (_questions.any((q) => !_isAnswered(q))) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Answer every question to see your results')));
      return;
    }

    setState(() => _isAnalyzing = true);
    final answersSnapshot = Map<String, dynamic>.of(_answers);
    final assessment = AiScenarioAssessment(questions: _questions, answers: answersSnapshot);
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
      context.read<ProfileRepository>().saveAiReadinessResult(result);
      setState(() => _isAnalyzing = false);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AiReadinessResultScreen(
            result: result,
            reviewQuestions: _questions,
            reviewAnswers: answersSnapshot,
          ),
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
    return Scaffold(
      appBar: AppBar(title: const Text('AI Readiness'), actions: const [HomeButton()]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How ready are you to work with AI?', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Short scenario questions, not a self-rating — your score reflects what you '
              'actually know and how you\'d judge an AI\'s output, not just your confidence. '
              'Each attempt draws a fresh set of questions, so retaking it is a real retest.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            for (final topic in AiReadinessTopic.values) ...[
              Text(topic.label, style: Theme.of(context).textTheme.titleMedium),
              Text(topic.description, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              for (final question in _questions.where((q) => q.topic == topic))
                _QuestionCard(
                  key: ValueKey(question.id),
                  question: question,
                  answer: _answers[question.id],
                  onChanged: (v) => setState(() => _answers[question.id] = v),
                ),
              const SizedBox(height: 12),
            ],
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

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({super.key, required this.question, required this.answer, required this.onChanged});

  final ScenarioQuestion question;
  final dynamic answer;
  final ValueChanged<dynamic> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey('question_${question.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question.prompt, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            if (question.type == QuestionType.multipleChoice)
              RadioGroup<int>(
                groupValue: answer is int ? answer as int : null,
                onChanged: (v) => onChanged(v),
                child: Column(
                  children: [
                    for (var i = 0; i < question.options.length; i++)
                      RadioListTile<int>(
                        key: ValueKey('option_${question.id}_$i'),
                        value: i,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(question.options[i]),
                      ),
                  ],
                ),
              )
            else
              TextField(
                key: ValueKey('fillInBlank_${question.id}'),
                decoration: const InputDecoration(
                  hintText: 'Type your answer',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: onChanged,
              ),
          ],
        ),
      ),
    );
  }
}
