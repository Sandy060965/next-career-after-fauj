import 'package:flutter/material.dart';

import '../../core/widgets/home_button.dart';
import 'ai_readiness_scenario.dart';

/// Shown after an AI Readiness attempt so the officer can see exactly what
/// they answered, what was correct, and why — not just a final score. Every
/// question from that attempt is shown, grouped by topic, regardless of
/// whether it was answered correctly.
class AiReadinessReviewScreen extends StatelessWidget {
  const AiReadinessReviewScreen({super.key, required this.questions, required this.answers});

  final List<ScenarioQuestion> questions;
  final Map<String, dynamic> answers;

  String _answerDisplay(ScenarioQuestion q) {
    final answer = answers[q.id];
    if (q.type == QuestionType.multipleChoice) {
      return answer is int ? q.options[answer] : 'Not answered';
    }
    return (answer is String && answer.trim().isNotEmpty) ? answer : 'Not answered';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review Your Answers'), actions: const [HomeButton()]),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Every question from this attempt, your answer, the correct answer, and why — '
            'whether or not you got it right.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          for (final topic in AiReadinessTopic.values) ...[
            if (questions.any((q) => q.topic == topic)) ...[
              Text(topic.label, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final q in questions.where((q) => q.topic == topic)) _ReviewTile(
                key: ValueKey('review_${q.id}'),
                question: q,
                yourAnswer: _answerDisplay(q),
                correct: q.isCorrect(answers[q.id]),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({super.key, required this.question, required this.yourAnswer, required this.correct});

  final ScenarioQuestion question;
  final String yourAnswer;
  final bool correct;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  correct ? Icons.check_circle : Icons.cancel,
                  color: correct ? colorScheme.primary : colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(question.prompt, style: Theme.of(context).textTheme.bodyMedium),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('Your answer: $yourAnswer', style: Theme.of(context).textTheme.bodySmall),
            if (!correct) ...[
              const SizedBox(height: 2),
              Text(
                'Correct answer: ${question.correctAnswerDisplay}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 6),
            Text(question.explanation, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
