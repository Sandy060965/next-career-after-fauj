import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/models/officer_profile.dart';
import 'package:next_career_after_fauj/core/services/profile_repository.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/ai_readiness/ai_readiness_quiz_screen.dart';
import 'package:next_career_after_fauj/features/ai_readiness/ai_readiness_service.dart';
import 'package:provider/provider.dart';

Widget _appUnderTest({
  dynamic analyzeAiReadiness = mockAnalyzeAiReadiness,
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
      home: AiReadinessQuizScreen(analyzeAiReadiness: analyzeAiReadiness),
    ),
  );
}

void main() {
  testWidgets('quiz shows one rating control per AI dimension, defaulting to 3', (tester) async {
    await tester.pumpWidget(_appUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('AI Awareness'), findsOneWidget);
    expect(find.text('AI Productivity'), findsOneWidget);
    expect(find.text('AI Decision Support'), findsOneWidget);
    expect(find.text('AI Leadership'), findsOneWidget);
    expect(find.text('AI Governance'), findsOneWidget);
    expect(find.byKey(const Key('rating_awareness')), findsOneWidget);
    expect(find.byKey(const Key('submitAssessmentButton')), findsOneWidget);
  });

  testWidgets('submitting the quiz navigates to the result screen with a computed score',
      (tester) async {
    await tester.pumpWidget(_appUnderTest());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.byKey(const Key('submitAssessmentButton')), 200);
    await tester.tap(find.byKey(const Key('submitAssessmentButton')));
    await tester.pumpAndSettle();

    // All five dimensions default to a rating of 3 -> (15/25)*100 = 60.
    final scoreFinder = find.byKey(const Key('readinessScoreText'));
    expect(scoreFinder, findsOneWidget);
    expect(tester.widget<Text>(scoreFinder).data, '60');

    await tester.scrollUntilVisible(find.text('Priority gaps'), 300);
    expect(find.text('Priority gaps'), findsOneWidget);

    await tester.scrollUntilVisible(find.byKey(const Key('cvAiBridgeCard')), 300);
    expect(find.byKey(const Key('cvAiBridgeCard')), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Your 90-day roadmap'), 300);
    expect(find.text('Your 90-day roadmap'), findsOneWidget);
  });
}
