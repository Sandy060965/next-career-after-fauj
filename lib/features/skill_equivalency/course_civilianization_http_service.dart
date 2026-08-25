import 'dart:convert';

import 'package:http/http.dart' as http;

import 'course_civilianization.dart';

const _workerUrl = 'https://next-career-after-fauj-fitment.sandy060965.workers.dev/civilianize-course';
const _appSharedKey = String.fromEnvironment('APP_SHARED_KEY');
const _maxAttempts = 3;
const _retryDelay = Duration(seconds: 2);
const _retryableStatusCodes = {502, 503, 504, 522, 523, 524};

class CourseCivilianizationException implements Exception {
  CourseCivilianizationException(this.message);

  final String message;

  @override
  String toString() => message;
}

Future<CourseCivilianizationResult> httpCivilianizeCourse({
  required String courseName,
  String? courseDescription,
  String? mobileNumber,
}) async {
  final body = <String, dynamic>{
    'courseName': courseName,
    if (courseDescription != null && courseDescription.isNotEmpty) 'courseDescription': courseDescription,
    if (mobileNumber != null) 'mobileNumber': mobileNumber,
  };
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
    throw CourseCivilianizationException('Could not reach the course lookup service: $lastError');
  }
  if (response.statusCode != 200) {
    throw CourseCivilianizationException(
      'Looking up this course failed (${response.statusCode}): ${response.body}',
    );
  }

  return CourseCivilianizationResult.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
}
