/// A question this specific JD is likely to probe, grounded in what the JD
/// actually states — never generic filler, never invented claims about the
/// hiring company.
class JdInterviewQuestion {
  const JdInterviewQuestion({required this.question, required this.reason});

  final String question;

  /// Why this JD suggests the question — must reference something the JD
  /// actually says.
  final String reason;
}
