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
