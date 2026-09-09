import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/models/officer_profile.dart';
import 'package:next_career_after_fauj/core/services/profile_repository.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/skill_equivalency/course_civilianization.dart';
import 'package:next_career_after_fauj/features/skill_equivalency/skill_equivalency.dart';
import 'package:next_career_after_fauj/features/skill_equivalency/skill_equivalency_screen.dart';
import 'package:provider/provider.dart';

// The screen now also fetches admin-approved courses on load, defaulting to
// the real backend call — every test must override it, or it fires a real
// network request against the live backend and hangs the test sandbox.
Future<List<SkillEquivalency>> _noApproved() async => [];

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

    await tester.pumpWidget(
      _wrap(const SkillEquivalencyScreen(fetchApprovedEquivalencies: _noApproved)),
    );

    for (final entry in kSkillEquivalencies) {
      final finder = find.byKey(ValueKey('equivalency_${entry.militaryTerm}'));
      await tester.ensureVisible(finder);
      expect(finder, findsOneWidget);
      expect(find.text(entry.civilianEquivalent), findsOneWidget);
    }
  });

  group('search', () {
    testWidgets('typing a query filters the list down to matching entries', (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(
        _wrap(const SkillEquivalencyScreen(fetchApprovedEquivalencies: _noApproved)),
      );

      final target = kSkillEquivalencies.first;
      final other = kSkillEquivalencies.firstWhere((e) => e.militaryTerm != target.militaryTerm);

      await tester.enterText(
        find.byKey(const Key('skillEquivalencySearchField')),
        target.militaryTerm,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(ValueKey('equivalency_${target.militaryTerm}')), findsOneWidget);
      expect(find.byKey(ValueKey('equivalency_${other.militaryTerm}')), findsNothing);
    });

    testWidgets('a query with no match shows a hint pointing to the lookup box', (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(
        _wrap(const SkillEquivalencyScreen(fetchApprovedEquivalencies: _noApproved)),
      );

      await tester.enterText(
        find.byKey(const Key('skillEquivalencySearchField')),
        'zzz-not-a-real-course-zzz',
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('No match in the list'), findsOneWidget);
    });

    testWidgets('clearing the search restores the full list', (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(
        _wrap(const SkillEquivalencyScreen(fetchApprovedEquivalencies: _noApproved)),
      );

      final target = kSkillEquivalencies.first;
      await tester.enterText(
        find.byKey(const Key('skillEquivalencySearchField')),
        target.militaryTerm,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      for (final entry in kSkillEquivalencies) {
        await tester.ensureVisible(find.byKey(ValueKey('equivalency_${entry.militaryTerm}')));
        expect(find.byKey(ValueKey('equivalency_${entry.militaryTerm}')), findsOneWidget);
      }
    });
  });

  group('CV-mention highlighting', () {
    testWidgets('a course mentioned in the CV shows an "In your CV" badge', (tester) async {
      _setTallViewport(tester);
      final target = kSkillEquivalencies.first;
      final repo = ProfileRepository()
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
            cvExtractedText: 'Completed ${target.militaryTerm} in 2015.',
          ),
        );

      await tester.pumpWidget(
        _wrap(
          const SkillEquivalencyScreen(fetchApprovedEquivalencies: _noApproved),
          repository: repo,
        ),
      );

      expect(
        find.descendant(
          of: find.byKey(ValueKey('equivalency_${target.militaryTerm}')),
          matching: find.byKey(const Key('inCvBadge')),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a course not mentioned in the CV shows no badge', (tester) async {
      _setTallViewport(tester);
      final repo = ProfileRepository()
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
            cvExtractedText: 'Nothing relevant in here at all.',
          ),
        );

      await tester.pumpWidget(
        _wrap(
          const SkillEquivalencyScreen(fetchApprovedEquivalencies: _noApproved),
          repository: repo,
        ),
      );

      expect(find.byKey(const Key('inCvBadge')), findsNothing);
    });
  });

  testWidgets('merges admin-approved equivalencies into the list', (tester) async {
    _setTallViewport(tester);
    const approved = SkillEquivalency(
      militaryTerm: 'Test Approved Course',
      civilianEquivalent: 'Test Approved Civilian Title',
      description: 'Approved by admin from an officer submission.',
      verified: true,
    );

    await tester.pumpWidget(
      _wrap(
        SkillEquivalencyScreen(fetchApprovedEquivalencies: () async => [approved]),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('equivalency_Test Approved Course')));

    expect(find.byKey(const Key('equivalency_Test Approved Course')), findsOneWidget);
    expect(find.text('Test Approved Civilian Title'), findsOneWidget);
  });

  group("Don't see your course?", () {
    testWidgets('submitting an empty course name shows a validation error', (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(
        _wrap(const SkillEquivalencyScreen(fetchApprovedEquivalencies: _noApproved)),
      );

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
        _wrap(SkillEquivalencyScreen(
          civilianizeCourse: stubCivilianizer,
          fetchApprovedEquivalencies: _noApproved,
        )),
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
        _wrap(SkillEquivalencyScreen(
          civilianizeCourse: stubCivilianizer,
          fetchApprovedEquivalencies: _noApproved,
        )),
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
        _wrap(SkillEquivalencyScreen(
          civilianizeCourse: countingCivilianizer,
          fetchApprovedEquivalencies: _noApproved,
        )),
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
        _wrap(SkillEquivalencyScreen(
          civilianizeCourse: stubCivilianizer,
          fetchApprovedEquivalencies: _noApproved,
        )),
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
