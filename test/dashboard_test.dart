import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/models/officer_profile.dart';
import 'package:next_career_after_fauj/core/routing/app_routes.dart';
import 'package:next_career_after_fauj/core/routing/module_catalog.dart';
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

void _setTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 2200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
      'shows the 3 core assessment cards before the readiness card, and an empty score with no '
      'profile', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(ProfileRepository()));
    await tester.pumpAndSettle();

    // The 3 always-shown cards, in Career Fit / AI Readiness / CV & JD Fit order.
    final careerFitY = tester.getTopLeft(find.byKey(const Key('dimensionCard_Career Fit'))).dy;
    final aiReadinessY = tester.getTopLeft(find.byKey(const Key('dimensionCard_AI Readiness'))).dy;
    final cvJdFitY = tester.getTopLeft(find.byKey(const Key('dimensionCard_CV & JD Fit'))).dy;
    final readinessCardY = tester.getTopLeft(find.byKey(const Key('dashboardReadinessCard'))).dy;
    expect(careerFitY, lessThan(aiReadinessY));
    expect(aiReadinessY, lessThan(cvJdFitY));
    expect(cvJdFitY, lessThan(readinessCardY));

    expect(tester.widget<Text>(find.byKey(const Key('dashboardReadinessScoreText'))).data, '—');
  });

  testWidgets('greets the officer by rank and surname once a profile exists', (tester) async {
    final repo = ProfileRepository()..saveProfile(_profile);
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    expect(find.textContaining('Lt Col Verma'), findsOneWidget);
  });

  testWidgets('tapping an incomplete assessment card navigates to that assessment', (tester) async {
    _setTallViewport(tester);
    final repo = ProfileRepository()..saveProfile(_profile);
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('dimensionCard_Career Fit')));
    await tester.pumpAndSettle();
    expect(find.text('Vertical Fit Screen'), findsOneWidget);
  });

  testWidgets('a completed assessment card shows its score instead of a chevron', (tester) async {
    _setTallViewport(tester);
    final repo = ProfileRepository()..saveProfile(_profile);
    repo.saveVerticalFitAssessment(const VerticalFitAssessment(ratings: {}));
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    // Only Career Fit is done (60) — the other two remain open.
    expect(tester.widget<Text>(find.byKey(const Key('dashboardReadinessScoreText'))).data, '60');
    expect(find.textContaining('60/100'), findsWidgets);

    // A done card still says it's tappable — a checkmark alone would read as
    // "finished, don't touch again," but retaking is always available.
    expect(find.text('Tap to retake'), findsOneWidget);
  });

  testWidgets('tapping a completed assessment card re-opens that same assessment to retake it',
      (tester) async {
    _setTallViewport(tester);
    final repo = ProfileRepository()..saveProfile(_profile);
    repo.saveVerticalFitAssessment(const VerticalFitAssessment(ratings: {}));
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('dimensionCard_Career Fit')));
    await tester.pumpAndSettle();
    expect(find.text('Vertical Fit Screen'), findsOneWidget);
  });

  testWidgets('tapping "View full breakdown" opens the Transition Readiness Index', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(ProfileRepository()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('viewFullReadinessBreakdown')));
    await tester.tap(find.byKey(const Key('viewFullReadinessBreakdown')));
    await tester.pumpAndSettle();
    expect(find.text('Readiness Screen'), findsOneWidget);
  });

  testWidgets('the "How This App Works" guide is collapsed by default and, once expanded, '
      'names and describes every module from the catalog', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(ProfileRepository()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('instructionsCard')), findsOneWidget);
    // Collapsed by default — module text isn't in the tree yet.
    expect(find.textContaining(kCareerModules.first.modules.first.description), findsNothing);

    await tester.tap(find.byKey(const Key('instructionsExpansionTile')));
    await tester.pumpAndSettle();

    // Each module's label and description render together in one bullet row
    // (Text.rich), so a description match — descriptions are unique,
    // specific phrases, unlike some labels (e.g. "AI Readiness" also appears
    // as a dashboard dimension card title elsewhere on this same screen) —
    // is sufficient proof that row is present.
    for (final phases in [kCareerModules, kJobsModules, kLearnModules]) {
      for (final phase in phases) {
        for (final module in phase.modules) {
          expect(
            find.textContaining(module.description),
            findsOneWidget,
            reason: 'missing description for ${module.label}',
          );
        }
      }
    }
  });

  // AI Assistant is deliberately absent from kCareerModules/kJobsModules/
  // kLearnModules (see dashboard_screen.dart's _kAlwaysAvailableModules doc
  // comment) so it never gets a second, redundant button anywhere in the
  // Career/Jobs/Learn tabs or the wide-screen sidebar — those all render
  // straight from those three lists. It still needs to show up in "How This
  // App Works" so the guide's count matches the feedback form's module list.
  testWidgets('"How This App Works" lists AI Assistant as an Always Available '
      'entry, not a Career/Jobs/Learn module', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(ProfileRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('instructionsExpansionTile')));
    await tester.pumpAndSettle();

    expect(find.text('Always Available'), findsOneWidget);
    expect(find.text('Reachable From Every Screen'), findsOneWidget);
    expect(
      find.textContaining('Shown as a separate floating button'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Numbered 1–$kTotalModuleCount'),
      findsOneWidget,
    );
  });
}
