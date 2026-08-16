import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/models/officer_profile.dart';
import 'package:next_career_after_fauj/core/services/profile_repository.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/fitment/certification_timeline_screen.dart';
import 'package:next_career_after_fauj/features/fitment/fitment_result.dart';
import 'package:next_career_after_fauj/features/fitment/refined_cv_screen.dart';
import 'package:next_career_after_fauj/features/fitment/score_gap_screen.dart';
import 'package:provider/provider.dart';

const _result = FitmentResult(
  fitmentScore: 7,
  scoreRationale: 'Solid overall match with one certification gap.',
  requirementBreakdown: [
    RequirementBreakdownItem(
      requirement: 'PMP certification',
      status: RequirementStatus.gap,
      notes: 'No formal certification listed on the CV.',
    ),
    RequirementBreakdownItem(
      requirement: 'Team leadership experience',
      status: RequirementStatus.met,
      notes: 'Over a decade leading teams of 30+.',
    ),
  ],
  originalCvExcerpt: 'Led logistics operations for a large unit.',
  refinedCv: 'Supply Chain & Operations Leader with proven logistics track record.',
  certificationGuidance: [
    CertificationRecommendation(
      name: 'PMP',
      closesGap: 'PMP certification',
      timeToAcquire: '3-4 months',
      priority: 2,
    ),
    CertificationRecommendation(
      name: 'Six Sigma Green Belt',
      closesGap: 'Process-improvement credibility',
      timeToAcquire: '4-6 weeks',
      priority: 1,
    ),
  ],
);

Widget _wrap(Widget child, {ProfileRepository? repository}) {
  return ChangeNotifierProvider<ProfileRepository>.value(
    value: repository ?? ProfileRepository(),
    child: MaterialApp(theme: AppTheme.light, home: child),
  );
}

void main() {
  group('ScoreGapScreen', () {
    testWidgets('shows the score, rationale, and expandable requirement notes',
        (tester) async {
      await tester.pumpWidget(_wrap(const ScoreGapScreen(result: _result)));

      expect(find.text('7'), findsOneWidget);
      expect(find.text('Solid overall match with one certification gap.'), findsOneWidget);
      expect(find.text('PMP certification'), findsOneWidget);
      expect(find.text('Gap'), findsOneWidget);
      expect(find.text('Met'), findsOneWidget);

      // Notes are only mounted once the tile is expanded.
      expect(find.text('No formal certification listed on the CV.'), findsNothing);
      await tester.tap(find.text('PMP certification'));
      await tester.pumpAndSettle();
      expect(find.text('No formal certification listed on the CV.'), findsOneWidget);
    });

    testWidgets('navigates to Refined CV and Certification Guidance screens', (tester) async {
      tester.view.physicalSize = const Size(430, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(const ScoreGapScreen(result: _result)));

      await tester.tap(find.byKey(const Key('viewRefinedCvButton')));
      await tester.pumpAndSettle();
      expect(find.text('Refined CV'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('viewCertificationGuidanceButton')));
      await tester.pumpAndSettle();
      expect(find.text('Certification Guidance'), findsOneWidget);
    });
  });

  group('RefinedCvScreen', () {
    testWidgets('toggles between original and refined CV text', (tester) async {
      await tester.pumpWidget(_wrap(const RefinedCvScreen(result: _result)));

      expect(find.text('Supply Chain & Operations Leader with proven logistics track record.'),
          findsOneWidget);
      expect(find.text('Led logistics operations for a large unit.'), findsNothing);

      await tester.tap(find.text('Original'));
      await tester.pumpAndSettle();

      expect(find.text('Led logistics operations for a large unit.'), findsOneWidget);
      expect(find.text('Supply Chain & Operations Leader with proven logistics track record.'),
          findsNothing);
    });
  });

  group('CertificationTimelineScreen', () {
    testWidgets('lists certifications in priority order and shows the release marker',
        (tester) async {
      final repository = ProfileRepository()
        ..saveProfile(
          OfficerProfile(
            rank: 'Lt Col',
            fullName: 'Lt Col A Verma',
            dateOfBirth: DateTime(1978, 5, 10),
            workExperienceYears: 18,
            workExperienceMonths: 2,
            releaseStatus: ReleaseStatus.tentative,
            releaseDate: DateTime(2027, 6, 30),
            service: OfficerService.army,
            mobileNumber: '9876543210',
            email: 'a.verma@example.com',
            segment: OfficerSegment.pmr,
            cvFileName: 'resume.pdf',
          ),
        );

      await tester.pumpWidget(
        _wrap(const CertificationTimelineScreen(result: _result), repository: repository),
      );

      final sixSigmaCenter = tester.getCenter(find.text('Six Sigma Green Belt'));
      final pmpCenter = tester.getCenter(find.text('PMP'));
      expect(sixSigmaCenter.dy, lessThan(pmpCenter.dy));

      expect(find.textContaining('Target: release on'), findsOneWidget);
    });

    testWidgets('shows an already-released marker when the profile says so', (tester) async {
      final repository = ProfileRepository()
        ..saveProfile(
          OfficerProfile(
            rank: 'Lt Col',
            fullName: 'Lt Col A Verma',
            dateOfBirth: DateTime(1978, 5, 10),
            workExperienceYears: 18,
            workExperienceMonths: 2,
            releaseStatus: ReleaseStatus.alreadyReleased,
            releaseDate: DateTime(2024, 1, 15),
            service: OfficerService.army,
            mobileNumber: '9876543210',
            email: 'a.verma@example.com',
            segment: OfficerSegment.pmr,
            cvFileName: 'resume.pdf',
          ),
        );

      await tester.pumpWidget(
        _wrap(const CertificationTimelineScreen(result: _result), repository: repository),
      );

      expect(find.textContaining('Already released'), findsOneWidget);
    });
  });
}
