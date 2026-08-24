import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/services/profile_repository.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/cv_builder/built_cv.dart';
import 'package:next_career_after_fauj/features/cv_builder/cv_builder_intake.dart';
import 'package:next_career_after_fauj/features/cv_builder/cv_builder_screen.dart';
import 'package:next_career_after_fauj/features/cv_builder/cv_builder_service.dart';
import 'package:provider/provider.dart';

Widget _wrap(ProfileRepository repository, {CvBuilder? buildCv}) {
  return ChangeNotifierProvider<ProfileRepository>.value(
    value: repository,
    child: MaterialApp(
      theme: AppTheme.light,
      home: CvBuilderScreen(buildCv: buildCv ?? mockBuildCv),
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
        skills: 'Leadership, Logistics',
      );
      final restored = CvBuilderIntake.fromJson(intake.toJson());
      expect(restored.summary, 'Operations leader.');
      expect(restored.workExperience.single.roleTitle, 'Operations Manager');
      expect(restored.education.single.degree, 'MBA');
      expect(restored.certifications.single.name, 'PMP');
      expect(restored.skills, 'Leadership, Logistics');
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

    testWidgets('adding and removing work experience, education, and certification cards',
        (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(_wrap(ProfileRepository()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('addWorkExperienceButton')));
      await tester.tap(find.byKey(const Key('addEducationButton')));
      await tester.tap(find.byKey(const Key('addCertificationButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('workExperienceCard_1')), findsOneWidget);
      expect(find.byKey(const Key('educationCard_0')), findsOneWidget);
      expect(find.byKey(const Key('certificationCard_0')), findsOneWidget);

      await tester.tap(find.byKey(const Key('removeWorkExperienceButton_1')));
      await tester.tap(find.byKey(const Key('removeEducationButton_0')));
      await tester.tap(find.byKey(const Key('removeCertificationButton_0')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('workExperienceCard_1')), findsNothing);
      expect(find.byKey(const Key('educationCard_0')), findsNothing);
      expect(find.byKey(const Key('certificationCard_0')), findsNothing);
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

      await tester.ensureVisible(find.byKey(const Key('buildCvButton')));
      await tester.tap(find.byKey(const Key('buildCvButton')));
      await tester.pumpAndSettle();

      expect(sentIntake, isNotNull);
      expect(sentIntake!.workExperience.single.roleTitle, 'Operations Manager');
      expect(sentIntake!.skills, 'Leadership, Logistics');
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
  });
}
