import 'dart:convert';

import 'package:http/http.dart' as http;

import 'built_cv.dart';
import 'cv_builder_intake.dart';

const _workerUrl = 'https://next-career-after-fauj-fitment.sandy060965.workers.dev/build-cv';
const _appSharedKey = String.fromEnvironment('APP_SHARED_KEY');
const _maxAttempts = 3;
const _retryDelay = Duration(seconds: 2);
const _retryableStatusCodes = {502, 503, 504, 522, 523, 524};

class CvBuilderException implements Exception {
  CvBuilderException(this.message);

  final String message;

  @override
  String toString() => message;
}

Future<BuiltCv> httpBuildCv({required CvBuilderIntake intake}) async {
  final encodedBody = jsonEncode({'intake': intake.toJson()});

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
    throw CvBuilderException('Could not reach the CV builder service: $lastError');
  }
  if (response.statusCode != 200) {
    throw CvBuilderException('Building your CV failed (${response.statusCode}): ${response.body}');
  }

  final json = jsonDecode(response.body) as Map<String, dynamic>;
  return BuiltCv(cvText: json['cv_text'] as String);
}
