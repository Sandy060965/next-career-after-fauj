import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/models/officer_profile.dart';
import 'package:next_career_after_fauj/core/services/profile_repository.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/ai_readiness/ai_readiness_quiz_screen.dart';
import 'package:next_career_after_fauj/features/ai_readiness/ai_readiness_scenario.dart';
import 'package:next_career_after_fauj/features/ai_readiness/ai_readiness_service.dart';
import 'package:provider/provider.dart';

Widget _appUnderTest({dynamic analyzeAiReadiness = mockAnalyzeAiReadiness}) {
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
      home: AiReadinessQuizScreen(analyzeAiReadiness: analyzeAiReadiness),
    ),
  );
}

void _setTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 8500);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Taps the given option index for every question — used to drive every
/// question to either fully-correct or fully-incorrect for score checks.
Future<void> _answerAll(WidgetTester tester, int Function(ScenarioQuestion q) pickIndex) async {
  for (final q in kAiReadinessQuestions) {
    final i = pickIndex(q);
    await tester.tap(find.byKey(ValueKey('option_${q.id}_$i')));
  }
  await tester.pump();
}

void main() {
  testWidgets('quiz shows one card per question, grouped by tier', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_appUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Knowledge'), findsOneWidget);
    expect(find.text('Application'), findsOneWidget);
    expect(find.text('Judgment'), findsOneWidget);
    expect(find.text('Governance'), findsOneWidget);
    for (final q in kAiReadinessQuestions) {
      expect(find.byKey(ValueKey('question_${q.id}')), findsOneWidget);
    }
    expect(find.byKey(const Key('submitAssessmentButton')), findsOneWidget);
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

  testWidgets('answering every question correctly scores 100 on every tier', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_appUnderTest());
    await tester.pumpAndSettle();

    await _answerAll(tester, (q) => q.correctIndex);
    await tester.tap(find.byKey(const Key('submitAssessmentButton')));
    await tester.pumpAndSettle();

    final scoreFinder = find.byKey(const Key('readinessScoreText'));
    expect(scoreFinder, findsOneWidget);
    expect(tester.widget<Text>(scoreFinder).data, '100');
  });

  testWidgets('answering every question incorrectly scores 0', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_appUnderTest());
    await tester.pumpAndSettle();

    await _answerAll(
      tester,
      (q) => q.correctIndex == 0 ? 1 : 0, // any wrong option
    );
    await tester.tap(find.byKey(const Key('submitAssessmentButton')));
    await tester.pumpAndSettle();

    final scoreFinder = find.byKey(const Key('readinessScoreText'));
    expect(tester.widget<Text>(scoreFinder).data, '0');
  });

  testWidgets('result screen shows the roadmap, skill gaps, and CV-AI bridge sections',
      (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_appUnderTest());
    await tester.pumpAndSettle();

    await _answerAll(tester, (q) => q.correctIndex);
    await tester.tap(find.byKey(const Key('submitAssessmentButton')));
    await tester.pumpAndSettle();

    expect(find.text('Priority gaps'), findsOneWidget);
    expect(find.byKey(const Key('cvAiBridgeCard')), findsOneWidget);
    expect(find.text('Your 90-day roadmap'), findsOneWidget);
  });
}
