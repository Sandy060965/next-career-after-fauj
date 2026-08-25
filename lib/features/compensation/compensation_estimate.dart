/// A compensation estimate for a specific role/location, sourced from real
/// market salary data (JSearch's estimated-salary endpoint) — never an
/// LLM-invented figure. [negotiationGuidance] is directional, grounded only
/// in what the JD itself states.
class CompensationEstimate {
  const CompensationEstimate({
    required this.jobTitle,
    required this.location,
    this.locationIsEstimate = false,
    this.requestedLocation,
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

  /// True when the JD's actual city wasn't in our curated list, so
  /// [location] is a stand-in (currently always Mumbai) rather than the
  /// real target city — never silently presented as if it were a match.
  final bool locationIsEstimate;

  /// The JD's own stated city, only set when it differs from [location]
  /// because we don't have reliable data for it.
  final String? requestedLocation;

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
