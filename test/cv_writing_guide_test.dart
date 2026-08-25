import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/cv_writing_guide/cv_template.dart';
import 'package:next_career_after_fauj/features/cv_writing_guide/cv_writing_guide_screen.dart';
import 'package:next_career_after_fauj/features/cv_writing_guide/template_sharer.dart';

void _setTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 8000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('lists all six templates with a download action each', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: CvWritingGuideScreen(shareTemplate: (_) async {})),
    );

    expect(kCvTemplates.length, 6);
    for (final template in kCvTemplates) {
      expect(find.byKey(ValueKey('cvTemplate_${template.name}')), findsOneWidget);
      expect(find.byKey(ValueKey('downloadTemplate_${template.name}')), findsOneWidget);
    }
  });

  testWidgets('tapping download invokes the injected sharer for that template', (tester) async {
    _setTallViewport(tester);
    final shared = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: CvWritingGuideScreen(
          shareTemplate: (template) async {
            shared.add(template.name);
          },
        ),
      ),
    );

    final target = kCvTemplates[2]; // Executive Leadership
    await tester.ensureVisible(find.byKey(ValueKey('downloadTemplate_${target.name}')));
    await tester.tap(find.byKey(ValueKey('downloadTemplate_${target.name}')));
    await tester.pumpAndSettle();

    expect(shared, [target.name]);
  });

  testWidgets('a sharer failure shows an error instead of failing silently', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: CvWritingGuideScreen(
          shareTemplate: (_) async => throw Exception('no share sheet available'),
        ),
      ),
    );

    final target = kCvTemplates.first;
    await tester.ensureVisible(find.byKey(ValueKey('downloadTemplate_${target.name}')));
    await tester.tap(find.byKey(ValueKey('downloadTemplate_${target.name}')));
    await tester.pumpAndSettle();

    expect(find.textContaining("Couldn't open the share sheet"), findsOneWidget);
  });

  testWidgets('shows the CV structure guidance and the writing guidelines', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: CvWritingGuideScreen(shareTemplate: (_) async {})),
    );

    // Structure section headings.
    for (final heading in [
      'Header',
      'Target Role / Professional Summary',
      'Core Skills',
      'Professional Experience',
      'Education',
      'Certifications',
      'Languages',
    ]) {
      expect(find.byKey(ValueKey('cvStructure_$heading')), findsOneWidget);
    }

    // A representative sample of the guideline titles the user specifically
    // asked for — defence jargon, challenges, KPI-based achievements.
    for (final title in [
      'Never use defence abbreviations or jargon',
      'Never include ACR, classified, or unit-identifying content',
      'Describe challenges, not just duties',
      'Quantify achievements — build a real KPI-based achievement matrix',
      'State designation and exact dates for every role',
      'List qualifications, certifications, and languages clearly',
    ]) {
      await tester.scrollUntilVisible(find.byKey(ValueKey('cvGuideline_$title')), 300);
      expect(find.byKey(ValueKey('cvGuideline_$title')), findsOneWidget);
    }
  });

  test('every template asset path is unique and points under assets/cv_templates/', () {
    final paths = kCvTemplates.map((t) => t.assetPath).toSet();
    expect(paths.length, kCvTemplates.length);
    for (final template in kCvTemplates) {
      expect(template.assetPath, startsWith('assets/cv_templates/'));
      expect(template.assetPath, endsWith('.docx'));
    }
  });

  test('shareTemplateFile loads the bundled asset bytes for every template', () async {
    // Exercises the real (non-injected) implementation up to the platform
    // share-sheet call, which isn't mocked in a test environment — that
    // final MissingPluginException is expected and is NOT what this test
    // is checking. What matters is that every asset path actually resolves
    // to real bundled bytes first (rootBundle.load would throw a distinct,
    // clear "unable to load asset" error if a path were wrong).
    for (final template in kCvTemplates) {
      try {
        await shareTemplateFile(template);
      } catch (e) {
        expect(
          '$e',
          isNot(contains('Unable to load asset')),
          reason: 'asset path for ${template.name} should resolve to a real bundled file',
        );
      }
    }
  });
}
