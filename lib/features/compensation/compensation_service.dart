import 'compensation_estimate.dart';

typedef CompensationAnalyzer = Future<CompensationEstimate> Function({
  required String jdText,
  String? cvText,
});

/// Placeholder analyzer used until the Cloudflare Worker backend is wired
/// in. Returns fixed sample data regardless of input.
Future<CompensationEstimate> mockEstimateCompensation({
  required String jdText,
  String? cvText,
}) async {
  await Future.delayed(const Duration(milliseconds: 700));
  return const CompensationEstimate(
    jobTitle: 'Chief Operating Officer',
    location: 'Mumbai',
    minSalary: 4500000,
    maxSalary: 8200000,
    medianSalary: 6100000,
    currency: 'INR',
    period: 'YEAR',
    confidence: 'CONFIDENT',
    publisher: 'Glassdoor',
    negotiationGuidance:
        'This JD emphasises P&L ownership and multi-site operations — both are strong '
        'negotiating levers. If your prior P&L scope is smaller than what\'s asked here, '
        'expect the offer to land toward the lower end of the range; a larger scope or '
        'directly relevant certifications support the upper end.',
  );
}
