import 'dart:convert';

import 'package:http/http.dart' as http;

const _workerUrl = 'https://next-career-after-fauj-fitment.sandy060965.workers.dev/generate-sample-jd';
const _appSharedKey = String.fromEnvironment('APP_SHARED_KEY');
const _maxAttempts = 3;
const _retryDelay = Duration(seconds: 2);
const _retryableStatusCodes = {502, 503, 504, 522, 523, 524};

class SampleJdException implements Exception {
  SampleJdException(this.message);

  final String message;

  @override
  String toString() => message;
}

Future<String> httpGenerateSampleJd({required String vertical, required String tier}) async {
  final encodedBody = jsonEncode({'vertical': vertical, 'tier': tier});

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
    throw SampleJdException('Could not reach the JD generator: $lastError');
  }
  if (response.statusCode != 200) {
    throw SampleJdException('JD generation failed (${response.statusCode}): ${response.body}');
  }

  final json = jsonDecode(response.body) as Map<String, dynamic>;
  return json['jdText'] as String;
}
