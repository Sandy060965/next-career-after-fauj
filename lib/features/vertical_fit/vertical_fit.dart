import '../career_paths/career_vertical.dart';
import 'aptitude_question.dart';

/// The officer's 1-5 rating on every [kAptitudeQuestions] statement,
/// keyed by question id. Scoring is entirely deterministic — no LLM
/// involved, so it's instant, free, and never fabricated.
class VerticalFitAssessment {
  const VerticalFitAssessment({required this.ratings});

  final Map<String, int> ratings;

  Map<String, dynamic> toJson() => {'ratings': ratings};

  factory VerticalFitAssessment.fromJson(Map<String, dynamic> json) =>
      VerticalFitAssessment(ratings: Map<String, int>.from(json['ratings'] as Map));

  Map<AptitudeDimension, int> get dimensionScores {
    final scores = <AptitudeDimension, int>{};
    for (final dimension in AptitudeDimension.values) {
      final questions = kAptitudeQuestions.where((q) => q.dimension == dimension).toList();
      final sum = questions.fold<int>(0, (total, q) => total + (ratings[q.id] ?? 3));
      scores[dimension] = ((sum / questions.length) * 20).round();
    }
    return scores;
  }
}

/// How much the officer's own scores across a vertical's contributing
/// dimensions agree with each other — a fit score built from consistent
/// signals is more trustworthy than one where the inputs pull in different
/// directions, even if the average happens to be the same. Deliberately a
/// simple, explainable heuristic (score spread), not a statistical claim.
enum FitConfidence { high, medium, low }

extension FitConfidenceLabel on FitConfidence {
  String get label => switch (this) {
        FitConfidence.high => 'High confidence',
        FitConfidence.medium => 'Medium confidence',
        FitConfidence.low => 'Low confidence',
      };

  String get description => switch (this) {
        FitConfidence.high => "Your scores across this vertical's dimensions agree closely.",
        FitConfidence.medium => "Your scores across this vertical's dimensions vary somewhat.",
        FitConfidence.low =>
          "Your scores across this vertical's dimensions pull in different directions — "
              'treat the fit score as a rough signal, not a strong one.',
      };
}

class VerticalFit {
  const VerticalFit({required this.vertical, required this.fitScore});

  final CareerVertical vertical;
  final int fitScore;

  /// The dimension(s) this vertical draws on, sorted by the officer's own
  /// score on them — grounds the "why this fits you" explanation in the
  /// officer's actual answers rather than a generic template.
  List<AptitudeDimension> topContributingDimensions(Map<AptitudeDimension, int> dimensionScores) {
    final dims = List<AptitudeDimension>.from(kVerticalDimensions[vertical.name] ?? const []);
    dims.sort((a, b) => (dimensionScores[b] ?? 0).compareTo(dimensionScores[a] ?? 0));
    return dims;
  }

  /// See [FitConfidence] — computed from how tightly the officer's scores
  /// on this vertical's contributing dimensions cluster together.
  FitConfidence confidence(Map<AptitudeDimension, int> dimensionScores) {
    final dims = kVerticalDimensions[vertical.name] ?? const [];
    if (dims.length < 2) return FitConfidence.low;
    final scores = dims.map((d) => dimensionScores[d] ?? 0).toList();
    final spread = scores.reduce((a, b) => a > b ? a : b) - scores.reduce((a, b) => a < b ? a : b);
    if (spread <= 15) return FitConfidence.high;
    if (spread <= 35) return FitConfidence.medium;
    return FitConfidence.low;
  }
}

/// Ranks every vertical in [universe] (defaults to the general 20) by how
/// well it matches the officer's dimension scores, highest first. Callers
/// pass a Corps/Arm-constrained universe (see `corps_affinity.dart`) for
/// domain-constrained officers instead of accepting the default.
List<VerticalFit> rankVerticalFit(
  Map<AptitudeDimension, int> dimensionScores, {
  List<CareerVertical> universe = kCareerVerticals,
}) {
  final fits = universe.map((vertical) {
    final dims = kVerticalDimensions[vertical.name] ?? const [];
    final score = dims.isEmpty
        ? 0
        : (dims.fold<int>(0, (total, d) => total + (dimensionScores[d] ?? 0)) / dims.length).round();
    return VerticalFit(vertical: vertical, fitScore: score);
  }).toList();
  fits.sort((a, b) => b.fitScore.compareTo(a.fitScore));
  return fits;
}
