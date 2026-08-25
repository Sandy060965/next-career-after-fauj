import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'jd_interview_question.dart';

const _workerUrl = 'https://next-career-after-fauj-fitment.sandy060965.workers.dev/interview-questions';
const _appSharedKey = String.fromEnvironment('APP_SHARED_KEY');
const _maxAttempts = 3;
const _retryDelay = Duration(seconds: 2);
const _retryableStatusCodes = {502, 503, 504, 522, 523, 524};

class InterviewQuestionsException implements Exception {
  InterviewQuestionsException(this.message);

  final String message;

  @override
  String toString() => message;
}

Future<List<JdInterviewQuestion>> httpGenerateJdInterviewQuestions({
  required String jdText,
  Uint8List? jdPdfBytes,
  String? cvText,
}) async {
  final body = <String, dynamic>{
    if (jdPdfBytes != null) 'jdPdfBase64': base64Encode(jdPdfBytes) else 'jdText': jdText,
  };
  if (cvText != null) body['cvText'] = cvText;
  final encodedBody = jsonEncode(body);

  http.Response? response;
  Object? lastError;
  for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
    try {
      response = await http.post(
        Uri.parse(_workerUrl),
        headers: const {
          'content-type': 'application/json',
          'x-app-key': _appSharedKey,
        },
        body: encodedBody,
      );
    } catch (e) {
      lastError = e;
      response = null;
    }

    final shouldRetry = response == null || _retryableStatusCodes.contains(response.statusCode);
    if (!shouldRetry || attempt == _maxAttempts) break;
    await Future.delayed(_retryDelay);
  }

  if (response == null) {
    throw InterviewQuestionsException('Could not reach the interview-questions service: $lastError');
  }
  if (response.statusCode != 200) {
    throw InterviewQuestionsException(
      'Interview question generation failed (${response.statusCode}): ${response.body}',
    );
  }

  final json = jsonDecode(response.body) as Map<String, dynamic>;
  return (json['questions'] as List)
      .map(
        (e) => JdInterviewQuestion(
          question: e['question'] as String,
          reason: e['reason'] as String,
        ),
      )
      .toList();
}
