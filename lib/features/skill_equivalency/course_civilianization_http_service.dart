import 'dart:convert';

import 'package:http/http.dart' as http;

import 'course_civilianization.dart';
import 'skill_equivalency.dart';

const _baseUrl = 'https://next-career-after-fauj-fitment.sandy060965.workers.dev';
const _workerUrl = '$_baseUrl/civilianize-course';
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

/// Admin-approved courses that have grown the curated list since the app
/// was last released — merged with [kSkillEquivalencies] at display time.
/// Best-effort by design at the call site: the curated list alone is
/// already a complete, useful screen, so a failure here should never block
/// or error the whole screen.
Future<List<SkillEquivalency>> httpFetchApprovedEquivalencies() async {
  final response = await http.post(
    Uri.parse('$_baseUrl/skill-equivalencies'),
    headers: const {'content-type': 'application/json', 'x-app-key': _appSharedKey},
    body: '{}',
  );
  if (response.statusCode != 200) {
    throw CourseCivilianizationException(
      'Could not load recently added courses (${response.statusCode}).',
    );
  }
  final json = jsonDecode(response.body) as Map<String, dynamic>;
  return (json['equivalencies'] as List)
      .map(
        (e) => SkillEquivalency(
          militaryTerm: (e as Map<String, dynamic>)['militaryTerm'] as String,
          civilianEquivalent: e['civilianEquivalent'] as String,
          description: e['description'] as String,
          verified: e['verified'] as bool? ?? false,
        ),
      )
      .toList();
}
