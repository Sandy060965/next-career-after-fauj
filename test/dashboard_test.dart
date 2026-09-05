import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/models/officer_profile.dart';
import 'package:next_career_after_fauj/core/routing/app_routes.dart';
import 'package:next_career_after_fauj/core/services/profile_repository.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/dashboard/dashboard_screen.dart';
import 'package:next_career_after_fauj/features/vertical_fit/vertical_fit.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _profile = OfficerProfile(
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
);

Widget _wrap(ProfileRepository repository) {
  return ChangeNotifierProvider<ProfileRepository>.value(
    value: repository,
    child: MaterialApp(
      theme: AppTheme.light,
      home: const DashboardScreen(),
      routes: {
        AppRoutes.verticalFit: (_) => const Scaffold(body: Text('Vertical Fit Screen')),
        AppRoutes.careerReadiness: (_) => const Scaffold(body: Text('Readiness Screen')),
        AppRoutes.transitionPlan: (_) => const Scaffold(body: Text('Transition Plan Screen')),
        AppRoutes.jobMatches: (_) => const Scaffold(body: Text('Job Matches Screen')),
        AppRoutes.financialPlanner: (_) => const Scaffold(body: Text('Financial Planner Screen')),
        AppRoutes.targetRoleStrategy: (_) => const Scaffold(body: Text('Target Role Screen')),
      },
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows a greeting and an empty readiness score with no profile', (tester) async {
    await tester.pumpWidget(_wrap(ProfileRepository()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dashboardReadinessCard')), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('dashboardReadinessScoreText'))).data, '—');
    expect(find.byKey(const Key('nextAction_1')), findsOneWidget);
  });

  testWidgets('greets the officer by rank and surname once a profile exists', (tester) async {
    final repo = ProfileRepository()..saveProfile(_profile);
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    expect(find.textContaining('Lt Col Verma'), findsOneWidget);
  });

  testWidgets('the first next action is completing an incomplete assessment', (tester) async {
    final repo = ProfileRepository()..saveProfile(_profile);
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    expect(find.textContaining('Complete the Career Fit assessment'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nextAction_1')));
    await tester.pumpAndSettle();
    expect(find.text('Vertical Fit Screen'), findsOneWidget);
  });

  testWidgets('shows a real score and a lowest-gap action once all assessments are complete',
      (tester) async {
    final repo = ProfileRepository()..saveProfile(_profile);
    repo.saveVerticalFitAssessment(const VerticalFitAssessment(ratings: {}));
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    // Only Career Fit is done (60) — the other two are still open, so those
    // remain the top next actions, not the "biggest gap" one yet.
    expect(tester.widget<Text>(find.byKey(const Key('dashboardReadinessScoreText'))).data, '60');
    expect(find.textContaining('Complete the CV & JD Fit assessment'), findsOneWidget);
  });

  testWidgets('tapping "View full breakdown" opens the Transition Readiness Index', (tester) async {
    await tester.pumpWidget(_wrap(ProfileRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('viewFullReadinessBreakdown')));
    await tester.pumpAndSettle();
    expect(find.text('Readiness Screen'), findsOneWidget);
  });
}
