enum RequirementStatus { met, partiallyMet, gap }

extension RequirementStatusLabel on RequirementStatus {
  String get label => switch (this) {
        RequirementStatus.met => 'Met',
        RequirementStatus.partiallyMet => 'Partially Met',
        RequirementStatus.gap => 'Gap',
      };
}

class RequirementBreakdownItem {
  const RequirementBreakdownItem({
    required this.requirement,
    required this.status,
    required this.notes,
  });

  final String requirement;
  final RequirementStatus status;
  final String notes;
}

enum GapDimension { experience, education, skills, certifications }

extension GapDimensionLabel on GapDimension {
  String get label => switch (this) {
        GapDimension.experience => 'Experience',
        GapDimension.education => 'Education & Qualifications',
        GapDimension.skills => 'Skills',
        GapDimension.certifications => 'Certifications',
      };
}

/// How the CV measures up against the JD on one of the four gap
/// dimensions (experience, education, skills, certifications).
class DimensionAssessment {
  const DimensionAssessment({
    required this.dimension,
    required this.status,
    required this.notes,
  });

  final GapDimension dimension;
  final RequirementStatus status;
  final String notes;
}

/// A prioritized, concrete step to close a specific gap — spans all four
/// dimensions, not just certifications (e.g. a certification to earn, a
/// course to close a skill gap, or how to frame limited experience).
class GapRoadmapItem {
  const GapRoadmapItem({
    required this.title,
    required this.dimension,
    required this.closesGap,
    required this.timeToAcquire,
    required this.priority,
  });

  final String title;
  final GapDimension dimension;
  final String closesGap;
  final String timeToAcquire;
  final int priority;
}

/// Result of comparing an officer's CV against a job description.
class FitmentResult {
  const FitmentResult({
    required this.fitmentScore,
    required this.scoreRationale,
    required this.requirementBreakdown,
    required this.originalCvExcerpt,
    required this.refinedCv,
    required this.dimensionGaps,
    required this.gapRoadmap,
  });

  final int fitmentScore;
  final String scoreRationale;
  final List<RequirementBreakdownItem> requirementBreakdown;
  final String originalCvExcerpt;
  final String refinedCv;
  final List<DimensionAssessment> dimensionGaps;
  final List<GapRoadmapItem> gapRoadmap;
}
