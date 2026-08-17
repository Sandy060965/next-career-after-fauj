enum JobPortal { naukri, indeed, linkedin, other }

extension JobPortalLabel on JobPortal {
  String get label => switch (this) {
        JobPortal.naukri => 'Naukri',
        JobPortal.indeed => 'Indeed',
        JobPortal.linkedin => 'LinkedIn',
        JobPortal.other => 'Other',
      };

  static JobPortal fromUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('naukri.com')) return JobPortal.naukri;
    if (lower.contains('indeed.com')) return JobPortal.indeed;
    if (lower.contains('linkedin.com')) return JobPortal.linkedin;
    return JobPortal.other;
  }
}

/// A single job listing matched against the officer's CV. [applyUrl] is
/// always sourced directly from the job-search API's data — never
/// generated or altered by the LLM — so it's a real, clickable link.
class JobMatch {
  const JobMatch({
    required this.title,
    required this.company,
    required this.portal,
    required this.applyUrl,
    required this.fitReason,
    this.location,
    this.postedDate,
    this.ctcRange,
    this.isTopCompany = false,
  });

  final String title;
  final String company;
  final JobPortal portal;
  final String applyUrl;
  final String fitReason;
  final String? location;
  final String? postedDate;

  /// Exactly as reported by the job-search API's source data — never an
  /// LLM estimate. Null means the source posting didn't disclose CTC, which
  /// the UI should show as "Not disclosed" rather than guessing.
  final String? ctcRange;

  /// True only when [company] matched an entry in the reference Top 250
  /// companies list — an annotation, not a filter.
  final bool isTopCompany;
}
