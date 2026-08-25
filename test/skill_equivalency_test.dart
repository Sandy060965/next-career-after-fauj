import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/services/profile_repository.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/skill_equivalency/course_civilianization.dart';
import 'package:next_career_after_fauj/features/skill_equivalency/skill_equivalency.dart';
import 'package:next_career_after_fauj/features/skill_equivalency/skill_equivalency_screen.dart';
import 'package:provider/provider.dart';

Widget _wrap(Widget child, {ProfileRepository? repository}) {
  return ChangeNotifierProvider<ProfileRepository>.value(
    value: repository ?? ProfileRepository(),
    child: MaterialApp(theme: AppTheme.light, home: child),
  );
}

void _setTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 30000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('shows every skill equivalency with its civilian mapping', (tester) async {
    _setTallViewport(tester);

    await tester.pumpWidget(_wrap(const SkillEquivalencyScreen()));

    for (final entry in kSkillEquivalencies) {
      final finder = find.byKey(ValueKey('equivalency_${entry.militaryTerm}'));
      await tester.ensureVisible(finder);
      expect(finder, findsOneWidget);
      expect(find.text(entry.civilianEquivalent), findsOneWidget);
    }
  });

  group("Don't see your course?", () {
    testWidgets('submitting an empty course name shows a validation error', (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(_wrap(const SkillEquivalencyScreen()));

      await tester.ensureVisible(find.byKey(const Key('submitCourseButton')));
      await tester.tap(find.byKey(const Key('submitCourseButton')));
      await tester.pumpAndSettle();

      expect(find.text('Enter the course or training name to continue'), findsOneWidget);
    });

    testWidgets('a verified lookup shows the civilian translation and a verified badge',
        (tester) async {
      _setTallViewport(tester);
      Future<CourseCivilianizationResult> stubCivilianizer({
        required String courseName,
        String? courseDescription,
        String? mobileNumber,
      }) async {
        return const CourseCivilianizationResult(
          civilianEquivalent: 'Test Civilian Title',
          description: 'Test description grounded in a real source.',
          verified: true,
          sourceNote: 'Found on an official establishment website.',
        );
      }

      await tester.pumpWidget(
        _wrap(SkillEquivalencyScreen(civilianizeCourse: stubCivilianizer)),
      );

      await tester.ensureVisible(find.byKey(const Key('courseNameField')));
      await tester.enterText(find.byKey(const Key('courseNameField')), 'Long Gunnery Staff Course');
      await tester.ensureVisible(find.byKey(const Key('submitCourseButton')));
      await tester.tap(find.byKey(const Key('submitCourseButton')));
      await tester.pumpAndSettle();

      expect(find.text('Test Civilian Title'), findsOneWidget);
      expect(find.text('Verified via web search'), findsOneWidget);
      expect(find.text('Found on an official establishment website.'), findsOneWidget);
    });

    testWidgets('an unverified lookup labels itself as such, not as a curated entry',
        (tester) async {
      _setTallViewport(tester);
      Future<CourseCivilianizationResult> stubCivilianizer({
        required String courseName,
        String? courseDescription,
        String? mobileNumber,
      }) async {
        return const CourseCivilianizationResult(
          civilianEquivalent: 'Best-Effort Civilian Title',
          description: 'Based only on what the officer described.',
          verified: false,
          sourceNote: 'No independent source found; based only on the officer\'s own description.',
        );
      }

      await tester.pumpWidget(
        _wrap(SkillEquivalencyScreen(civilianizeCourse: stubCivilianizer)),
      );

      await tester.ensureVisible(find.byKey(const Key('courseNameField')));
      await tester.enterText(find.byKey(const Key('courseNameField')), 'Some Obscure Course');
      await tester.ensureVisible(find.byKey(const Key('submitCourseButton')));
      await tester.tap(find.byKey(const Key('submitCourseButton')));
      await tester.pumpAndSettle();

      // Some curated entries are themselves flagged not-independently-
      // verified (see kSkillEquivalencies), so this badge can legitimately
      // appear more than once — scope the check to the submitted result.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('equivalency_Some Obscure Course')),
          matching: find.text('Not independently verified'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a description containing a flagged term shows the redaction review first',
        (tester) async {
      _setTallViewport(tester);
      var callCount = 0;
      Future<CourseCivilianizationResult> countingCivilianizer({
        required String courseName,
        String? courseDescription,
        String? mobileNumber,
      }) async {
        callCount++;
        return const CourseCivilianizationResult(
          civilianEquivalent: 'X',
          description: 'Y',
          verified: false,
          sourceNote: '',
        );
      }

      await tester.pumpWidget(
        _wrap(SkillEquivalencyScreen(civilianizeCourse: countingCivilianizer)),
      );

      await tester.ensureVisible(find.byKey(const Key('courseNameField')));
      await tester.enterText(find.byKey(const Key('courseNameField')), 'Some Course');
      await tester.ensureVisible(find.byKey(const Key('courseDescriptionField')));
      await tester.enterText(
        find.byKey(const Key('courseDescriptionField')),
        'Ran logistics for 4 Battalion during the exercise.',
      );
      await tester.ensureVisible(find.byKey(const Key('submitCourseButton')));
      await tester.tap(find.byKey(const Key('submitCourseButton')));
      await tester.pumpAndSettle();

      expect(find.text('Review before continuing'), findsOneWidget);
      expect(callCount, 0);

      await tester.tap(find.byKey(const Key('confirmRedactionReviewButton')));
      await tester.pumpAndSettle();

      expect(callCount, 1);
    });

    testWidgets('"Look up another course" resets the form for a fresh lookup', (tester) async {
      _setTallViewport(tester);
      Future<CourseCivilianizationResult> stubCivilianizer({
        required String courseName,
        String? courseDescription,
        String? mobileNumber,
      }) async {
        return const CourseCivilianizationResult(
          civilianEquivalent: 'Test Civilian Title',
          description: 'Test description.',
          verified: true,
          sourceNote: '',
        );
      }

      await tester.pumpWidget(
        _wrap(SkillEquivalencyScreen(civilianizeCourse: stubCivilianizer)),
      );

      await tester.ensureVisible(find.byKey(const Key('courseNameField')));
      await tester.enterText(find.byKey(const Key('courseNameField')), 'Some Course');
      await tester.ensureVisible(find.byKey(const Key('submitCourseButton')));
      await tester.tap(find.byKey(const Key('submitCourseButton')));
      await tester.pumpAndSettle();

      expect(find.text('Test Civilian Title'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('submitAnotherCourseButton')));
      await tester.tap(find.byKey(const Key('submitAnotherCourseButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('courseNameField')), findsOneWidget);
      expect(find.text('Test Civilian Title'), findsNothing);
    });
  });
}
