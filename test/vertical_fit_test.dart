import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/models/officer_profile.dart';
import 'package:next_career_after_fauj/core/services/profile_repository.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/career_paths/career_paths_screen.dart';
import 'package:next_career_after_fauj/features/career_paths/career_vertical.dart';
import 'package:next_career_after_fauj/features/vertical_fit/aptitude_question.dart';
import 'package:next_career_after_fauj/features/vertical_fit/cv_evidence.dart';
import 'package:next_career_after_fauj/features/vertical_fit/cv_evidence_service.dart';
import 'package:next_career_after_fauj/features/vertical_fit/vertical_fit.dart';
import 'package:next_career_after_fauj/features/vertical_fit/vertical_fit_quiz_screen.dart';
import 'package:next_career_after_fauj/features/vertical_fit/vertical_fit_result_screen.dart';
import 'package:provider/provider.dart';

/// Ratings that push investigative, openness, and conventional to a
/// dimension score of 100 and everything else to 20 — 'Tech Product & Data
/// Operations' is the only vertical drawing on exactly those three
/// dimensions, so it comes out uniquely top-ranked (same skew used in
/// target_role_strategy_test.dart).
final _skewedRatings = {
  for (final q in kAptitudeQuestions)
    q.id: (q.dimension == AptitudeDimension.investigative ||
            q.dimension == AptitudeDimension.openness ||
            q.dimension == AptitudeDimension.conventional)
        ? 5
        : 1,
};

OfficerProfile _profile() => OfficerProfile(
      rank: 'Col',
      fullName: 'Col A Verma',
      dateOfBirth: DateTime(1975, 5, 10),
      workExperienceYears: 22,
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

/// Evidence grounder that reports every dimension as NOT found, so every
/// vertical whose self-rating is high (>=80, as skewed ratings produce)
/// comes out `disconnected` — used to exercise the disconnect/retake UI.
Future<CvEvidenceResult> _noEvidenceFound({
  required String cvText,
  Uint8List? cvPdfBytes,
  required List<VerticalEvidenceRequest> requests,
}) async {
  return CvEvidenceResult(
    verticals: requests
        .map(
          (r) => VerticalEvidence(
            verticalName: r.verticalName,
            dimensionEvidence: r.dimensions.map((d) => DimensionEvidence(dimension: d, found: false)).toList(),
          ),
        )
        .toList(),
  );
}

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

  group('VerticalFitResultScreen Corps/Arm behaviour', () {
    testWidgets('AMC officer sees the domain-constrained notice and only medical verticals',
        (tester) async {
      tester.view.physicalSize = const Size(430, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const assessment = VerticalFitAssessment(ratings: {});
      await tester.pumpWidget(
        _wrap(
          const VerticalFitResultScreen(assessment: assessment, corpsOrArm: 'Army Medical Corps (AMC)'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('domainConstrainedNotice')), findsOneWidget);
      expect(find.textContaining('Army Medical Corps (AMC)-relevant'), findsOneWidget);
      // With no ratings given, every medical dimension ties, so the top 3
      // are simply the first 3 in kMedicalCareerVerticals — assert one of
      // them appears, and that no general-20 vertical leaked in.
      expect(find.byKey(ValueKey('verticalFit_${kMedicalCareerVerticals.first.name}')), findsOneWidget);
      expect(find.byKey(const Key('verticalFit_Operations & Process Excellence')), findsNothing);
    });

    testWidgets('a non-constrained Corps/Arm gets a soft affinity badge, not a domain notice',
        (tester) async {
      tester.view.physicalSize = const Size(430, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final ratings = {
        for (final q in kAptitudeQuestions)
          q.id: (q.dimension == AptitudeDimension.investigative ||
                  q.dimension == AptitudeDimension.conventional ||
                  q.dimension == AptitudeDimension.realistic)
              ? 5
              : 1,
      };
      final assessment = VerticalFitAssessment(ratings: ratings);

      await tester.pumpWidget(
        _wrap(
          VerticalFitResultScreen(assessment: assessment, corpsOrArm: 'Corps of Signals'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('domainConstrainedNotice')), findsNothing);
      expect(
        find.byKey(const ValueKey('corpsAffinity_IT Infrastructure & Cybersecurity')),
        findsOneWidget,
      );
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

    test('omitting cvEvidence and corpsAffinity reproduces pre-existing behaviour exactly', () {
      final scores = {for (final d in AptitudeDimension.values) d: 50}
        ..addAll({
          AptitudeDimension.investigative: 80,
          AptitudeDimension.openness: 85,
          AptitudeDimension.conventional: 75,
        });
      final fit =
          rankVerticalFit(scores).firstWhere((f) => f.vertical.name == 'Tech Product & Data Operations');
      expect(fit.confidence(scores), fit.confidence(scores, cvEvidence: null, corpsAffinity: false));
    });

    test('a tight spread drops to medium when CV evidence fails to corroborate it', () {
      // Only one dimension (openness, 82) is >=80, so this stays below the
      // 2-dimension disconnect threshold and instead exercises the
      // tight-spread-but-uncorroborated medium-confidence path.
      final scores = {for (final d in AptitudeDimension.values) d: 50}
        ..addAll({
          AptitudeDimension.investigative: 78,
          AptitudeDimension.openness: 82,
          AptitudeDimension.conventional: 70,
        });
      final fit =
          rankVerticalFit(scores).firstWhere((f) => f.vertical.name == 'Tech Product & Data Operations');
      final dims = fit.topContributingDimensions(scores);
      final evidence = CvEvidenceResult(
        verticals: [
          VerticalEvidence(
            verticalName: fit.vertical.name,
            dimensionEvidence: dims.map((d) => DimensionEvidence(dimension: d, found: false)).toList(),
          ),
        ],
      );
      expect(fit.confidence(scores, cvEvidence: evidence), FitConfidence.medium);
    });

    test('a tight spread with corps affinity stays high even without CV evidence', () {
      final scores = {for (final d in AptitudeDimension.values) d: 50}
        ..addAll({
          AptitudeDimension.investigative: 80,
          AptitudeDimension.openness: 85,
          AptitudeDimension.conventional: 75,
        });
      final fit =
          rankVerticalFit(scores).firstWhere((f) => f.vertical.name == 'Tech Product & Data Operations');
      expect(fit.confidence(scores, corpsAffinity: true), FitConfidence.high);
    });

    test('disconnected when at least 2 high self-rated dimensions have no CV evidence', () {
      final scores = {for (final d in AptitudeDimension.values) d: 50}
        ..addAll({
          AptitudeDimension.investigative: 90,
          AptitudeDimension.openness: 85,
          AptitudeDimension.conventional: 80,
        });
      final fit =
          rankVerticalFit(scores).firstWhere((f) => f.vertical.name == 'Tech Product & Data Operations');
      final dims = fit.topContributingDimensions(scores);
      final evidence = CvEvidenceResult(
        verticals: [
          VerticalEvidence(
            verticalName: fit.vertical.name,
            dimensionEvidence: dims.map((d) => DimensionEvidence(dimension: d, found: false)).toList(),
          ),
        ],
      );
      expect(fit.confidence(scores, cvEvidence: evidence), FitConfidence.disconnected);
    });

    test('a single unconfirmed dimension is not enough to call it disconnected', () {
      final scores = {for (final d in AptitudeDimension.values) d: 50}
        ..addAll({
          AptitudeDimension.investigative: 90,
          AptitudeDimension.openness: 85,
          AptitudeDimension.conventional: 80,
        });
      final fit =
          rankVerticalFit(scores).firstWhere((f) => f.vertical.name == 'Tech Product & Data Operations');
      final dims = fit.topContributingDimensions(scores);
      final evidence = CvEvidenceResult(
        verticals: [
          VerticalEvidence(
            verticalName: fit.vertical.name,
            dimensionEvidence: [
              DimensionEvidence(dimension: dims[0], found: false),
              for (final d in dims.skip(1)) DimensionEvidence(dimension: d, found: true, evidence: 'Cited.'),
            ],
          ),
        ],
      );
      expect(fit.confidence(scores, cvEvidence: evidence), isNot(FitConfidence.disconnected));
    });
  });

  group('VerticalFitResultScreen CV evidence grounding', () {
    testWidgets('ground-in-CV button calls the grounder and displays evidence', (tester) async {
      tester.view.physicalSize = const Size(430, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = ProfileRepository()..saveProfile(_profile());
      final assessment = VerticalFitAssessment(ratings: _skewedRatings);

      await tester.pumpWidget(
        _wrap(
          VerticalFitResultScreen(assessment: assessment),
          repository: repo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('groundInCvButton')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('groundInCvButton')));
      await tester.tap(find.byKey(const Key('groundInCvButton')));
      await tester.pumpAndSettle();

      expect(find.textContaining('From your CV'), findsWidgets);
      expect(find.byKey(const Key('regenerateCvEvidenceButton')), findsOneWidget);
      expect(repo.lastCvEvidenceResult, isNotNull);
    });

    testWidgets('cached evidence matching the current top-3 is reused without a fresh call',
        (tester) async {
      tester.view.physicalSize = const Size(430, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = ProfileRepository()..saveProfile(_profile());
      final assessment = VerticalFitAssessment(ratings: _skewedRatings);
      final top3 = rankVerticalFit(assessment.dimensionScores).take(3).toList();
      await repo.saveCvEvidenceResult(
        CvEvidenceResult(
          verticals: top3
              .map(
                (fit) => VerticalEvidence(
                  verticalName: fit.vertical.name,
                  dimensionEvidence: fit
                      .topContributingDimensions(assessment.dimensionScores)
                      .map((d) => DimensionEvidence(dimension: d, found: true, evidence: 'Cached hit.'))
                      .toList(),
                ),
              )
              .toList(),
        ),
      );

      var callCount = 0;
      Future<CvEvidenceResult> countingGrounder({
        required String cvText,
        Uint8List? cvPdfBytes,
        required List<VerticalEvidenceRequest> requests,
      }) {
        callCount++;
        return mockGroundCvEvidence(cvText: cvText, cvPdfBytes: cvPdfBytes, requests: requests);
      }

      await tester.pumpWidget(
        _wrap(
          VerticalFitResultScreen(assessment: assessment, groundCvEvidence: countingGrounder),
          repository: repo,
        ),
      );
      await tester.pumpAndSettle();

      expect(callCount, 0);
      expect(find.textContaining('Cached hit.'), findsWidgets);
      expect(find.byKey(const Key('regenerateCvEvidenceButton')), findsOneWidget);
    });

    testWidgets('disconnect notice appears when self-rating outstrips CV evidence, and can be dismissed',
        (tester) async {
      tester.view.physicalSize = const Size(430, 3400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = ProfileRepository()..saveProfile(_profile());
      final assessment = VerticalFitAssessment(ratings: _skewedRatings);

      await tester.pumpWidget(
        _wrap(
          VerticalFitResultScreen(assessment: assessment, groundCvEvidence: _noEvidenceFound),
          repository: repo,
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('groundInCvButton')));
      await tester.tap(find.byKey(const Key('groundInCvButton')));
      await tester.pumpAndSettle();

      const topVertical = 'Tech Product & Data Operations';
      const noticeKey = ValueKey('disconnectNotice_$topVertical');
      await tester.ensureVisible(find.byKey(noticeKey));
      expect(find.byKey(noticeKey), findsOneWidget);

      await tester.ensureVisible(find.byKey(const ValueKey('keepRatingButton_$topVertical')));
      await tester.tap(find.byKey(const ValueKey('keepRatingButton_$topVertical')));
      await tester.pumpAndSettle();

      expect(find.byKey(noticeKey), findsNothing);
    });

    testWidgets('retaking the assessment navigates to the quiz, pre-filled from the prior ratings',
        (tester) async {
      tester.view.physicalSize = const Size(430, 3400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = ProfileRepository()..saveProfile(_profile());
      final assessment = VerticalFitAssessment(ratings: _skewedRatings);
      repo.saveVerticalFitAssessment(assessment);

      await tester.pumpWidget(
        _wrap(
          VerticalFitResultScreen(assessment: assessment, groundCvEvidence: _noEvidenceFound),
          repository: repo,
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('groundInCvButton')));
      await tester.tap(find.byKey(const Key('groundInCvButton')));
      await tester.pumpAndSettle();

      const topVertical = 'Tech Product & Data Operations';
      await tester.ensureVisible(find.byKey(const ValueKey('retakeAssessmentButton_$topVertical')));
      await tester.tap(find.byKey(const ValueKey('retakeAssessmentButton_$topVertical')));
      await tester.pumpAndSettle();

      expect(find.text('Which corporate verticals suit you?'), findsOneWidget);
      // Pre-filled from _skewedRatings: an investigative-dimension question
      // should already show 5 selected, not the blank-quiz default of 3.
      final investigativeQuestion = kAptitudeQuestions.firstWhere(
        (q) => q.dimension == AptitudeDimension.investigative,
      );
      final segmented = tester.widget<SegmentedButton<int>>(
        find.byKey(ValueKey('rating_${investigativeQuestion.id}')),
      );
      expect(segmented.selected, {5});
    });
  });

  group('CareerPathsScreen recommendations', () {
    testWidgets('badges and sorts recommended verticals to the top', (tester) async {
      tester.view.physicalSize = const Size(430, 6000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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
