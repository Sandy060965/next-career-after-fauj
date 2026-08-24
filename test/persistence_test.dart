import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/models/job_application.dart';
import 'package:next_career_after_fauj/core/models/officer_profile.dart';
import 'package:next_career_after_fauj/core/services/profile_repository.dart';
import 'package:next_career_after_fauj/features/ai_readiness/ai_competency.dart';
import 'package:next_career_after_fauj/features/ai_readiness/ai_readiness.dart';
import 'package:next_career_after_fauj/features/cv_civilianizer/civilianized_cv.dart';
import 'package:next_career_after_fauj/features/fitment/fitment_result.dart';
import 'package:next_career_after_fauj/features/vertical_fit/vertical_fit.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _profile = OfficerProfile(
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
  cvFileName: 'resume.docx',
  cvExtractedText: 'Sample extracted CV text.',
);

const _fitmentResult = FitmentResult(
  fitmentScore: 7,
  scoreRationale: 'Solid overall match.',
  requirementBreakdown: [
    RequirementBreakdownItem(
      requirement: 'PMP certification',
      status: RequirementStatus.gap,
      notes: 'No formal certification listed.',
    ),
  ],
  originalCvExcerpt: 'Original excerpt.',
  refinedCv: 'Refined CV text.',
  dimensionGaps: [
    DimensionAssessment(
      dimension: GapDimension.certifications,
      status: RequirementStatus.gap,
      notes: 'No certification listed.',
    ),
  ],
  gapRoadmap: [
    GapRoadmapItem(
      title: 'PMP',
      dimension: GapDimension.certifications,
      closesGap: 'PMP certification',
      timeToAcquire: '3-4 months',
      priority: 1,
    ),
  ],
);

const _verticalFit = VerticalFitAssessment(ratings: {'ops-1': 4, 'people-1': 2});

final _aiReadiness = AiReadinessResult(
  readinessScore: 60,
  scoreRationale: 'Moderate readiness.',
  dimensionScores: {for (final d in AiDimension.values) d: 60},
  skillGaps: [
    SkillGap(competency: kAiCompetencies.first, severity: GapSeverity.high, reason: 'Needs practice.'),
  ],
  cvAiBridge: 'Your logistics experience already involves data-driven decisions.',
  roadmap: const [
    RoadmapItem(
      phase: RoadmapPhase.day30,
      title: 'Learn LLM fundamentals',
      description: 'Complete an introductory course on how LLMs work.',
      courseId: 'fundamentals',
    ),
  ],
);

final _application = JobApplication(
  id: 'app-1',
  companyName: 'Acme Corp',
  roleTitle: 'Head of Operations',
  status: ApplicationStatus.applied,
  createdAt: DateTime(2026, 1, 1),
  source: 'Job Matches',
  appliedDate: DateTime(2026, 1, 5),
  nextActionDate: DateTime(2026, 1, 12),
  nextActionNote: 'Follow up with recruiter',
  notes: 'Referred by a course-mate.',
);

const _civilianizedCv = CivilianizedCv(
  civilianizedCv: 'Operations Director with 14+ years leading large organisations.',
  translationNotes: ['Rewrote command language as Operations Director.'],
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('JSON round-trips', () {
    test('OfficerProfile survives a toJson/fromJson round-trip', () {
      final restored = OfficerProfile.fromJson(_profile.toJson());

      expect(restored.rank, _profile.rank);
      expect(restored.fullName, _profile.fullName);
      expect(restored.dateOfBirth, _profile.dateOfBirth);
      expect(restored.workExperienceYears, _profile.workExperienceYears);
      expect(restored.workExperienceMonths, _profile.workExperienceMonths);
      expect(restored.releaseStatus, _profile.releaseStatus);
      expect(restored.releaseDate, _profile.releaseDate);
      expect(restored.service, _profile.service);
      expect(restored.mobileNumber, _profile.mobileNumber);
      expect(restored.email, _profile.email);
      expect(restored.segment, _profile.segment);
      expect(restored.cvFileName, _profile.cvFileName);
      expect(restored.cvExtractedText, _profile.cvExtractedText);
      expect(restored.cvPdfBytes, isNull);
    });

    test('FitmentResult survives a toJson/fromJson round-trip', () {
      final restored = FitmentResult.fromJson(_fitmentResult.toJson());

      expect(restored.fitmentScore, _fitmentResult.fitmentScore);
      expect(restored.scoreRationale, _fitmentResult.scoreRationale);
      expect(restored.requirementBreakdown.single.requirement,
          _fitmentResult.requirementBreakdown.single.requirement);
      expect(restored.requirementBreakdown.single.status,
          _fitmentResult.requirementBreakdown.single.status);
      expect(restored.refinedCv, _fitmentResult.refinedCv);
      expect(restored.dimensionGaps.single.dimension, GapDimension.certifications);
      expect(restored.gapRoadmap.single.title, 'PMP');
      expect(restored.gapRoadmap.single.priority, 1);
    });

    test('VerticalFitAssessment survives a toJson/fromJson round-trip', () {
      final restored = VerticalFitAssessment.fromJson(_verticalFit.toJson());
      expect(restored.ratings, _verticalFit.ratings);
    });

    test('AiReadinessResult survives a toJson/fromJson round-trip', () {
      final restored = AiReadinessResult.fromJson(_aiReadiness.toJson());

      expect(restored.readinessScore, 60);
      expect(restored.dimensionScores[AiDimension.awareness], 60);
      expect(restored.skillGaps.single.competency.id, kAiCompetencies.first.id);
      expect(restored.skillGaps.single.severity, GapSeverity.high);
      expect(restored.cvAiBridge, _aiReadiness.cvAiBridge);
      expect(restored.roadmap.single.title, 'Learn LLM fundamentals');
      expect(restored.roadmap.single.phase, RoadmapPhase.day30);
    });

    test('JobApplication survives a toJson/fromJson round-trip', () {
      final restored = JobApplication.fromJson(_application.toJson());

      expect(restored.companyName, _application.companyName);
      expect(restored.roleTitle, _application.roleTitle);
      expect(restored.status, ApplicationStatus.applied);
      expect(restored.source, _application.source);
      expect(restored.appliedDate, _application.appliedDate);
      expect(restored.nextActionDate, _application.nextActionDate);
      expect(restored.nextActionNote, _application.nextActionNote);
      expect(restored.notes, _application.notes);
    });

    test('CivilianizedCv survives a toJson/fromJson round-trip', () {
      final restored = CivilianizedCv.fromJson(_civilianizedCv.toJson());

      expect(restored.civilianizedCv, _civilianizedCv.civilianizedCv);
      expect(restored.translationNotes, _civilianizedCv.translationNotes);
    });
  });

  group('ProfileRepository persistence', () {
    test('a saved profile is restored by a fresh repository instance', () async {
      final writer = ProfileRepository();
      writer.saveProfile(_profile);
      // saveProfile persists in the background — give the microtask queue
      // a turn to let the (unawaited) SharedPreferences write land.
      await Future<void>.delayed(Duration.zero);

      final reader = ProfileRepository();
      await reader.loadFromStorage();

      expect(reader.profile?.fullName, _profile.fullName);
      expect(reader.profile?.email, _profile.email);
    });

    test('a saved fitment result and JD text are restored', () async {
      final writer = ProfileRepository();
      writer.saveFitmentResult(_fitmentResult, jdText: 'Some JD text');
      await Future<void>.delayed(Duration.zero);

      final reader = ProfileRepository();
      await reader.loadFromStorage();

      expect(reader.lastFitmentResult?.fitmentScore, 7);
      expect(reader.lastJdText, 'Some JD text');
    });

    test('a saved vertical fit assessment is restored', () async {
      final writer = ProfileRepository();
      writer.saveVerticalFitAssessment(_verticalFit);
      await Future<void>.delayed(Duration.zero);

      final reader = ProfileRepository();
      await reader.loadFromStorage();

      expect(reader.lastVerticalFitAssessment?.ratings, _verticalFit.ratings);
    });

    test('a saved AI readiness result is restored', () async {
      final writer = ProfileRepository();
      writer.saveAiReadinessResult(_aiReadiness);
      await Future<void>.delayed(Duration.zero);

      final reader = ProfileRepository();
      await reader.loadFromStorage();

      expect(reader.lastAiReadinessResult?.readinessScore, 60);
      expect(reader.lastAiReadinessResult?.skillGaps.single.competency.id, kAiCompetencies.first.id);
    });

    test('a saved application is restored', () async {
      final writer = ProfileRepository();
      writer.addApplication(_application);
      await Future<void>.delayed(Duration.zero);

      final reader = ProfileRepository();
      await reader.loadFromStorage();

      expect(reader.applications, hasLength(1));
      expect(reader.applications.single.companyName, 'Acme Corp');
      expect(reader.applications.single.status, ApplicationStatus.applied);
    });

    test('a saved civilianized CV is restored', () async {
      final writer = ProfileRepository();
      writer.saveCivilianizedCv(_civilianizedCv);
      await Future<void>.delayed(Duration.zero);

      final reader = ProfileRepository();
      await reader.loadFromStorage();

      expect(reader.lastCivilianizedCv?.civilianizedCv, _civilianizedCv.civilianizedCv);
    });

    test('loadFromStorage on an empty store leaves everything null', () async {
      final reader = ProfileRepository();
      await reader.loadFromStorage();

      expect(reader.profile, isNull);
      expect(reader.lastFitmentResult, isNull);
      expect(reader.lastVerticalFitAssessment, isNull);
      expect(reader.lastAiReadinessResult, isNull);
      expect(reader.applications, isEmpty);
      expect(reader.lastCivilianizedCv, isNull);
    });
  });
}
