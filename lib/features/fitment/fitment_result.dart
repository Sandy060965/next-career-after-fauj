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

class CertificationRecommendation {
  const CertificationRecommendation({
    required this.name,
    required this.closesGap,
    required this.timeToAcquire,
    required this.priority,
  });

  final String name;
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
    required this.certificationGuidance,
  });

  final int fitmentScore;
  final String scoreRationale;
  final List<RequirementBreakdownItem> requirementBreakdown;
  final String originalCvExcerpt;
  final String refinedCv;
  final List<CertificationRecommendation> certificationGuidance;
}
