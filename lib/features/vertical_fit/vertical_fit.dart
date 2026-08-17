import '../career_paths/career_vertical.dart';
import 'aptitude_question.dart';

/// The officer's 1-5 rating on every [kAptitudeQuestions] statement,
/// keyed by question id. Scoring is entirely deterministic — no LLM
/// involved, so it's instant, free, and never fabricated.
class VerticalFitAssessment {
  const VerticalFitAssessment({required this.ratings});

  final Map<String, int> ratings;

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
}

/// Ranks every Career Paths vertical by how well it matches the officer's
/// dimension scores, highest first.
List<VerticalFit> rankVerticalFit(Map<AptitudeDimension, int> dimensionScores) {
  final fits = kCareerVerticals.map((vertical) {
    final dims = kVerticalDimensions[vertical.name] ?? const [];
    final score = dims.isEmpty
        ? 0
        : (dims.fold<int>(0, (total, d) => total + (dimensionScores[d] ?? 0)) / dims.length).round();
    return VerticalFit(vertical: vertical, fitScore: score);
  }).toList();
  fits.sort((a, b) => b.fitScore.compareTo(a.fitScore));
  return fits;
}
