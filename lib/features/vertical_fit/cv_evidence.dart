import 'aptitude_question.dart';

/// A dimension the CV-evidence pass was asked to check for one vertical —
/// [dimensions] are its contributing dimensions from the deterministic
/// ranking, sent as-is; the response can't change or add to them.
class VerticalEvidenceRequest {
  const VerticalEvidenceRequest({required this.verticalName, required this.dimensions});

  final String verticalName;
  final List<AptitudeDimension> dimensions;
}

/// Whether the CV backs up one self-rated dimension for one vertical.
/// [found] and [evidence] come straight from the AI call; never computed
/// or guessed client-side.
class DimensionEvidence {
  const DimensionEvidence({required this.dimension, required this.found, this.evidence});

  final AptitudeDimension dimension;
  final bool found;

  /// A specific citation from the CV, only ever non-null when [found].
  final String? evidence;

  Map<String, dynamic> toJson() => {
        'dimension': dimension.name,
        'found': found,
        'evidence': evidence,
      };

  factory DimensionEvidence.fromJson(Map<String, dynamic> json) => DimensionEvidence(
        dimension: AptitudeDimension.values.byName(json['dimension'] as String),
        found: json['found'] as bool,
        evidence: json['evidence'] as String?,
      );
}

class VerticalEvidence {
  const VerticalEvidence({required this.verticalName, required this.dimensionEvidence});

  final String verticalName;
  final List<DimensionEvidence> dimensionEvidence;

  Map<String, dynamic> toJson() => {
        'verticalName': verticalName,
        'dimensionEvidence': dimensionEvidence.map((d) => d.toJson()).toList(),
      };

  factory VerticalEvidence.fromJson(Map<String, dynamic> json) => VerticalEvidence(
        verticalName: json['verticalName'] as String,
        dimensionEvidence: (json['dimensionEvidence'] as List)
            .map((e) => DimensionEvidence.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Result of grounding the officer's top-3 verticals in their CV — always
/// tied to whichever specific verticals were checked (see the
/// set-equality check in `vertical_fit_result_screen.dart` before trusting
/// a cached result against a possibly-changed top-3).
class CvEvidenceResult {
  const CvEvidenceResult({required this.verticals});

  final List<VerticalEvidence> verticals;

  DimensionEvidence? evidenceFor(String verticalName, AptitudeDimension dimension) {
    for (final v in verticals) {
      if (v.verticalName != verticalName) continue;
      for (final d in v.dimensionEvidence) {
        if (d.dimension == dimension) return d;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() => {'verticals': verticals.map((v) => v.toJson()).toList()};

  factory CvEvidenceResult.fromJson(Map<String, dynamic> json) => CvEvidenceResult(
        verticals: (json['verticals'] as List)
            .map((e) => VerticalEvidence.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
