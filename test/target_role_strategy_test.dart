import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/models/officer_profile.dart';
import 'package:next_career_after_fauj/core/routing/app_routes.dart';
import 'package:next_career_after_fauj/core/services/profile_repository.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/target_role/target_role_service.dart';
import 'package:next_career_after_fauj/features/target_role/target_role_strategy.dart';
import 'package:next_career_after_fauj/features/target_role/target_role_strategy_screen.dart';
import 'package:next_career_after_fauj/features/vertical_fit/aptitude_question.dart';
import 'package:next_career_after_fauj/features/vertical_fit/vertical_fit.dart';
import 'package:provider/provider.dart';

/// Ratings that push investigative, openness, and conventional to a
/// dimension score of 100 and everything else to 20 — 'Tech Product & Data
/// Operations' is the only vertical drawing on exactly those three
/// dimensions, so it comes out uniquely top-ranked.
final _skewedRatings = {
  for (final q in kAptitudeQuestions)
    q.id: (q.dimension == AptitudeDimension.investigative ||
            q.dimension == AptitudeDimension.openness ||
            q.dimension == AptitudeDimension.conventional)
        ? 5
        : 1,
};

OfficerProfile _profile({int workExperienceYears = 22}) => OfficerProfile(
      rank: 'Col',
      fullName: 'Col A Verma',
      dateOfBirth: DateTime(1975, 5, 10),
      workExperienceYears: workExperienceYears,
      workExperienceMonths: 0,
      releaseStatus: ReleaseStatus.tentative,
      releaseDate: DateTime(2027, 6, 30),
      service: OfficerService.army,
      mobileNumber: '9876543210',
      email: 'a.verma@example.com',
      segment: OfficerSegment.pmr,
      cvFileName: 'resume.pdf',
      cvExtractedText: 'Sample CV text',
    );

ProfileRepository _repositoryWithAssessment({int workExperienceYears = 22}) {
  final repo = ProfileRepository()..saveProfile(_profile(workExperienceYears: workExperienceYears));
  repo.saveVerticalFitAssessment(VerticalFitAssessment(ratings: _skewedRatings));
  return repo;
}

Widget _wrap(ProfileRepository repository, {TargetRoleStrategist? generateStrategy}) {
  return ChangeNotifierProvider<ProfileRepository>.value(
    value: repository,
    child: MaterialApp(
      theme: AppTheme.light,
      initialRoute: '/target-role',
      routes: {
        '/target-role': (_) => TargetRoleStrategyScreen(
              generateStrategy: generateStrategy ?? mockGenerateTargetRoleStrategy,
            ),
        AppRoutes.verticalFit: (_) => const Scaffold(body: Text('Vertical Fit quiz screen')),
      },
    ),
  );
}

void _setTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('buildTargetRoleDrafts', () {
    test('ranks the vertical matching the officer\'s strongest dimensions first', () {
      final dimensionScores =
          VerticalFitAssessment(ratings: _skewedRatings).dimensionScores;
      final drafts = buildTargetRoleDrafts(dimensionScores: dimensionScores, workExperienceYears: 22);

      expect(drafts, hasLength(3));
      expect(drafts.first.verticalName, 'Tech Product & Data Operations');
      expect(drafts.first.fitScore, 100);
    });

    test('picks the role title from the experience-based career ladder', () {
      final dimensionScores =
          VerticalFitAssessment(ratings: _skewedRatings).dimensionScores;
      final drafts = buildTargetRoleDrafts(dimensionScores: dimensionScores, workExperienceYears: 22);

      // 22 years falls in the tier-3 band (21-27) for this vertical.
      expect(drafts.first.roleTitle, 'Head of Product & Data Operations');
    });
  });

  group('TargetRoleStrategyResult JSON round-trip', () {
    test('serializes and restores every field', () {
      const result = TargetRoleStrategyResult(
        targets: [
          TargetRoleNarrative(
            verticalName: 'Tech Product & Data Operations',
            category: 'Technical & Engineering',
            roleTitle: 'Head of Product & Data Operations',
            fitScore: 100,
            topDimensionLabels: ['Investigative', 'Openness'],
            confidence: FitConfidence.high,
            why: 'Grounded explanation.',
            strengthenTip: 'Concrete tip.',
          ),
        ],
      );
      final restored = TargetRoleStrategyResult.fromJson(result.toJson());
      expect(restored.targets.single.verticalName, 'Tech Product & Data Operations');
      expect(restored.targets.single.fitScore, 100);
      expect(restored.targets.single.why, 'Grounded explanation.');
    });
  });

  group('TargetRoleStrategyScreen', () {
    testWidgets('shows a gate card when no Vertical Fit assessment exists', (tester) async {
      final repo = ProfileRepository()..saveProfile(_profile());
      await tester.pumpWidget(_wrap(repo));
      await tester.pumpAndSettle();

      expect(find.textContaining('Take the Career Vertical Fit quiz first'), findsOneWidget);
      expect(find.byKey(const Key('targetCard_Tech Product & Data Operations')), findsNothing);

      await tester.tap(find.byKey(const Key('goToVerticalFitButton')));
      await tester.pumpAndSettle();
      expect(find.text('Vertical Fit quiz screen'), findsOneWidget);
    });

    testWidgets('generates and shows 3 targets, primary first', (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(_wrap(_repositoryWithAssessment()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('targetCard_Tech Product & Data Operations')), findsOneWidget);
      expect(find.text('Primary'), findsOneWidget);
      expect(find.text('Secondary'), findsWidgets);
      expect(find.text('Head of Product & Data Operations'), findsOneWidget);
    });

    testWidgets('uses the cached result and skips regenerating when verticals match', (tester) async {
      _setTallViewport(tester);
      var callCount = 0;
      Future<TargetRoleStrategyResult> countingGenerate({
        required String cvText,
        cvPdfBytes,
        required List<TargetRoleDraft> drafts,
      }) {
        callCount++;
        return mockGenerateTargetRoleStrategy(cvText: cvText, cvPdfBytes: cvPdfBytes, drafts: drafts);
      }

      final repo = _repositoryWithAssessment();
      final dimensionScores = VerticalFitAssessment(ratings: _skewedRatings).dimensionScores;
      final drafts = buildTargetRoleDrafts(dimensionScores: dimensionScores, workExperienceYears: 22);
      await repo.saveTargetRoleStrategy(
        TargetRoleStrategyResult(
          targets: drafts
              .map(
                (d) => TargetRoleNarrative(
                  verticalName: d.verticalName,
                  category: d.category,
                  roleTitle: d.roleTitle,
                  fitScore: d.fitScore,
                  topDimensionLabels: d.topDimensionLabels,
                  confidence: d.confidence,
                  why: 'Cached why.',
                  strengthenTip: 'Cached tip.',
                ),
              )
              .toList(),
        ),
      );

      await tester.pumpWidget(_wrap(repo, generateStrategy: countingGenerate));
      await tester.pumpAndSettle();

      expect(callCount, 0);
      expect(find.text('Cached why.'), findsNWidgets(3));
    });

    testWidgets('regenerate button calls the service again', (tester) async {
      _setTallViewport(tester);
      var callCount = 0;
      Future<TargetRoleStrategyResult> countingGenerate({
        required String cvText,
        cvPdfBytes,
        required List<TargetRoleDraft> drafts,
      }) {
        callCount++;
        return mockGenerateTargetRoleStrategy(cvText: cvText, cvPdfBytes: cvPdfBytes, drafts: drafts);
      }

      await tester.pumpWidget(_wrap(_repositoryWithAssessment(), generateStrategy: countingGenerate));
      await tester.pumpAndSettle();
      expect(callCount, 1);

      await tester.tap(find.byKey(const Key('regenerateTargetRoleButton')));
      await tester.pumpAndSettle();

      expect(callCount, 2);
    });
  });
}
