import 'dart:typed_data';

import 'jd_interview_question.dart';

typedef JdInterviewQuestionsAnalyzer = Future<List<JdInterviewQuestion>> Function({
  required String jdText,
  Uint8List? jdPdfBytes,
  String? cvText,
});

/// Placeholder analyzer used until the Cloudflare Worker backend is wired
/// in. Returns fixed sample data regardless of input so the screen can be
/// built and tested independently of the backend.
Future<List<JdInterviewQuestion>> mockGenerateJdInterviewQuestions({
  required String jdText,
  Uint8List? jdPdfBytes,
  String? cvText,
}) async {
  await Future.delayed(const Duration(milliseconds: 700));
  return const [
    JdInterviewQuestion(
      question: 'This role asks for cross-functional stakeholder management — describe a '
          'time you coordinated across departments that didn\'t report to you.',
      reason: 'The JD lists "cross-functional stakeholder management" as a core requirement.',
    ),
    JdInterviewQuestion(
      question: 'The JD calls for experience with P&L ownership — walk through the largest '
          'budget or revenue line you\'ve been directly accountable for.',
      reason: 'The JD specifies P&L ownership as a requirement for the role.',
    ),
    JdInterviewQuestion(
      question: 'This position is based in a fast-scaling team — how do you approach '
          'building processes from scratch versus operating within existing ones?',
      reason: 'The JD describes the team as "fast-scaling" and emphasises process ownership.',
    ),
  ];
}
