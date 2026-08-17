import 'dart:convert';

import 'package:http/http.dart' as http;

import 'mock_interview_feedback.dart';

const _workerUrl = 'https://next-career-after-fauj-fitment.sandy060965.workers.dev/mock-interview-feedback';
const _appSharedKey = String.fromEnvironment('APP_SHARED_KEY');
const _maxAttempts = 3;
const _retryDelay = Duration(seconds: 2);
const _retryableStatusCodes = {502, 503, 504, 522, 523, 524};

class MockInterviewException implements Exception {
  MockInterviewException(this.message);

  final String message;

  @override
  String toString() => message;
}

Future<MockInterviewFeedback> httpAnalyzeInterviewAnswer({
  required String question,
  required String answer,
  String? jdText,
}) async {
  final body = <String, dynamic>{'question': question, 'answer': answer};
  if (jdText != null) body['jdText'] = jdText;
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
    throw MockInterviewException('Could not reach the interview-feedback service: $lastError');
  }
  if (response.statusCode != 200) {
    throw MockInterviewException(
      'Interview feedback failed (${response.statusCode}): ${response.body}',
    );
  }

  final json = jsonDecode(response.body) as Map<String, dynamic>;
  return MockInterviewFeedback(
    strengths: (json['strengths'] as List).cast<String>(),
    improvements: (json['improvements'] as List).cast<String>(),
    overallImpression: json['overall_impression'] as String,
  );
}
