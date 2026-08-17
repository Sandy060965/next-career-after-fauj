/// Feedback on one spoken/typed practice answer — grounded only in what the
/// officer actually said, never a rewritten "better answer" with invented
/// facts about them.
class MockInterviewFeedback {
  const MockInterviewFeedback({
    required this.strengths,
    required this.improvements,
    required this.overallImpression,
  });

  final List<String> strengths;
  final List<String> improvements;
  final String overallImpression;
}
