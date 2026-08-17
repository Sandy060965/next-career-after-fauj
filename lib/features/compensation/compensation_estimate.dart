/// A compensation estimate for a specific role/location, sourced from real
/// market salary data (JSearch's estimated-salary endpoint) — never an
/// LLM-invented figure. [negotiationGuidance] is directional, grounded only
/// in what the JD itself states.
class CompensationEstimate {
  const CompensationEstimate({
    required this.jobTitle,
    required this.location,
    this.minSalary,
    this.maxSalary,
    this.medianSalary,
    this.currency,
    this.period,
    this.confidence,
    this.publisher,
    required this.negotiationGuidance,
  });

  final String jobTitle;
  final String location;
  final num? minSalary;
  final num? maxSalary;
  final num? medianSalary;
  final String? currency;
  final String? period;
  final String? confidence;
  final String? publisher;
  final String negotiationGuidance;

  bool get hasMarketData => minSalary != null || maxSalary != null;
}
