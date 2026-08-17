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

  Map<String, dynamic> toJson() => {
        'requirement': requirement,
        'status': status.name,
        'notes': notes,
      };

  factory RequirementBreakdownItem.fromJson(Map<String, dynamic> json) => RequirementBreakdownItem(
        requirement: json['requirement'] as String,
        status: RequirementStatus.values.byName(json['status'] as String),
        notes: json['notes'] as String,
      );
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

  Map<String, dynamic> toJson() => {
        'dimension': dimension.name,
        'status': status.name,
        'notes': notes,
      };

  factory DimensionAssessment.fromJson(Map<String, dynamic> json) => DimensionAssessment(
        dimension: GapDimension.values.byName(json['dimension'] as String),
        status: RequirementStatus.values.byName(json['status'] as String),
        notes: json['notes'] as String,
      );
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

  Map<String, dynamic> toJson() => {
        'title': title,
        'dimension': dimension.name,
        'closesGap': closesGap,
        'timeToAcquire': timeToAcquire,
        'priority': priority,
      };

  factory GapRoadmapItem.fromJson(Map<String, dynamic> json) => GapRoadmapItem(
        title: json['title'] as String,
        dimension: GapDimension.values.byName(json['dimension'] as String),
        closesGap: json['closesGap'] as String,
        timeToAcquire: json['timeToAcquire'] as String,
        priority: json['priority'] as int,
      );
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

  Map<String, dynamic> toJson() => {
        'fitmentScore': fitmentScore,
        'scoreRationale': scoreRationale,
        'requirementBreakdown': requirementBreakdown.map((e) => e.toJson()).toList(),
        'originalCvExcerpt': originalCvExcerpt,
        'refinedCv': refinedCv,
        'dimensionGaps': dimensionGaps.map((e) => e.toJson()).toList(),
        'gapRoadmap': gapRoadmap.map((e) => e.toJson()).toList(),
      };

  factory FitmentResult.fromJson(Map<String, dynamic> json) => FitmentResult(
        fitmentScore: json['fitmentScore'] as int,
        scoreRationale: json['scoreRationale'] as String,
        requirementBreakdown: (json['requirementBreakdown'] as List)
            .map((e) => RequirementBreakdownItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        originalCvExcerpt: json['originalCvExcerpt'] as String,
        refinedCv: json['refinedCv'] as String,
        dimensionGaps: (json['dimensionGaps'] as List)
            .map((e) => DimensionAssessment.fromJson(e as Map<String, dynamic>))
            .toList(),
        gapRoadmap: (json['gapRoadmap'] as List)
            .map((e) => GapRoadmapItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
