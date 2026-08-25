import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/services/profile_repository.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/career_paths/career_paths_screen.dart';
import 'package:next_career_after_fauj/features/vertical_fit/aptitude_question.dart';
import 'package:next_career_after_fauj/features/vertical_fit/vertical_fit.dart';
import 'package:next_career_after_fauj/features/vertical_fit/vertical_fit_quiz_screen.dart';
import 'package:provider/provider.dart';

Widget _wrap(Widget child, {ProfileRepository? repository}) {
  return ChangeNotifierProvider<ProfileRepository>.value(
    value: repository ?? ProfileRepository(),
    child: MaterialApp(theme: AppTheme.light, home: child),
  );
}

void main() {
  group('VerticalFitQuizScreen', () {
    testWidgets('shows all eleven dimensions and all 33 questions, defaulting to rating 3',
        (tester) async {
      await tester.pumpWidget(_wrap(const VerticalFitQuizScreen()));

      expect(find.text('Interests'), findsOneWidget);
      expect(find.text('Work Style'), findsOneWidget);
      for (final dimension in AptitudeDimension.values) {
        expect(find.text(dimension.label), findsWidgets);
      }
      expect(find.byType(SegmentedButton<int>), findsNWidgets(kAptitudeQuestions.length));
      expect(find.byKey(const Key('submitVerticalFitButton')), findsOneWidget);
    });

    testWidgets('submitting navigates to the result screen with 3 recommended verticals',
        (tester) async {
      tester.view.physicalSize = const Size(430, 4600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(const VerticalFitQuizScreen()));
      await tester.ensureVisible(find.byKey(const Key('submitVerticalFitButton')));
      await tester.tap(find.byKey(const Key('submitVerticalFitButton')));
      await tester.pumpAndSettle();

      expect(find.text('Your top 3 verticals'), findsOneWidget);
      // All ratings default to 3 -> every dimension scores (3/5)*100 = 60.
      expect(find.text('60'), findsWidgets);

      final cardFinder = find.byWidgetPredicate((w) => w.key is ValueKey<String> &&
          (w.key as ValueKey<String>).value.toString().startsWith('verticalFit_'));
      await tester.scrollUntilVisible(cardFinder.last, 300);
      expect(cardFinder, findsNWidgets(3));
    });
  });

  group('VerticalFit.confidence', () {
    test('high confidence when contributing dimension scores agree closely', () {
      final scores = {for (final d in AptitudeDimension.values) d: 50}
        ..addAll({
          AptitudeDimension.investigative: 80,
          AptitudeDimension.openness: 85,
          AptitudeDimension.conventional: 75,
        });
      final fit =
          rankVerticalFit(scores).firstWhere((f) => f.vertical.name == 'Tech Product & Data Operations');
      expect(fit.confidence(scores), FitConfidence.high);
    });

    test('medium confidence for a moderate spread', () {
      final scores = {for (final d in AptitudeDimension.values) d: 50}
        ..addAll({
          AptitudeDimension.investigative: 80,
          AptitudeDimension.openness: 60,
          AptitudeDimension.conventional: 55,
        });
      final fit =
          rankVerticalFit(scores).firstWhere((f) => f.vertical.name == 'Tech Product & Data Operations');
      expect(fit.confidence(scores), FitConfidence.medium);
    });

    test('low confidence when contributing dimension scores disagree sharply', () {
      final scores = {for (final d in AptitudeDimension.values) d: 50}
        ..addAll({
          AptitudeDimension.investigative: 100,
          AptitudeDimension.openness: 20,
          AptitudeDimension.conventional: 60,
        });
      final fit =
          rankVerticalFit(scores).firstWhere((f) => f.vertical.name == 'Tech Product & Data Operations');
      expect(fit.confidence(scores), FitConfidence.low);
    });
  });

  group('CareerPathsScreen recommendations', () {
    testWidgets('badges and sorts recommended verticals to the top', (tester) async {
      await tester.pumpWidget(
        _wrap(const CareerPathsScreen(recommendedVerticals: {'IT Infrastructure & Cybersecurity'})),
      );

      expect(find.byKey(const Key('recommendedVerticalBadge')), findsOneWidget);

      // Recommended vertical should be sorted above a non-recommended one
      // that would otherwise come first in the fixed taxonomy order.
      final recommendedY = tester.getTopLeft(find.text('IT Infrastructure & Cybersecurity')).dy;
      final otherY = tester.getTopLeft(find.text('Operations & Process Excellence')).dy;
      expect(recommendedY, lessThan(otherY));
    });

    testWidgets('shows no badge when no verticals are recommended', (tester) async {
      await tester.pumpWidget(_wrap(const CareerPathsScreen()));
      expect(find.byKey(const Key('recommendedVerticalBadge')), findsNothing);
    });
  });
}
