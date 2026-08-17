import 'dart:typed_data';

import 'india_cities.dart';
import 'job_match.dart';

typedef JobMatchesAnalyzer = Future<List<JobMatch>> Function({
  required String cvText,
  CityTier? cityTier,
  Uint8List? cvPdfBytes,
});

/// Placeholder used until the Worker's /job-matches endpoint (JSearch +
/// Claude ranking) is deployed. Returns fixed sample data so the results
/// screen can be built and tested independently of the backend.
Future<List<JobMatch>> mockAnalyzeJobMatches({
  required String cvText,
  CityTier? cityTier,
  Uint8List? cvPdfBytes,
}) async {
  await Future.delayed(const Duration(milliseconds: 700));
  return const [
    JobMatch(
      title: 'Head of Security – Manufacturing Plant',
      company: 'Tata Steel',
      portal: JobPortal.naukri,
      applyUrl: 'https://www.naukri.com/job-listings-example-1',
      fitReason: 'Matches 14+ years of security leadership and large-team management experience.',
      location: 'Mumbai',
      postedDate: '3 days ago',
      ctcRange: '₹28-35 LPA',
      isTopCompany: true,
    ),
    JobMatch(
      title: 'Chief Security Officer',
      company: 'Regional Manufacturing Group',
      portal: JobPortal.indeed,
      applyUrl: 'https://in.indeed.com/job-listings-example-2',
      fitReason: 'Strong fit for crisis management and 24x7 security operations background.',
      location: 'Pune',
      postedDate: '1 week ago',
      ctcRange: null,
      isTopCompany: false,
    ),
    JobMatch(
      title: 'Security & Risk Manager',
      company: 'Infosys',
      portal: JobPortal.linkedin,
      applyUrl: 'https://www.linkedin.com/jobs/view/example-3',
      fitReason: 'Aligns with threat assessment and stakeholder engagement experience.',
      location: 'Bengaluru',
      postedDate: '2 days ago',
      ctcRange: '₹22-30 LPA',
      isTopCompany: true,
    ),
  ];
}
