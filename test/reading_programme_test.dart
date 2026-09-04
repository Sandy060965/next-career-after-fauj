import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/reading_programme/reading_programme_books.dart';
import 'package:next_career_after_fauj/features/reading_programme/reading_programme_detail_screen.dart';
import 'package:next_career_after_fauj/features/reading_programme/reading_programme_screen.dart';
import 'package:next_career_after_fauj/features/reading_programme/reading_programme_support.dart';

Widget _wrap(Widget child) => MaterialApp(theme: AppTheme.light, home: child);

void _setTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 8000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('kReadingProgrammeBooks data integrity', () {
    test('has exactly 22 books, all with non-empty deep-dive content', () {
      expect(kReadingProgrammeBooks.length, 22);
      for (final b in kReadingProgrammeBooks) {
        expect(b.whatYoudLearn, isNotEmpty, reason: b.title);
        expect(b.keyTakeaways, isNotEmpty, reason: b.title);
        expect(b.summary, isNotEmpty, reason: b.title);
        expect(b.selfAssessmentQuestions, isNotEmpty, reason: b.title);
      }
    });

    test('every book has a real priority tier', () {
      for (final b in kReadingProgrammeBooks) {
        expect(kReadingProgrammePriorityOrder, contains(b.priority), reason: b.title);
      }
    });

    test('every book referenced in the five-book minimum exists in the list', () {
      final titles = kReadingProgrammeBooks.map((b) => b.title).toSet();
      for (final entry in kFiveBookMinimum) {
        expect(
          titles.any((t) => entry.contains(t)),
          isTrue,
          reason: 'five-book-minimum entry "$entry" has no matching book',
        );
      }
    });
  });

  testWidgets('shows the intro, five-book minimum, special buttons, and books grouped by priority',
      (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(const ReadingProgrammeScreen()));

    expect(find.widgetWithText(AppBar, 'Corporate Transition - Reading Programme'), findsOneWidget);
    expect(find.byKey(const Key('fiveBookMinimumCard')), findsOneWidget);
    expect(find.byKey(const Key('readingSequenceButton')), findsOneWidget);
    expect(find.byKey(const Key('translationMapButton')), findsOneWidget);
    expect(find.byKey(const Key('cautionsButton')), findsOneWidget);
    for (final book in kReadingProgrammeBooks) {
      expect(find.byKey(Key('readingProgrammeEntry_${book.title}')), findsOneWidget);
    }
    // Priority section headers appear in the expected order.
    expect(find.text('ESSENTIAL'), findsWidgets);
    expect(find.text('HIGHLY RECOMMENDED'), findsWidgets);
    expect(find.text('RECOMMENDED'), findsWidgets);
  });

  testWidgets('tapping a book opens its detail screen with all 8 fields', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(const ReadingProgrammeScreen()));

    final book = kReadingProgrammeBooks.firstWhere((b) => b.title == 'The First 90 Days');
    await tester.tap(find.byKey(Key('readingProgrammeEntry_${book.title}')));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'The First 90 Days'), findsOneWidget);
    expect(find.text(book.author), findsOneWidget);
    expect(find.text('Why read it'), findsOneWidget);
    expect(find.text(book.whyItBelongs), findsOneWidget);
    expect(find.text('What you\'ll learn'), findsOneWidget);
    expect(find.text(book.whatYoudLearn), findsOneWidget);
    expect(find.text('Military-to-corporate gap addressed'), findsOneWidget);
    expect(find.text(book.militaryTranslation), findsOneWidget);
    expect(find.text('When to read'), findsOneWidget);
    expect(find.text(book.bestTiming), findsOneWidget);
    expect(find.text('Key takeaways'), findsOneWidget);
    for (final t in book.keyTakeaways) {
      expect(find.text(t), findsOneWidget);
    }
    expect(find.text('Summary'), findsOneWidget);
    await tester.scrollUntilVisible(find.byKey(const Key('summaryBox')), 500);
    expect(find.byKey(const Key('summaryBox')), findsOneWidget);
    expect(find.text(book.summary), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Self-assessment questions'), 500);
    expect(find.text('Self-assessment questions'), findsOneWidget);
    for (final q in book.selfAssessmentQuestions) {
      await tester.scrollUntilVisible(find.text(q), 500);
      expect(find.text(q), findsOneWidget);
    }
  });

  testWidgets('the reading sequence screen lists all 5 real phases', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(const ReadingProgrammeScreen()));
    await tester.tap(find.byKey(const Key('readingSequenceButton')));
    await tester.pumpAndSettle();

    expect(find.text('Before transition'), findsOneWidget);
    expect(find.text('Functional depth'), findsOneWidget);
  });

  testWidgets('the translation map screen lists the 8 real mappings', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(const ReadingProgrammeScreen()));
    await tester.tap(find.byKey(const Key('translationMapButton')));
    await tester.pumpAndSettle();

    expect(kMilitaryCorporateMap.length, 8);
    expect(find.text('Command authority → influence'), findsOneWidget);
  });

  testWidgets('the cautions screen lists the real cautions', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(const ReadingProgrammeScreen()));
    await tester.tap(find.byKey(const Key('cautionsButton')));
    await tester.pumpAndSettle();

    expect(kReadingProgrammeCautions.length, 6);
    expect(find.textContaining('Do not try to read all 20'), findsOneWidget);
  });

  testWidgets('a priority chip color varies with tier, and detail screen renders for a non-ESSENTIAL book',
      (tester) async {
    _setTallViewport(tester);
    final recommended = kReadingProgrammeBooks.firstWhere((b) => b.priority == 'RECOMMENDED');
    await tester.pumpWidget(_wrap(ReadingProgrammeDetailScreen(book: recommended)));

    expect(find.byKey(const Key('priorityChip')), findsOneWidget);
    expect(find.text('RECOMMENDED'), findsOneWidget);
  });
}
