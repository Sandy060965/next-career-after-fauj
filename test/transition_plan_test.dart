import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/models/officer_profile.dart';
import 'package:next_career_after_fauj/core/routing/app_routes.dart';
import 'package:next_career_after_fauj/core/services/profile_repository.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/transition_plan/transition_phase_content.dart';
import 'package:next_career_after_fauj/features/transition_plan/transition_plan_screen.dart';
import 'package:next_career_after_fauj/features/vertical_fit/vertical_fit.dart';
import 'package:provider/provider.dart';

OfficerProfile _profileWithReleaseIn(int months) {
  return OfficerProfile(
    rank: 'Lt Col',
    fullName: 'Lt Col A Verma',
    dateOfBirth: DateTime(1978, 5, 10),
    workExperienceYears: 18,
    workExperienceMonths: 2,
    releaseStatus: months <= 0 ? ReleaseStatus.alreadyReleased : ReleaseStatus.tentative,
    releaseDate: DateTime.now().add(Duration(days: months * 30)),
    service: OfficerService.army,
    mobileNumber: '9876543210',
    email: 'a.verma@example.com',
    segment: OfficerSegment.pmr,
    cvFileName: 'resume.pdf',
  );
}

Widget _wrap(ProfileRepository repository) {
  return ChangeNotifierProvider<ProfileRepository>.value(
    value: repository,
    child: MaterialApp(
      theme: AppTheme.light,
      home: const TransitionPlanScreen(),
      routes: {
        AppRoutes.jdMatch: (_) => const Scaffold(body: Text('JD Match screen')),
      },
    ),
  );
}

void main() {
  test('currentTransitionPhase picks the nearest reached milestone', () {
    expect(currentTransitionPhase(10).label, 'T-12 months');
    expect(currentTransitionPhase(8).label, 'T-9 months');
    expect(currentTransitionPhase(20).label, 'T-12 months');
    expect(currentTransitionPhase(0).label, 'Joining');
    expect(currentTransitionPhase(-5).label, 'Joining');
  });

  testWidgets('T-12 phase is marked current focus for a release ~10 months away', (tester) async {
    final repository = ProfileRepository()..saveProfile(_profileWithReleaseIn(10));
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    final t12Card = find.byKey(const Key('phaseCard_T-12 months'));
    expect(
      find.descendant(of: t12Card, matching: find.byKey(const Key('currentPhaseChip'))),
      findsOneWidget,
    );
  });

  testWidgets('Joining phase is current once already released', (tester) async {
    // Tall enough that all 6 phase cards are laid out — Joining is the last
    // one, well beyond the default 600px test viewport.
    tester.view.physicalSize = const Size(430, 4600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = ProfileRepository()..saveProfile(_profileWithReleaseIn(-5));
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    final joiningCard = find.byKey(const Key('phaseCard_Joining'));
    expect(
      find.descendant(of: joiningCard, matching: find.byKey(const Key('currentPhaseChip'))),
      findsOneWidget,
    );
    expect(find.text("You're released — here's what to focus on now."), findsOneWidget);
  });

  testWidgets('a completed Vertical Fit assessment shows its action as done', (tester) async {
    final repository = ProfileRepository()..saveProfile(_profileWithReleaseIn(10));
    repository.saveVerticalFitAssessment(const VerticalFitAssessment(ratings: {}));
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    final actionRow =
        find.byKey(const Key('transitionAction_Take the Career Vertical Fit assessment'));
    expect(
      find.descendant(
        of: actionRow,
        matching: find.byWidgetPredicate((w) => w is Icon && w.icon == Icons.check_circle),
      ),
      findsOneWidget,
    );
  });

  testWidgets('tapping an action navigates to its module', (tester) async {
    final repository = ProfileRepository()..saveProfile(_profileWithReleaseIn(8));
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('transitionAction_Run JD Match against 2-3 target job descriptions')),
    );
    await tester.pumpAndSettle();

    expect(find.text('JD Match screen'), findsOneWidget);
  });
}
