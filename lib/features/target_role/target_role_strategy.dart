import '../career_paths/career_vertical.dart';
import '../vertical_fit/aptitude_question.dart';
import '../vertical_fit/vertical_fit.dart';

/// One deterministically-derived target — vertical, role title, fit score,
/// and top contributing dimensions all come straight from Career Paths'
/// experience ladder and Vertical Fit's rating math. Nothing here is AI
/// output; this is what gets sent to the backend for the one grounded
/// "why" narrative call.
class TargetRoleDraft {
  const TargetRoleDraft({
    required this.verticalName,
    required this.category,
    required this.roleTitle,
    required this.fitScore,
    required this.topDimensionLabels,
  });

  final String verticalName;
  final String category;
  final String roleTitle;
  final int fitScore;
  final List<String> topDimensionLabels;
}

/// Builds the top 3 [TargetRoleDraft]s (primary + 2 secondary), highest fit
/// first — entirely deterministic, no AI involved at this stage.
List<TargetRoleDraft> buildTargetRoleDrafts({
  required Map<AptitudeDimension, int> dimensionScores,
  required int workExperienceYears,
}) {
  final ranked = rankVerticalFit(dimensionScores).take(3);
  return ranked
      .map(
        (fit) => TargetRoleDraft(
          verticalName: fit.vertical.name,
          category: fit.vertical.category,
          roleTitle: fit.vertical.levelForExperience(workExperienceYears).title,
          fitScore: fit.fitScore,
          topDimensionLabels: fit
              .topContributingDimensions(dimensionScores)
              .map((d) => d.label)
              .toList(),
        ),
      )
      .toList();
}

/// A [TargetRoleDraft] plus the one AI-generated part: a grounded "why this
/// fits you" explanation and a concrete tip to strengthen the case. Fully
/// flattened (no [CareerVertical]/[AptitudeDimension] references) so it can
/// be cached wholesale, the same way [CivilianizedCv] is.
class TargetRoleNarrative {
  const TargetRoleNarrative({
    required this.verticalName,
    required this.category,
    required this.roleTitle,
    required this.fitScore,
    required this.topDimensionLabels,
    required this.why,
    required this.strengthenTip,
  });

  final String verticalName;
  final String category;
  final String roleTitle;
  final int fitScore;
  final List<String> topDimensionLabels;
  final String why;
  final String strengthenTip;

  Map<String, dynamic> toJson() => {
        'verticalName': verticalName,
        'category': category,
        'roleTitle': roleTitle,
        'fitScore': fitScore,
        'topDimensionLabels': topDimensionLabels,
        'why': why,
        'strengthenTip': strengthenTip,
      };

  factory TargetRoleNarrative.fromJson(Map<String, dynamic> json) => TargetRoleNarrative(
        verticalName: json['verticalName'] as String,
        category: json['category'] as String,
        roleTitle: json['roleTitle'] as String,
        fitScore: json['fitScore'] as int,
        topDimensionLabels: List<String>.from(json['topDimensionLabels'] as List),
        why: json['why'] as String,
        strengthenTip: json['strengthenTip'] as String,
      );
}

/// [targets] is always exactly 3, ranked highest-fit first — [targets.first]
/// is the primary target, the rest are the two secondary targets.
class TargetRoleStrategyResult {
  const TargetRoleStrategyResult({required this.targets});

  final List<TargetRoleNarrative> targets;

  Map<String, dynamic> toJson() => {'targets': targets.map((t) => t.toJson()).toList()};

  factory TargetRoleStrategyResult.fromJson(Map<String, dynamic> json) => TargetRoleStrategyResult(
        targets: (json['targets'] as List)
            .map((e) => TargetRoleNarrative.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
