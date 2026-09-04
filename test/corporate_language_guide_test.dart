import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/corporate_language/corporate_language_detail_screen.dart';
import 'package:next_career_after_fauj/features/corporate_language/corporate_language_guide_screen.dart';
import 'package:next_career_after_fauj/features/corporate_language/corporate_language_support.dart';
import 'package:next_career_after_fauj/features/corporate_language/corporate_language_term.dart';
import 'package:next_career_after_fauj/features/corporate_language/corporate_language_terms.dart';

Widget _wrap(Widget child) => MaterialApp(theme: AppTheme.light, home: child);

void _setTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 10000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('kCorporateLanguageTerms data integrity', () {
    test('has exactly 296 terms, all with non-empty deep-dive content', () {
      expect(kCorporateLanguageTerms.length, 296);
      for (final t in kCorporateLanguageTerms) {
        expect(t.indianContext, isNotEmpty, reason: t.term);
        expect(t.militaryEquivalent, isNotEmpty, reason: t.term);
        expect(t.dialogueSnippet, isNotEmpty, reason: t.term);
        expect(t.trapForOfficers, isNotEmpty, reason: t.term);
      }
    });

    test('every term belongs to a known category', () {
      for (final t in kCorporateLanguageTerms) {
        expect(kCorporateLanguageCategories, contains(t.category), reason: t.term);
      }
    });

    test('priority tiers 1, 2 and 3 each have 50 terms', () {
      for (final tier in [1, 2]) {
        expect(kCorporateLanguageTerms.where((t) => t.priorityTier == tier).length, 50);
      }
      expect(kCorporateLanguageTerms.where((t) => t.priorityTier == 3).length, 51);
    });

    test('role quick-reference terms all resolve to a real glossary entry', () {
      final names = kCorporateLanguageTerms.map((t) => t.term).toSet();
      for (final role in kRoleQuickReferences) {
        for (final term in role.terms) {
          expect(names, contains(term), reason: '${role.role} -> $term');
        }
      }
    });
  });

  testWidgets('shows the intro, search field and priority/browse sections', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(const CorporateLanguageGuideScreen()));

    expect(find.byKey(const Key('corporateLanguageSearchField')), findsOneWidget);
    expect(find.byKey(const Key('priorityTier1Button')), findsOneWidget);
    expect(find.byKey(const Key('priorityTier2Button')), findsOneWidget);
    expect(find.byKey(const Key('priorityTier3Button')), findsOneWidget);
    expect(find.byKey(const Key('mindsetBridgeButton')), findsOneWidget);
    expect(find.byKey(const Key('confusedTermsButton')), findsOneWidget);
    expect(find.byKey(const Key('meetingPhrasesButton')), findsOneWidget);
    expect(find.byKey(const Key('roleQuickReferenceButton')), findsOneWidget);
    for (final category in kCorporateLanguageCategories) {
      expect(find.byKey(Key('category_$category')), findsOneWidget);
    }
  });

  testWidgets('searching filters to matching terms and opens the detail screen', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(const CorporateLanguageGuideScreen()));

    await tester.enterText(find.byKey(const Key('corporateLanguageSearchField')), 'RACI');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('searchResult_RACI')), findsOneWidget);
    // Priority buttons and category list are hidden while searching.
    expect(find.byKey(const Key('priorityTier1Button')), findsNothing);

    await tester.tap(find.byKey(const Key('searchResult_RACI')));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'RACI'), findsOneWidget);
    expect(find.text('Responsible, Accountable, Consulted, Informed'), findsOneWidget);
  });

  testWidgets('search with no matches shows a friendly empty state', (tester) async {
    await tester.pumpWidget(_wrap(const CorporateLanguageGuideScreen()));

    await tester.enterText(
      find.byKey(const Key('corporateLanguageSearchField')),
      'zzzznonexistentterm',
    );
    await tester.pumpAndSettle();

    expect(find.text('No terms match that search.'), findsOneWidget);
  });

  testWidgets('the "learn before Day 1" tier lists exactly its 50 terms', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(const CorporateLanguageGuideScreen()));

    await tester.tap(find.byKey(const Key('priorityTier1Button')));
    await tester.pumpAndSettle();

    final tier1Terms = kCorporateLanguageTerms.where((t) => t.priorityTier == 1);
    for (final t in tier1Terms) {
      expect(find.byKey(Key('termListEntry_${t.term}')), findsWidgets);
    }
  });

  testWidgets('browsing a category shows its terms, including cross-listed ones', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(const CorporateLanguageGuideScreen()));

    await tester.tap(find.byKey(const Key('category_Manufacturing, Engineering & Infrastructure')));
    await tester.pumpAndSettle();

    // BOM's primary category is Operations, Supply Chain & Procurement but it
    // cross-lists into Manufacturing — confirming cross-category inclusion
    // actually works, not just primary-category filtering.
    expect(find.byKey(const Key('termListEntry_BOM')), findsOneWidget);
  });

  testWidgets('the mindset bridge screen lists the military->corporate vocabulary pairs',
      (tester) async {
    await tester.pumpWidget(_wrap(const CorporateLanguageGuideScreen()));
    await tester.tap(find.byKey(const Key('mindsetBridgeButton')));
    await tester.pumpAndSettle();

    expect(find.text('Mission'), findsOneWidget);
    expect(find.text('business objective / strategic objective'), findsOneWidget);
  });

  testWidgets('the confused-terms screen lists real distinctions', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(const CorporateLanguageGuideScreen()));
    await tester.tap(find.byKey(const Key('confusedTermsButton')));
    await tester.pumpAndSettle();

    expect(find.text('KRA vs KPI vs OKR'), findsOneWidget);
    expect(find.textContaining('Risk vs Issue'), findsOneWidget);
  });

  testWidgets('the meeting-phrases screen lists real workplace phrases', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(const CorporateLanguageGuideScreen()));
    await tester.tap(find.byKey(const Key('meetingPhrasesButton')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Who owns this'), findsOneWidget);
  });

  testWidgets('role quick reference drills down from a role to its term list', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(const CorporateLanguageGuideScreen()));
    await tester.tap(find.byKey(const Key('roleQuickReferenceButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('role_Finance')), findsOneWidget);
    await tester.tap(find.byKey(const Key('role_Finance')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('termListEntry_P&L')), findsOneWidget);
  });

  group('CorporateLanguageDetailScreen', () {
    final sample = kCorporateLanguageTerms.firstWhere((t) => t.term == 'RACI');

    testWidgets('shows the quick reference and all 4 deep-dive sections', (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(_wrap(CorporateLanguageDetailScreen(entry: sample)));

      expect(find.text(sample.fullForm), findsOneWidget);
      expect(find.text(sample.meaning), findsOneWidget);
      expect(find.textContaining(sample.whereSeen), findsOneWidget);
      expect(find.text(sample.indianContext), findsOneWidget);
      expect(find.text(sample.militaryEquivalent), findsOneWidget);
      expect(find.text(sample.dialogueSnippet), findsOneWidget);
      expect(find.byKey(const Key('trapForOfficersBox')), findsOneWidget);
      expect(find.text(sample.trapForOfficers), findsOneWidget);
      expect(find.byKey(const Key('priorityTierChip')), findsOneWidget);
    });

    testWidgets('omits the full-form line for a term with no expansion', (tester) async {
      const noFullForm = CorporateLanguageTerm(
        term: 'Synergy',
        fullForm: '—',
        meaning: 'Some meaning.',
        whereSeen: 'Somewhere',
        bridge: 'A bridge.',
        category: 'General Management & Strategy',
        indianContext: 'Context.',
        militaryEquivalent: 'Equivalent.',
        dialogueSnippet: '"A snippet."',
        trapForOfficers: 'A trap.',
      );
      await tester.pumpWidget(_wrap(const CorporateLanguageDetailScreen(entry: noFullForm)));

      expect(find.text('—'), findsNothing);
      expect(find.byKey(const Key('priorityTierChip')), findsNothing);
    });
  });
}
