import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/business_etiquette/business_etiquette_screen.dart';
import 'package:next_career_after_fauj/features/business_etiquette/business_etiquette_sections.dart';

Widget _wrap(Widget child) => MaterialApp(theme: AppTheme.light, home: child);

void _setTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 8000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('kBusinessEtiquetteSections data integrity', () {
    test('has exactly 22 sections with unique titles', () {
      expect(kBusinessEtiquetteSections.length, 22);
      final titles = kBusinessEtiquetteSections.map((s) => s.title).toSet();
      expect(titles.length, kBusinessEtiquetteSections.length);
    });

    test('every section has content in at least one of its shape fields', () {
      for (final s in kBusinessEtiquetteSections) {
        final hasContent = s.paragraphs.isNotEmpty ||
            s.scenarios.isNotEmpty ||
            s.referenceTable != null ||
            s.translations.isNotEmpty ||
            s.checklistItems.isNotEmpty;
        expect(hasContent, isTrue, reason: s.title);
      }
    });

    test('every scenario has non-empty situation, recommended response and avoid', () {
      for (final s in kBusinessEtiquetteSections) {
        for (final scenario in s.scenarios) {
          expect(scenario.situation, isNotEmpty, reason: s.title);
          expect(scenario.recommendedResponse, isNotEmpty, reason: s.title);
          expect(scenario.avoid, isNotEmpty, reason: s.title);
        }
      }
    });

    test('the two newly-authored sections are present', () {
      final titles = kBusinessEtiquetteSections.map((s) => s.title).toSet();
      expect(titles.any((t) => t.contains('Statutory Boundaries')), isTrue);
      expect(titles.any((t) => t.contains('Body Language & Vocal Presence')), isTrue);
    });
  });

  testWidgets('shows the intro and every section title', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(const BusinessEtiquetteScreen()));

    expect(find.widgetWithText(AppBar, 'Business Etiquette & Professional Conduct'), findsOneWidget);
    for (final section in kBusinessEtiquetteSections) {
      expect(find.byKey(Key('businessEtiquetteEntry_${section.title}')), findsOneWidget);
    }
  });

  testWidgets('tapping a section with scenarios opens its detail screen', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(const BusinessEtiquetteScreen()));

    final section = kBusinessEtiquetteSections.firstWhere((s) => s.title.contains('Addressing People'));
    await tester.tap(find.byKey(Key('businessEtiquetteEntry_${section.title}')));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, section.title), findsOneWidget);
    expect(find.text(section.scenarios.first.situation), findsOneWidget);
    expect(find.text(section.scenarios.first.whatYouMayEncounter!), findsOneWidget);
    expect(find.text(section.scenarios.first.recommendedResponse), findsOneWidget);
    expect(find.text(section.scenarios.first.avoid), findsOneWidget);
  });

  testWidgets('the practical phrases section renders both sides of each translation', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(const BusinessEtiquetteScreen()));

    final section = kBusinessEtiquetteSections.firstWhere((s) => s.title.contains('Practical Phrases'));
    await tester.tap(find.byKey(Key('businessEtiquetteEntry_${section.title}')));
    await tester.pumpAndSettle();

    final first = section.translations.first;
    expect(find.text('"${first.from}"'), findsOneWidget);
    expect(find.textContaining(first.to), findsOneWidget);
  });

  testWidgets('the professional conduct test section renders its checklist', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(const BusinessEtiquetteScreen()));

    final section =
        kBusinessEtiquetteSections.firstWhere((s) => s.title.contains('Professional Conduct Test'));
    await tester.tap(find.byKey(Key('businessEtiquetteEntry_${section.title}')));
    await tester.pumpAndSettle();

    for (final item in section.checklistItems) {
      await tester.scrollUntilVisible(find.text(item), 500);
      expect(find.text(item), findsOneWidget);
    }
  });

  testWidgets('the final reminder section renders its closing note', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(const BusinessEtiquetteScreen()));

    final section =
        kBusinessEtiquetteSections.firstWhere((s) => s.title.contains('Final Reminder'));
    await tester.tap(find.byKey(Key('businessEtiquetteEntry_${section.title}')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('closingNoteBox')), findsOneWidget);
    expect(find.text(section.closingNote!), findsOneWidget);
  });

  testWidgets('the new statutory boundaries section renders its scenarios', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(const BusinessEtiquetteScreen()));

    final section =
        kBusinessEtiquetteSections.firstWhere((s) => s.title.contains('Statutory Boundaries'));
    await tester.tap(find.byKey(Key('businessEtiquetteEntry_${section.title}')));
    await tester.pumpAndSettle();

    expect(find.text(section.paragraphs.first), findsOneWidget);
    for (final scenario in section.scenarios) {
      expect(find.text(scenario.heading!), findsOneWidget);
    }
  });
}
