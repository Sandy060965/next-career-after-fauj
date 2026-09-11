import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/models/learning_resource.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/learning_resources/learning_resource_detail_screen.dart';
import 'package:next_career_after_fauj/features/learning_resources/learning_resources_data.dart';
import 'package:next_career_after_fauj/features/learning_resources/learning_resources_screen.dart';

Widget _wrap(Widget child) => MaterialApp(theme: AppTheme.light, home: child);

void _setTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 12000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('kLearningResources data integrity', () {
    test('has exactly 77 resources with unique ids', () {
      expect(kLearningResources.length, 77);
      final ids = kLearningResources.map((r) => r.id).toSet();
      expect(ids.length, kLearningResources.length);
    });

    test('every resource has non-empty required fields and a valid URL', () {
      for (final r in kLearningResources) {
        expect(r.name, isNotEmpty, reason: r.id);
        expect(r.provider, isNotEmpty, reason: r.id);
        expect(Uri.tryParse(r.url)?.hasScheme, isTrue, reason: r.id);
        expect(r.tags, isNotEmpty, reason: r.id);
        expect(r.description, isNotEmpty, reason: r.id);
        expect(DateTime.tryParse(r.lastVerified), isNotNull, reason: r.id);
      }
    });

    test('every resource belongs to a known category', () {
      for (final r in kLearningResources) {
        expect(kLearningResourceCategories, contains(r.category), reason: r.id);
      }
    });

    test('every category has at least one resource', () {
      for (final category in kLearningResourceCategories) {
        expect(kLearningResources.where((r) => r.category == category), isNotEmpty, reason: category);
      }
    });

    test('the AI & Generative AI category has meaningful depth', () {
      expect(kLearningResources.where((r) => r.category == 'AI & Generative AI').length,
          greaterThanOrEqualTo(10));
    });
  });

  testWidgets('shows the intro, search field and every category', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(const LearningResourcesScreen()));

    expect(find.byKey(const Key('learningResourcesSearchField')), findsOneWidget);
    for (final category in kLearningResourceCategories) {
      expect(find.byKey(Key('category_$category')), findsOneWidget);
    }
  });

  testWidgets('searching filters by name, provider, description and tag', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(const LearningResourcesScreen()));

    await tester.enterText(find.byKey(const Key('learningResourcesSearchField')), 'power bi');
    await tester.pump();

    expect(find.byKey(const Key('searchResult_ms-learn-power-bi-prepare-visualize')), findsOneWidget);
    expect(find.byKey(const Key('searchResult_openai-academy')), findsNothing);
  });

  testWidgets('browsing a category lists every resource in it and opens a detail screen', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(const LearningResourcesScreen()));

    await tester.tap(find.byKey(const Key('category_Cybersecurity')));
    await tester.pumpAndSettle();

    final cybersecurityResources = kLearningResources.where((r) => r.category == 'Cybersecurity');
    for (final r in cybersecurityResources) {
      expect(find.byKey(Key('resourceListEntry_${r.id}')), findsOneWidget);
    }

    final first = cybersecurityResources.first;
    await tester.tap(find.byKey(Key('resourceListEntry_${first.id}')));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, first.name), findsOneWidget);
    expect(find.text(first.provider), findsOneWidget);
    expect(find.text(first.description), findsOneWidget);
    expect(find.byKey(const Key('openResourceButton')), findsOneWidget);
    expect(find.text('Last verified ${first.lastVerified}'), findsOneWidget);
  });

  testWidgets('a resource with a practical project renders it', (tester) async {
    final resource = kLearningResources.firstWhere((r) => r.practicalProject != null);
    await tester.pumpWidget(_wrap(LearningResourceDetailScreen(resource: resource)));

    expect(find.byKey(const Key('practicalProjectBox')), findsOneWidget);
    expect(find.text(resource.practicalProject!), findsOneWidget);
  });

  testWidgets('cost/type/level chips render for a resource', (tester) async {
    final resource = kLearningResources.first;
    await tester.pumpWidget(_wrap(LearningResourceDetailScreen(resource: resource)));

    expect(find.byKey(const Key('costChip')), findsOneWidget);
    expect(find.text(resource.cost.label), findsOneWidget);
    expect(find.text(resource.resourceType.label), findsOneWidget);
    expect(find.text(resource.level), findsOneWidget);
  });
}
