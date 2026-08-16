import 'fitment_result.dart';

typedef FitmentAnalyzer = Future<FitmentResult> Function({
  required String jdText,
  required String cvFileName,
});

/// Placeholder analyzer used until the Cloudflare Worker backend is wired
/// in. Returns fixed sample data regardless of input so the results screens
/// can be built and tested independently of the backend.
Future<FitmentResult> mockAnalyzeFitment({
  required String jdText,
  required String cvFileName,
}) async {
  await Future.delayed(const Duration(milliseconds: 700));
  return const FitmentResult(
    fitmentScore: 7,
    scoreRationale:
        'Strong operational leadership and logistics background covers most core '
        'requirements; a formal project-management certification is the main gap.',
    requirementBreakdown: [
      RequirementBreakdownItem(
        requirement: '8+ years managing cross-functional teams',
        status: RequirementStatus.met,
        notes: 'CV shows over a decade leading teams of 30+ across postings.',
      ),
      RequirementBreakdownItem(
        requirement: 'Supply chain / logistics planning experience',
        status: RequirementStatus.met,
        notes: 'Directly evidenced by multiple logistics command roles.',
      ),
      RequirementBreakdownItem(
        requirement: 'PMP or equivalent project-management certification',
        status: RequirementStatus.gap,
        notes: 'No formal certification listed on the CV.',
      ),
      RequirementBreakdownItem(
        requirement: 'Exposure to ERP / inventory software (SAP or similar)',
        status: RequirementStatus.partiallyMet,
        notes: 'CV mentions "digitised unit inventory tracking" but no named platform.',
      ),
      RequirementBreakdownItem(
        requirement: "Bachelor's degree",
        status: RequirementStatus.met,
        notes: 'Listed under education.',
      ),
    ],
    originalCvExcerpt:
        'Led a team of 30+ personnel responsible for unit logistics and supply '
        'planning. Digitised unit inventory tracking, reducing stock discrepancies. '
        'Coordinated cross-functional exercises involving multiple departments.',
    refinedCv:
        'Supply Chain & Operations Leader with 10+ years managing cross-functional '
        'teams of 30+ in high-tempo logistics environments. Led end-to-end supply '
        'planning and inventory digitisation, reducing stock discrepancies and '
        'improving audit readiness. Proven track record coordinating multi-department '
        'operations under tight timelines — directly transferable to supply chain and '
        'operations management roles.',
    certificationGuidance: [
      CertificationRecommendation(
        name: 'PMP (Project Management Professional)',
        closesGap: 'PMP or equivalent project-management certification',
        timeToAcquire: '3-4 months',
        priority: 1,
      ),
      CertificationRecommendation(
        name: 'SAP Certified Associate — Supply Chain',
        closesGap: 'Exposure to ERP / inventory software',
        timeToAcquire: '6-8 weeks',
        priority: 2,
      ),
      CertificationRecommendation(
        name: 'Six Sigma Green Belt',
        closesGap: 'Process-improvement credibility for operations roles',
        timeToAcquire: '4-6 weeks',
        priority: 3,
      ),
    ],
  );
}
