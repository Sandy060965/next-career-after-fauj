import 'mock_interview_feedback.dart';

typedef MockInterviewAnalyzer = Future<MockInterviewFeedback> Function({
  required String question,
  required String answer,
  String? jdText,
});

/// Placeholder analyzer used until the Cloudflare Worker backend is wired
/// in. Returns fixed sample feedback regardless of input.
Future<MockInterviewFeedback> mockAnalyzeInterviewAnswer({
  required String question,
  required String answer,
  String? jdText,
}) async {
  await Future.delayed(const Duration(milliseconds: 700));
  return const MockInterviewFeedback(
    strengths: [
      'You gave a specific example rather than speaking in generalities.',
      'You quantified the scale of what you managed.',
    ],
    improvements: [
      'Structure the answer more explicitly as Situation, Task, Action, Result — the outcome '
          'came through, but the setup was rushed.',
      'A couple of military-specific terms went unexplained; translate them into civilian '
          'equivalents.',
    ],
    overallImpression:
        'A solid, grounded answer — tightening the structure and the language would make it land '
        'more clearly with a civilian interviewer.',
  );
}
