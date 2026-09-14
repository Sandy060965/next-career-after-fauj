import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/models/officer_profile.dart';
import 'package:next_career_after_fauj/core/routing/app_routes.dart';
import 'package:next_career_after_fauj/core/services/profile_repository.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/ai_readiness/ai_readiness_quiz_screen.dart';
import 'package:next_career_after_fauj/features/ai_readiness/ai_readiness_scenario.dart';
import 'package:next_career_after_fauj/features/ai_readiness/ai_readiness_service.dart';
import 'package:provider/provider.dart';

/// A fixed (non-random) sample — 4 MCQ + 1 fill-in-blank per topic, taken in
/// bank order — so tests get a reproducible question set instead of the
/// random-per-attempt sample the real app uses.
List<ScenarioQuestion> _fixedTestQuestions() {
  final questions = <ScenarioQuestion>[];
  for (final topic in AiReadinessTopic.values) {
    final pool = kAiReadinessQuestionBank[topic]!;
    questions.addAll(pool.where((q) => q.type == QuestionType.multipleChoice).take(4));
    questions.addAll(pool.where((q) => q.type == QuestionType.fillInBlank).take(1));
  }
  return questions;
}

Widget _appUnderTest({
  dynamic analyzeAiReadiness = mockAnalyzeAiReadiness,
  List<ScenarioQuestion>? questions,
}) {
  final repository = ProfileRepository()
    ..saveProfile(
      OfficerProfile(
        rank: 'Lt Col',
        fullName: 'Lt Col A Verma',
        dateOfBirth: DateTime(1978, 5, 10),
        workExperienceYears: 18,
        workExperienceMonths: 2,
        releaseStatus: ReleaseStatus.tentative,
        releaseDate: DateTime(2027, 6, 30),
        service: OfficerService.army,
        mobileNumber: '9876543210',
        email: 'a.verma@example.com',
        segment: OfficerSegment.pmr,
        cvFileName: 'resume.pdf',
        cvExtractedText: 'Sample CV text',
      ),
    );
  return ChangeNotifierProvider<ProfileRepository>.value(
    value: repository,
    child: MaterialApp(
      theme: AppTheme.light,
      home: AiReadinessQuizScreen(
        analyzeAiReadiness: analyzeAiReadiness,
        questionsOverride: questions ?? _fixedTestQuestions(),
      ),
      routes: {
        // A fresh instance, matching what "Retake this assessment" on the
        // result screen actually routes to in the real app (main.dart).
        AppRoutes.aiReadiness: (_) => AiReadinessQuizScreen(
              analyzeAiReadiness: analyzeAiReadiness,
              questionsOverride: questions ?? _fixedTestQuestions(),
            ),
      },
    ),
  );
}

void _setTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 20000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Answers every question in [questions] — MCQ via [pickIndex], fill-in-blank
/// via [pickText] — to drive every question to either fully-correct or
/// fully-incorrect for score checks.
Future<void> _answerAll(
  WidgetTester tester,
  List<ScenarioQuestion> questions, {
  required int Function(ScenarioQuestion q) pickIndex,
  required String Function(ScenarioQuestion q) pickText,
}) async {
  for (final q in questions) {
    if (q.type == QuestionType.multipleChoice) {
      await tester.tap(find.byKey(ValueKey('option_${q.id}_${pickIndex(q)}')));
    } else {
      await tester.enterText(find.byKey(ValueKey('fillInBlank_${q.id}')), pickText(q));
    }
  }
  await tester.pump();
}

void main() {
  testWidgets('quiz shows one card per question, grouped by topic', (tester) async {
    _setTallViewport(tester);
    final questions = _fixedTestQuestions();
    await tester.pumpWidget(_appUnderTest(questions: questions));
    await tester.pumpAndSettle();

    for (final topic in AiReadinessTopic.values) {
      expect(find.text(topic.label), findsOneWidget);
    }
    for (final q in questions) {
      expect(find.byKey(ValueKey('question_${q.id}')), findsOneWidget);
    }
    expect(find.byKey(const Key('submitAssessmentButton')), findsOneWidget);
  });

  testWidgets('questions are numbered continuously 1..N across topic sections, not restarted per topic',
      (tester) async {
    _setTallViewport(tester);
    final questions = _fixedTestQuestions();
    await tester.pumpWidget(_appUnderTest(questions: questions));
    await tester.pumpAndSettle();

    // First question overall is numbered 1.
    expect(find.textContaining('1. ${questions.first.prompt}'), findsOneWidget);
    // Last question overall carries the full count, not a per-topic restart.
    expect(find.textContaining('${questions.length}. ${questions.last.prompt}'), findsOneWidget);
    // The first question of the second topic continues the count rather than
    // restarting at 1 — 5 questions per topic in the fixed test set.
    final secondTopicFirstQuestion = questions[5];
    expect(find.textContaining('6. ${secondTopicFirstQuestion.prompt}'), findsOneWidget);
  });

  testWidgets('submitting with unanswered questions shows a snackbar and does not call the service',
      (tester) async {
    _setTallViewport(tester);
    var called = false;
    await tester.pumpWidget(
      _appUnderTest(
        analyzeAiReadiness: ({
          required assessment,
          required cvFileName,
          cvExtractedText,
          cvPdfBytes,
          releaseDate,
        }) {
          called = true;
          return mockAnalyzeAiReadiness(
            assessment: assessment,
            cvFileName: cvFileName,
            cvExtractedText: cvExtractedText,
            cvPdfBytes: cvPdfBytes,
            releaseDate: releaseDate,
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('submitAssessmentButton')));
    await tester.pump();

    expect(called, isFalse);
    expect(find.text('Answer every question to see your results'), findsOneWidget);
  });

  testWidgets('answering every question correctly scores 100', (tester) async {
    _setTallViewport(tester);
    final questions = _fixedTestQuestions();
    await tester.pumpWidget(_appUnderTest(questions: questions));
    await tester.pumpAndSettle();

    await _answerAll(
      tester,
      questions,
      pickIndex: (q) => q.correctIndex!,
      pickText: (q) => q.acceptedAnswers.first,
    );
    await tester.tap(find.byKey(const Key('submitAssessmentButton')));
    await tester.pumpAndSettle();

    final scoreFinder = find.byKey(const Key('readinessScoreText'));
    expect(scoreFinder, findsOneWidget);
    expect(tester.widget<Text>(scoreFinder).data, '100');
  });

  testWidgets('answering every question incorrectly scores 0', (tester) async {
    _setTallViewport(tester);
    final questions = _fixedTestQuestions();
    await tester.pumpWidget(_appUnderTest(questions: questions));
    await tester.pumpAndSettle();

    await _answerAll(
      tester,
      questions,
      pickIndex: (q) => q.correctIndex == 0 ? 1 : 0, // any wrong option
      pickText: (_) => 'definitely_the_wrong_answer',
    );
    await tester.tap(find.byKey(const Key('submitAssessmentButton')));
    await tester.pumpAndSettle();

    final scoreFinder = find.byKey(const Key('readinessScoreText'));
    expect(tester.widget<Text>(scoreFinder).data, '0');
  });

  testWidgets('result screen shows the roadmap, skill gaps, CV-AI bridge, and a working answer review',
      (tester) async {
    _setTallViewport(tester);
    final questions = _fixedTestQuestions();
    await tester.pumpWidget(_appUnderTest(questions: questions));
    await tester.pumpAndSettle();

    await _answerAll(
      tester,
      questions,
      pickIndex: (q) => q.correctIndex!,
      pickText: (q) => q.acceptedAnswers.first,
    );
    await tester.tap(find.byKey(const Key('submitAssessmentButton')));
    await tester.pumpAndSettle();

    expect(find.text('Priority gaps'), findsOneWidget);
    expect(find.byKey(const Key('cvAiBridgeCard')), findsOneWidget);
    expect(find.text('Your 90-day roadmap'), findsOneWidget);
    expect(find.byKey(const Key('capabilitySummaryCard')), findsOneWidget);
    for (final topic in AiReadinessTopic.values) {
      expect(find.byKey(ValueKey('capabilityScore_${topic.name}')), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(ValueKey('capabilityScore_${topic.name}'))).data, '100/100');
    }

    await tester.tap(find.byKey(const Key('reviewAnswersButton')));
    await tester.pumpAndSettle();

    expect(find.text('Review Your Answers'), findsOneWidget);
    for (final q in questions) {
      expect(find.byKey(ValueKey('review_${q.id}')), findsOneWidget);
    }
    expect(find.textContaining('Correct answer:'), findsNothing);
  });

  testWidgets('"Retake this assessment" on the result screen re-opens a fresh quiz', (tester) async {
    _setTallViewport(tester);
    final questions = _fixedTestQuestions();
    await tester.pumpWidget(_appUnderTest(questions: questions));
    await tester.pumpAndSettle();

    await _answerAll(
      tester,
      questions,
      pickIndex: (q) => q.correctIndex!,
      pickText: (q) => q.acceptedAnswers.first,
    );
    await tester.tap(find.byKey(const Key('submitAssessmentButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('retakeAiReadinessButton')));
    await tester.pumpAndSettle();

    expect(find.text('How ready are you to work with AI?'), findsOneWidget);
    // A fresh attempt starts unanswered, not pre-filled with the last score.
    expect(find.byKey(const Key('submitAssessmentButton')), findsOneWidget);
  });
}
