import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/models/officer_profile.dart';
import 'package:next_career_after_fauj/core/services/profile_repository.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/cv_builder/built_cv.dart';
import 'package:next_career_after_fauj/features/cv_builder/cv_builder_intake.dart';
import 'package:next_career_after_fauj/features/cv_builder/cv_builder_screen.dart';
import 'package:next_career_after_fauj/features/cv_builder/cv_builder_service.dart';
import 'package:next_career_after_fauj/features/skill_equivalency/skill_equivalency.dart';
import 'package:provider/provider.dart';

// CvBuilderScreen fetches admin-approved course equivalencies on load,
// defaulting to the real backend call — every test must override it, or it
// fires a real network request against the live backend and hangs the test
// sandbox (same gotcha the old Skill Equivalency screen's tests guarded
// against).
Future<List<SkillEquivalency>> _noApprovedEquivalencies() async => [];

Widget _wrap(ProfileRepository repository, {CvBuilder? buildCv}) {
  return ChangeNotifierProvider<ProfileRepository>.value(
    value: repository,
    child: MaterialApp(
      theme: AppTheme.light,
      home: CvBuilderScreen(
        buildCv: buildCv ?? mockBuildCv,
        fetchApprovedEquivalencies: _noApprovedEquivalencies,
      ),
    ),
  );
}

void _setTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 5200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('model JSON round-trips', () {
    test('CvBuilderIntake with nested entries', () {
      const intake = CvBuilderIntake(
        summary: 'Operations leader.',
        workExperience: [
          WorkExperienceEntry(
            roleTitle: 'Operations Manager',
            organizationType: 'Infantry battalion, ~800 personnel',
            duration: '2018-2022',
            responsibilities: 'Led daily operations.',
          ),
        ],
        education: [EducationEntry(degree: 'MBA', institution: 'IIM', year: '2017')],
        certifications: [CertificationEntry(name: 'PMP', year: '2019')],
        courses: [CourseEntry(name: 'Higher Command Course', year: '2015')],
        honoursAwards: [
          AwardEntry(name: 'Vir Chakra (VrC)', year: '2012', bar: 'Bar', citation: 'For gallantry.'),
        ],
        skills: 'Leadership, Logistics',
      );
      final restored = CvBuilderIntake.fromJson(intake.toJson());
      expect(restored.summary, 'Operations leader.');
      expect(restored.workExperience.single.roleTitle, 'Operations Manager');
      expect(restored.education.single.degree, 'MBA');
      expect(restored.certifications.single.name, 'PMP');
      expect(restored.courses.single.name, 'Higher Command Course');
      expect(restored.honoursAwards.single.name, 'Vir Chakra (VrC)');
      expect(restored.honoursAwards.single.bar, 'Bar');
      expect(restored.honoursAwards.single.citation, 'For gallantry.');
      expect(restored.skills, 'Leadership, Logistics');
    });

    test('AwardEntry.fromJson defaults bar/citation to empty when the keys are missing (an award '
        'cached before this change)', () {
      final oldShapedAwardJson = {'name': 'Vir Chakra (VrC)', 'year': '2012'};
      final restored = AwardEntry.fromJson(oldShapedAwardJson);
      expect(restored.bar, '');
      expect(restored.citation, '');
    });

    test('CvBuilderIntake.fromJson defaults courses/honoursAwards to empty when the keys are '
        'missing (an intake cached before this feature shipped)', () {
      final oldShapedJson = {
        'summary': 'Operations leader.',
        'workExperience': <Map<String, dynamic>>[],
        'education': <Map<String, dynamic>>[],
        'certifications': <Map<String, dynamic>>[],
        'skills': 'Leadership',
        // No 'courses' or 'honoursAwards' keys at all.
      };
      final restored = CvBuilderIntake.fromJson(oldShapedJson);
      expect(restored.courses, isEmpty);
      expect(restored.honoursAwards, isEmpty);
      expect(restored.summary, 'Operations leader.');
    });

    test('BuiltCv', () {
      const cv = BuiltCv(cvText: 'Full CV text.');
      expect(BuiltCv.fromJson(cv.toJson()).cvText, 'Full CV text.');
    });
  });

  group('CvBuilderScreen', () {
    testWidgets('starts with one empty work experience card', (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(_wrap(ProfileRepository()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('workExperienceCard_0')), findsOneWidget);
      expect(find.byKey(const Key('workExperienceCard_1')), findsNothing);
      // Only one entry, so the remove button shouldn't be offered yet.
      expect(find.byKey(const Key('removeWorkExperienceButton_0')), findsNothing);
    });

    testWidgets(
        'adding and removing work experience, education, certification, course, and award cards',
        (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(_wrap(ProfileRepository()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('addWorkExperienceButton')));
      await tester.tap(find.byKey(const Key('addEducationButton')));
      await tester.tap(find.byKey(const Key('addCertificationButton')));
      await tester.tap(find.byKey(const Key('addCourseButton')));
      await tester.tap(find.byKey(const Key('addAwardButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('workExperienceCard_1')), findsOneWidget);
      expect(find.byKey(const Key('educationCard_0')), findsOneWidget);
      expect(find.byKey(const Key('certificationCard_0')), findsOneWidget);
      expect(find.byKey(const Key('courseCard_0')), findsOneWidget);
      expect(find.byKey(const Key('awardCard_0')), findsOneWidget);

      await tester.tap(find.byKey(const Key('removeWorkExperienceButton_1')));
      await tester.tap(find.byKey(const Key('removeEducationButton_0')));
      await tester.tap(find.byKey(const Key('removeCertificationButton_0')));
      await tester.ensureVisible(find.byKey(const Key('removeCourseButton_0')));
      await tester.tap(find.byKey(const Key('removeCourseButton_0')));
      await tester.ensureVisible(find.byKey(const Key('removeAwardButton_0')));
      await tester.tap(find.byKey(const Key('removeAwardButton_0')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('workExperienceCard_1')), findsNothing);
      expect(find.byKey(const Key('educationCard_0')), findsNothing);
      expect(find.byKey(const Key('certificationCard_0')), findsNothing);
      expect(find.byKey(const Key('courseCard_0')), findsNothing);
      expect(find.byKey(const Key('awardCard_0')), findsNothing);
    });

    testWidgets(
        'picking a curated course from the dropdown shows its civilian equivalent inline',
        (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(_wrap(ProfileRepository()));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('addCourseButton')));
      await tester.tap(find.byKey(const Key('addCourseButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('courseCivilianEquivalent_0')), findsNothing);

      await tester.ensureVisible(find.byKey(const Key('courseNameDropdown_0')));
      await tester.tap(find.byKey(const Key('courseNameDropdown_0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Higher Command Course').last);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('courseCivilianEquivalent_0')), findsOneWidget);
      expect(
        find.text('Advanced Executive Leadership (General Manager / VP level)'),
        findsOneWidget,
      );
      // No manual field for a curated pick.
      expect(find.byKey(const Key('courseOtherField_0')), findsNothing);
    });

    testWidgets(
        'a course already mentioned in the officer\'s CV is flagged in the dropdown',
        (tester) async {
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
            cvExtractedText: 'Completed the Higher Command Course in 2021.',
          ),
        );
      await tester.pumpWidget(_wrap(repo));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('addCourseButton')));
      await tester.tap(find.byKey(const Key('addCourseButton')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('courseNameDropdown_0')));
      await tester.tap(find.byKey(const Key('courseNameDropdown_0')));
      await tester.pumpAndSettle();

      // A checkmark appears next to the matched course's option in the open
      // dropdown menu — the exact same icon the standalone Skill
      // Equivalency Matrix screen uses for "found in your CV".
      expect(find.byIcon(Icons.check_circle), findsWidgets);
      expect(find.text('Higher Command Course'), findsWidgets);
    });

    testWidgets(
        'picking "Other (please specify)" for a course reveals manual entry and hides the '
        'civilian-equivalent line', (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(_wrap(ProfileRepository()));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('addCourseButton')));
      await tester.tap(find.byKey(const Key('addCourseButton')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('courseNameDropdown_0')));
      await tester.tap(find.byKey(const Key('courseNameDropdown_0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Other (please specify)').last);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('courseOtherField_0')), findsOneWidget);
      expect(find.byKey(const Key('courseCivilianEquivalent_0')), findsNothing);

      await tester.enterText(find.byKey(const Key('courseOtherField_0')), 'Some rare course');
    });

    testWidgets(
        'the honour/award dropdown only appears once a category is chosen, and only offers that '
        "category's awards", (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(_wrap(ProfileRepository()));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('addAwardButton')));
      await tester.tap(find.byKey(const Key('addAwardButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('honoursDropdown_0')), findsNothing);

      await tester.ensureVisible(find.byKey(const Key('honoursCategoryDropdown_0')));
      await tester.tap(find.byKey(const Key('honoursCategoryDropdown_0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('National Gallantry & Valour').last);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('honoursDropdown_0')), findsOneWidget);
      await tester.tap(find.byKey(const Key('honoursDropdown_0')));
      await tester.pumpAndSettle();
      expect(find.text('Vir Chakra (VrC)'), findsWidgets);
      // A campaign medal from a different category shouldn't be offered here.
      expect(find.text('Special Service Medal'), findsNothing);
      await tester.tap(find.text('Vir Chakra (VrC)').last);
      await tester.pumpAndSettle();

      // Switching category clears the previously-picked award.
      await tester.tap(find.byKey(const Key('honoursCategoryDropdown_0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Operational / Campaign / Service Medals').last);
      await tester.pumpAndSettle();
      expect(find.text('Vir Chakra (VrC)'), findsNothing);
    });

    testWidgets(
        'selecting "Other (please specify)" for an honour/award reveals a manual field, and '
        'switching back to a curated award hides it again', (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(_wrap(ProfileRepository()));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('addAwardButton')));
      await tester.tap(find.byKey(const Key('addAwardButton')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('honoursCategoryDropdown_0')));
      await tester.tap(find.byKey(const Key('honoursCategoryDropdown_0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('National Gallantry & Valour').last);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('honoursOtherField_0')), findsNothing);

      await tester.ensureVisible(find.byKey(const Key('honoursDropdown_0')));
      await tester.tap(find.byKey(const Key('honoursDropdown_0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Other (please specify)').last);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('honoursOtherField_0')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('honoursOtherField_0')), 'Op Vijay Star');

      await tester.tap(find.byKey(const Key('honoursDropdown_0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vir Chakra (VrC)').last);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('honoursOtherField_0')), findsNothing);
    });

    testWidgets(
        'picking "Other / Not Listed" as the category skips straight to manual entry, no award '
        'dropdown shown', (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(_wrap(ProfileRepository()));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('addAwardButton')));
      await tester.tap(find.byKey(const Key('addAwardButton')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('honoursCategoryDropdown_0')));
      await tester.tap(find.byKey(const Key('honoursCategoryDropdown_0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Other / Not Listed').last);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('honoursDropdown_0')), findsNothing);
      expect(find.byKey(const Key('honoursOtherField_0')), findsOneWidget);
    });

    testWidgets('rejects building with no role title entered', (tester) async {
      _setTallViewport(tester);
      var called = false;
      await tester.pumpWidget(
        _wrap(
          ProfileRepository(),
          buildCv: ({required intake}) {
            called = true;
            return mockBuildCv(intake: intake);
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('buildCvButton')));
      await tester.tap(find.byKey(const Key('buildCvButton')));
      await tester.pumpAndSettle();

      expect(called, isFalse);
      expect(find.text('Add at least one role title before building your CV'), findsOneWidget);
    });

    testWidgets('builds the CV from entered fields and persists the intake and result',
        (tester) async {
      _setTallViewport(tester);
      final repo = ProfileRepository();
      CvBuilderIntake? sentIntake;
      await tester.pumpWidget(
        _wrap(
          repo,
          buildCv: ({required intake}) {
            sentIntake = intake;
            return mockBuildCv(intake: intake);
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('roleTitleField_0')), 'Operations Manager');
      await tester.enterText(
        find.byKey(const Key('organizationTypeField_0')),
        'Infantry battalion, ~800 personnel',
      );
      await tester.enterText(find.byKey(const Key('durationField_0')), '2018-2022');
      await tester.enterText(
        find.byKey(const Key('responsibilitiesField_0')),
        'Led daily operations for a large organisation.',
      );
      await tester.enterText(find.byKey(const Key('skillsField')), 'Leadership, Logistics');

      await tester.ensureVisible(find.byKey(const Key('addCourseButton')));
      await tester.tap(find.byKey(const Key('addCourseButton')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('courseNameDropdown_0')));
      await tester.tap(find.byKey(const Key('courseNameDropdown_0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Higher Command Course').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('courseYearField_0')), '2015');

      await tester.ensureVisible(find.byKey(const Key('addAwardButton')));
      await tester.tap(find.byKey(const Key('addAwardButton')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('honoursCategoryDropdown_0')));
      await tester.tap(find.byKey(const Key('honoursCategoryDropdown_0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('National Gallantry & Valour').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('honoursDropdown_0')));
      await tester.tap(find.byKey(const Key('honoursDropdown_0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vir Chakra (VrC)').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('honoursYearField_0')), '2012');
      await tester.enterText(find.byKey(const Key('honoursBarField_0')), 'Bar');
      await tester.enterText(find.byKey(const Key('honoursCitationField_0')), 'For gallantry in J&K.');

      await tester.ensureVisible(find.byKey(const Key('buildCvButton')));
      await tester.tap(find.byKey(const Key('buildCvButton')));
      await tester.pumpAndSettle();

      expect(sentIntake, isNotNull);
      expect(sentIntake!.workExperience.single.roleTitle, 'Operations Manager');
      expect(sentIntake!.skills, 'Leadership, Logistics');
      expect(sentIntake!.courses.single.name, 'Higher Command Course');
      expect(sentIntake!.courses.single.year, '2015');
      expect(sentIntake!.honoursAwards.single.name, 'Vir Chakra (VrC)');
      expect(sentIntake!.honoursAwards.single.year, '2012');
      expect(sentIntake!.honoursAwards.single.bar, 'Bar');
      expect(sentIntake!.honoursAwards.single.citation, 'For gallantry in J&K.');
      expect(find.byKey(const Key('builtCvResult')), findsOneWidget);
      expect(repo.lastCvBuilderIntake?.workExperience.single.roleTitle, 'Operations Manager');
      expect(repo.lastBuiltCv, isNotNull);
    });

    testWidgets('resumes from a cached intake and shows the cached result immediately',
        (tester) async {
      _setTallViewport(tester);
      final repo = ProfileRepository();
      await repo.saveCvBuilderIntake(
        const CvBuilderIntake(
          workExperience: [
            WorkExperienceEntry(
              roleTitle: 'Logistics Head',
              organizationType: 'Supply unit',
              duration: '2015-2020',
              responsibilities: 'Ran the supply chain.',
            ),
          ],
        ),
      );
      await repo.saveBuiltCv(const BuiltCv(cvText: 'Previously built CV text.'));

      var called = false;
      await tester.pumpWidget(
        _wrap(
          repo,
          buildCv: ({required intake}) {
            called = true;
            return mockBuildCv(intake: intake);
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(called, isFalse);
      expect(find.text('Logistics Head'), findsOneWidget);
      expect(find.text('Previously built CV text.'), findsOneWidget);
    });

    testWidgets('tapping copy shows a confirmation snackbar', (tester) async {
      _setTallViewport(tester);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async => null,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      final repo = ProfileRepository();
      await repo.saveBuiltCv(const BuiltCv(cvText: 'Text to copy.'));
      await repo.saveCvBuilderIntake(
        const CvBuilderIntake(
          workExperience: [
            WorkExperienceEntry(
              roleTitle: 'Logistics Head',
              organizationType: '',
              duration: '',
              responsibilities: '',
            ),
          ],
        ),
      );

      await tester.pumpWidget(_wrap(repo));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('copyBuiltCvButton')));
      await tester.tap(find.byKey(const Key('copyBuiltCvButton')));
      await tester.pumpAndSettle();

      expect(find.text('CV copied to clipboard'), findsOneWidget);
    });

    testWidgets('shows a download-PDF button alongside copy', (tester) async {
      final repo = ProfileRepository();
      await repo.saveBuiltCv(const BuiltCv(cvText: 'Text to export.'));

      await tester.pumpWidget(_wrap(repo));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('downloadBuiltCvButton')));
      expect(find.byKey(const Key('downloadBuiltCvButton')), findsOneWidget);
    });
  });
}
