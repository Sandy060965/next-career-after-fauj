import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/corporate_culture/corporate_culture_screen.dart';
import 'package:next_career_after_fauj/features/corporate_culture/corporate_culture_sections.dart';

Widget _wrap(Widget child) => MaterialApp(theme: AppTheme.light, home: child);

void _setTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 8000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('kCorporateCultureSections data integrity', () {
    test('has exactly 20 sections with unique titles', () {
      expect(kCorporateCultureSections.length, 20);
      final titles = kCorporateCultureSections.map((s) => s.title).toSet();
      expect(titles.length, kCorporateCultureSections.length);
    });

    test('every section has content in at least one of its shape fields', () {
      for (final s in kCorporateCultureSections) {
        final hasContent = s.paragraphs.isNotEmpty ||
            s.scenarios.isNotEmpty ||
            s.referenceTable != null ||
            s.translations.isNotEmpty ||
            s.checklistItems.isNotEmpty;
        expect(hasContent, isTrue, reason: s.title);
      }
    });

    test('every scenario has non-empty situation, recommended response and avoid', () {
      for (final s in kCorporateCultureSections) {
        for (final scenario in s.scenarios) {
          expect(scenario.situation, isNotEmpty, reason: s.title);
          expect(scenario.recommendedResponse, isNotEmpty, reason: s.title);
          expect(scenario.avoid, isNotEmpty, reason: s.title);
        }
      }
    });

    test('every reference table row matches its column count', () {
      for (final s in kCorporateCultureSections) {
        final table = s.referenceTable;
        if (table == null) continue;
        for (final row in table.rows) {
          expect(row.length, table.columnHeaders.length, reason: s.title);
        }
      }
    });

    test('the two newly-authored sections are present', () {
      final titles = kCorporateCultureSections.map((s) => s.title).toSet();
      expect(
        titles.any((t) => t.contains('Support Ecosystem')),
        isTrue,
      );
      expect(
        titles.any((t) => t.contains('Individual Contributor Before Manager')),
        isTrue,
      );
    });
  });

  testWidgets('shows the intro and every section title', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(const CorporateCultureScreen()));

    expect(find.widgetWithText(AppBar, 'Corporate Culture & Work Environment'), findsOneWidget);
    for (final section in kCorporateCultureSections) {
      expect(find.byKey(Key('corporateCultureEntry_${section.title}')), findsOneWidget);
    }
  });

  testWidgets('tapping a section with scenarios opens its detail screen', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(const CorporateCultureScreen()));

    final section = kCorporateCultureSections
        .firstWhere((s) => s.title.contains('Rank Usually Does Not Travel'));
    await tester.tap(find.byKey(Key('corporateCultureEntry_${section.title}')));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, section.title), findsOneWidget);
    expect(find.text(section.scenarios.first.situation), findsOneWidget);
    expect(find.text(section.scenarios.first.recommendedResponse), findsOneWidget);
    expect(find.text(section.scenarios.first.avoid), findsOneWidget);
  });

  testWidgets('a section with a reference table renders its headers', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(const CorporateCultureScreen()));

    final section = kCorporateCultureSections.firstWhere((s) => s.title.contains('First Mental Shift'));
    await tester.tap(find.byKey(Key('corporateCultureEntry_${section.title}')));
    await tester.pumpAndSettle();

    for (final header in section.referenceTable!.columnHeaders) {
      expect(find.text(header), findsOneWidget);
    }
  });

  testWidgets('a section with translations renders both sides of each pair', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(const CorporateCultureScreen()));

    final section = kCorporateCultureSections.firstWhere((s) => s.title.contains('From Command to Influence'));
    await tester.tap(find.byKey(Key('corporateCultureEntry_${section.title}')));
    await tester.pumpAndSettle();

    final first = section.translations.first;
    expect(find.text('"${first.from}"'), findsOneWidget);
    expect(find.textContaining(first.to), findsOneWidget);
  });

  testWidgets('a section with a closing note renders it', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(const CorporateCultureScreen()));

    final section = kCorporateCultureSections.firstWhere((s) => s.closingNote != null);
    await tester.tap(find.byKey(Key('corporateCultureEntry_${section.title}')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('closingNoteBox')), findsOneWidget);
    expect(find.text(section.closingNote!), findsOneWidget);
  });
}
