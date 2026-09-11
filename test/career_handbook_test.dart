import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/career_handbook/career_handbook_detail_screen.dart';
import 'package:next_career_after_fauj/features/career_handbook/career_handbook_screen.dart';
import 'package:next_career_after_fauj/features/career_handbook/career_handbook_entries.dart';
import 'package:next_career_after_fauj/features/career_paths/career_vertical.dart';
import 'package:next_career_after_fauj/features/career_paths/corps_affinity.dart';

Widget _wrap(Widget child) => MaterialApp(theme: AppTheme.light, home: child);

void _setTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 6000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('kCareerHandbookEntries fabrication guards', () {
    test('has exactly one entry per real vertical, matched by exact name', () {
      final entryNames = kCareerHandbookEntries.map((e) => e.verticalName).toSet();
      final realNames = kAllBrowsableVerticals.map((v) => v.name).toSet();
      expect(entryNames, realNames);
      expect(kCareerHandbookEntries.length, kAllBrowsableVerticals.length);
    });

    test('never restates a ladder job title in the narrative fields', () {
      final ladderTitles = kAllBrowsableVerticals.expand((v) => v.levels.map((l) => l.title));
      for (final entry in kCareerHandbookEntries) {
        final blob = [
          entry.whatItDoes,
          entry.careerRoadmap,
          ...entry.whoSucceeds,
          ...entry.whoStruggles,
          entry.whatYoudNeed,
          entry.restrictionNote ?? '',
        ].join(' ');
        for (final title in ladderTitles) {
          expect(
            blob.contains(title),
            isFalse,
            reason: '${entry.verticalName} narrative should not restate ladder title "$title"',
          );
        }
      }
    });

    test('restriction notes are set for exactly the 9 medical + 5 legal verticals', () {
      final restricted = kCareerHandbookEntries.where((e) => e.restrictionNote != null).map((e) => e.verticalName);
      final expectedRestricted = {
        ...kMedicalCareerVerticals.map((v) => v.name),
        ...kLegalCareerVerticals.map((v) => v.name),
      };
      expect(restricted.toSet(), expectedRestricted);
    });

    test('known-fabricated certification claims never reappear', () {
      for (final entry in kCareerHandbookEntries) {
        for (final banned in ['AFIH', 'MD-PSM', 'marine medicine certification']) {
          expect(
            entry.whatYoudNeed.contains(banned),
            isFalse,
            reason: '${entry.verticalName} whatYoudNeed should never contain "$banned"',
          );
        }
      }
    });
  });


  testWidgets('lists all 34 verticals grouped by category, plus the compare and glossary actions',
      (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(const CareerHandbookScreen()));

    for (final vertical in kAllBrowsableVerticals) {
      expect(find.byKey(Key('handbookEntry_${vertical.name}')), findsOneWidget);
    }
    expect(find.byKey(const Key('handbookComparisonTableButton')), findsOneWidget);
    expect(find.byKey(const Key('handbookGlossaryButton')), findsOneWidget);
  });

  testWidgets(
      'the comparison table numbers every row and all 34 are reachable by scrolling '
      '(regression: a horizontal-only ScrollView silently clipped rows past the viewport)',
      (tester) async {
    // Deliberately NOT _setTallViewport here — a viewport tall enough to fit
    // all 34 rows without scrolling is exactly what let the original bug
    // (no vertical scroll wrapper around the DataTable) slip past this test.
    await tester.pumpWidget(_wrap(const CareerHandbookScreen()));
    await tester.scrollUntilVisible(find.byKey(const Key('handbookComparisonTableButton')), 200);
    await tester.tap(find.byKey(const Key('handbookComparisonTableButton')));
    await tester.pumpAndSettle();

    // Row numbering: the first vertical is row "1".
    expect(find.text(kAllBrowsableVerticals.first.name), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    // DataRow keys aren't discoverable via find.byKey (TableRow isn't a
    // Widget), so this checks cell text directly, scrolling as needed to
    // reach rows below the fold — this is the actual regression check.
    for (final vertical in kAllBrowsableVerticals) {
      await tester.scrollUntilVisible(find.text(vertical.name), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text(vertical.name), findsOneWidget);
    }

    // The last vertical is numbered 34.
    expect(find.text('${kAllBrowsableVerticals.length}'), findsOneWidget);

    // Spot check: the 9 medical and 5 JAG verticals are flagged, the rest are not.
    expect(find.text('Medical branches only'), findsNWidgets(9));
    expect(find.text('JAG branch only'), findsNWidgets(5));
    expect(find.text('—'), findsNWidgets(20));
  });

  testWidgets('the glossary button opens the Corporate Language Guide', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(const CareerHandbookScreen()));
    await tester.tap(find.byKey(const Key('handbookGlossaryButton')));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Corporate Language Guide'), findsOneWidget);
  });

  testWidgets('tapping a vertical opens its detail screen', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(const CareerHandbookScreen()));
    await tester.tap(find.byKey(const Key('handbookEntry_IT Infrastructure & Cybersecurity')));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'IT Infrastructure & Cybersecurity'), findsOneWidget);
  });

  group('CareerHandbookDetailScreen', () {
    final generalVertical =
        kCareerVerticals.firstWhere((v) => v.name == 'Operations & Process Excellence');
    final medicalVertical = kMedicalCareerVerticals
        .firstWhere((v) => v.name == 'Clinical Practice & Hospital Administration');

    testWidgets('shows the real ladder titles and bridge certifications, ungated', (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(_wrap(CareerHandbookDetailScreen(vertical: generalVertical)));

      for (final level in generalVertical.levels) {
        final expected =
            'T${level.tier}: ${level.title} (${level.expMin}-${level.expMax == 42 ? '42+' : level.expMax}y)';
        expect(find.text(expected), findsOneWidget);
      }
      expect(find.textContaining('Six Sigma Green/Black Belt'), findsWidgets);
      expect(find.byKey(const Key('handbookRestrictionChip')), findsNothing);
    });

    testWidgets('flags a medical-only vertical with a restriction chip', (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(_wrap(CareerHandbookDetailScreen(vertical: medicalVertical)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('handbookRestrictionChip')), findsOneWidget);
      expect(find.text('Medical branches only'), findsOneWidget);
    });

    testWidgets('links to Career Vertical Fit, Build My Civilian CV and Compensation Guidance',
        (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(_wrap(CareerHandbookDetailScreen(vertical: generalVertical)));

      expect(find.text('Career Vertical Fit'), findsOneWidget);
      expect(find.text('Build My Civilian CV'), findsOneWidget);
      expect(find.text('Compensation Guidance'), findsOneWidget);
    });

    testWidgets('shows up to 3 related verticals from the same category', (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(_wrap(CareerHandbookDetailScreen(vertical: generalVertical)));

      final related = kAllBrowsableVerticals
          .where((v) => v.category == generalVertical.category && v.name != generalVertical.name)
          .take(3);
      for (final r in related) {
        expect(find.byKey(Key('relatedVertical_${r.name}')), findsOneWidget);
      }
    });
  });
}
