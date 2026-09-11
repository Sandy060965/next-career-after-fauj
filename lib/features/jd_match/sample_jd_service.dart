/// Generates a stand-in job description for an officer with no real JD in
/// hand, keyed to a career vertical and a role title/tier.
typedef SampleJdGenerator = Future<String> Function({
  required String vertical,
  required String tier,
});

/// Overridable for testing; defaults to sample data until the Cloudflare
/// Worker backend is wired in.
Future<String> mockGenerateSampleJd({required String vertical, required String tier}) async {
  return '$tier — $vertical\n\n'
      'A representative role at this level, drafted for practice purposes.\n\n'
      'Key Responsibilities:\n'
      '- Lead day-to-day operations for this function\n'
      '- Own planning, budgeting, and reporting\n\n'
      'Required Experience:\n'
      '- 10+ years of relevant experience';
}
