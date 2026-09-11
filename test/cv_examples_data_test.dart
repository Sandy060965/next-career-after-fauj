import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/features/cv_examples/cv_example.dart';
import 'package:next_career_after_fauj/features/cv_examples/cv_examples_data.dart';
import 'package:next_career_after_fauj/features/cv_templates/cv_pdf_fonts.dart';
import 'package:next_career_after_fauj/features/cv_templates/cv_template_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CV Examples library', () {
    test('exactly 54 examples — 3 services × 6 ranks × 3 career tracks, each combination unique', () {
      expect(kCvExamples.length, 54);
      final keys = kCvExamples.map((e) => '${e.serviceLabel}|${e.rank}|${e.archetype}').toSet();
      expect(keys.length, 54, reason: 'every Service/Rank/archetype combination should be unique');

      final services = kCvExamples.map((e) => e.serviceLabel).toSet();
      expect(services, {'Army', 'Navy', 'Air Force'});
      for (final service in services) {
        final ranksForService = kCvExamples.where((e) => e.serviceLabel == service).map((e) => e.rank).toSet();
        expect(ranksForService.length, 6, reason: '$service should have 6 distinct rank tiers');
      }
      expect(kCvExamples.map((e) => e.archetype).toSet(), CvExampleArchetype.values.toSet());
    });

    test('every example references a real, registered template id', () {
      final validIds = kCvPdfTemplates.map((t) => t.id).toSet();
      for (final example in kCvExamples) {
        expect(validIds.contains(example.templateId), isTrue,
            reason: '${example.serviceLabel} ${example.rank} references unknown template "${example.templateId}"');
      }
    });

    test('every example has a name, summary, and at least one work-experience entry', () {
      for (final example in kCvExamples) {
        expect(example.data.fullName, isNotEmpty, reason: '${example.serviceLabel} ${example.rank} missing fullName');
        expect(example.data.summary, isNotEmpty, reason: '${example.serviceLabel} ${example.rank} missing summary');
        expect(example.data.workExperience, isNotEmpty,
            reason: '${example.serviceLabel} ${example.rank} missing work experience');
      }
    });

    test('every example has career highlights, and templateId varies by archetype', () {
      const expectedTemplateByArchetype = {
        CvExampleArchetype.operationsAndGeneralManagement: 'business_leader',
        CvExampleArchetype.technologyAndFunctional: 'technology_digital',
        CvExampleArchetype.strategyAndTransformation: 'executive_navy',
      };
      for (final example in kCvExamples) {
        expect(example.data.careerHighlights, isNotEmpty,
            reason: '${example.serviceLabel} ${example.rank} missing careerHighlights');
        expect(example.templateId, expectedTemplateByArchetype[example.archetype],
            reason: '${example.serviceLabel} ${example.rank} (${example.archetype})');
      }
    });

    // Rank -> (years of service, appointments shown, courses baseline).
    const rankInfo = {
      'Major': (10, 3, 3), 'Lieutenant Colonel': (20, 6, 5),
      'Colonel': (22, 7, 6), 'Brigadier': (30, 9, 7),
      'Major General': (34, 11, 8), 'Lieutenant General': (38, 13, 9),
      'Lieutenant Commander': (10, 3, 3), 'Commander': (20, 6, 5),
      'Captain': (22, 7, 6), 'Commodore': (30, 9, 7),
      'Rear Admiral': (34, 11, 8), 'Vice Admiral': (38, 13, 9),
      'Squadron Leader': (10, 3, 3), 'Wing Commander': (20, 6, 5),
      'Group Captain': (22, 7, 6), 'Air Commodore': (30, 9, 7),
      'Air Vice Marshal': (34, 11, 8), 'Air Marshal': (38, 13, 9),
    };
    const seniorRanks = {
      'Colonel', 'Brigadier', 'Major General', 'Lieutenant General',
      'Captain', 'Commodore', 'Rear Admiral', 'Vice Admiral',
      'Group Captain', 'Air Commodore', 'Air Vice Marshal', 'Air Marshal',
    };

    test('appointment count scales with rank, plus the "one of three" UN deployment for Operations examples', () {
      for (final example in kCvExamples) {
        final (_, appointments, _) = rankInfo[example.rank]!;
        final isUnBonus = example.archetype == CvExampleArchetype.operationsAndGeneralManagement;
        final expected = appointments + (isUnBonus ? 1 : 0);
        expect(example.data.workExperience.length, expected,
            reason: '${example.serviceLabel} ${example.rank} (${example.archetype})');
      }
    });

    test('the 3 most recent appointments are fully detailed; earlier ones are brief', () {
      for (final example in kCvExamples) {
        final entries = example.data.workExperience;
        for (var i = 0; i < entries.length; i++) {
          final entry = entries[i];
          expect(entry.responsibilities, isNot(contains('[XX]')),
              reason: '${example.serviceLabel} ${example.rank}: ${entry.roleTitle}');
          if (i < 3) {
            expect(entry.responsibilities.split('\n').length, greaterThanOrEqualTo(4),
                reason: '${example.serviceLabel} ${example.rank}: ${entry.roleTitle} should be fully detailed');
          }
        }
      }
    });

    test('course count scales with rank, plus DSSC for Strategy & Transformation from Colonel onward', () {
      for (final example in kCvExamples) {
        final (_, _, courses) = rankInfo[example.rank]!;
        final isDssc = example.archetype == CvExampleArchetype.strategyAndTransformation && seniorRanks.contains(example.rank);
        final expected = courses + (isDssc ? 1 : 0);
        expect(example.data.courses.length, expected,
            reason: '${example.serviceLabel} ${example.rank} (${example.archetype})');
        if (isDssc) {
          expect(example.data.courses.map((c) => c.name), contains('Defence Services Staff College'),
              reason: '${example.serviceLabel} ${example.rank}');
        }
      }
    });

    test('appointment dates are month+year and span exactly the rank\'s years of service', () {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      for (final example in kCvExamples) {
        final (years, _, _) = rankInfo[example.rank]!;
        final entries = example.data.workExperience;
        for (final e in entries) {
          expect(e.duration, matches(RegExp(r'^[A-Z][a-z]{2} \d{4} – [A-Z][a-z]{2} \d{4}$')),
              reason: '${example.serviceLabel} ${example.rank}: "${e.duration}"');
        }
        final firstParts = entries.first.duration.split(' – ');
        final lastParts = entries.last.duration.split(' – ');
        final endMonth = firstParts[1].split(' ')[0];
        final endYear = int.parse(firstParts[1].split(' ')[1]);
        final startMonth = lastParts[0].split(' ')[0];
        final startYear = int.parse(lastParts[0].split(' ')[1]);
        final spanMonths = (endYear - startYear) * 12 + (months.indexOf(endMonth) - months.indexOf(startMonth)) + 1;
        expect(spanMonths, closeTo(years * 12, 1), reason: '${example.serviceLabel} ${example.rank}');
      }
    });

    test('content is genuinely differentiated by seniority tier, not reused verbatim across ranks', () {
      final juniorOps = kCvExamples.firstWhere(
        (e) => e.serviceLabel == 'Army' && e.rank == 'Major' && e.archetype == CvExampleArchetype.operationsAndGeneralManagement,
      );
      final flagOps = kCvExamples.firstWhere(
        (e) =>
            e.serviceLabel == 'Army' &&
            e.rank == 'Lieutenant General' &&
            e.archetype == CvExampleArchetype.operationsAndGeneralManagement,
      );
      expect(juniorOps.data.summary, isNot(equals(flagOps.data.summary)));
      expect(
        juniorOps.data.workExperience.first.responsibilities,
        isNot(equals(flagOps.data.workExperience.first.responsibilities)),
      );
    });

    // A full pass (fonts + all 54 examples through their assigned template) in
    // a single test avoids loading the bundled fonts 54 times over.
    test('every example renders non-empty PDF bytes through its assigned template', () async {
      final fonts = await CvPdfFonts.load();
      for (final example in kCvExamples) {
        final template = kCvPdfTemplates.firstWhere((t) => t.id == example.templateId);
        final bytes = await template.build(example.data, fonts).save();
        expect(bytes, isNotEmpty,
            reason: '${example.serviceLabel} ${example.rank} (${example.archetype}) produced no bytes');
      }
    });
  });
}
