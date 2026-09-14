import 'dart:convert';

import 'package:http/http.dart' as http;

import 'skill_equivalency.dart';

const _baseUrl = 'https://next-career-after-fauj-fitment.sandy060965.workers.dev';
const _appSharedKey = String.fromEnvironment('APP_SHARED_KEY');
// Best-effort enrichment — bounded so a stalled connection can't leave this
// pending forever; the caller already treats any failure here as non-fatal.
const _requestTimeout = Duration(seconds: 30);

class CourseCivilianizationException implements Exception {
  CourseCivilianizationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Admin-approved courses that have grown the curated list since the app
/// was last released — merged with [kSkillEquivalencies] at display time
/// (see the Courses section of cv_builder_screen.dart). Best-effort by
/// design at the call site: the curated list alone is already complete and
/// useful, so a failure here should never block or error the whole screen.
Future<List<SkillEquivalency>> httpFetchApprovedEquivalencies() async {
  final response = await http
      .post(
        Uri.parse('$_baseUrl/skill-equivalencies'),
        headers: const {'content-type': 'application/json', 'x-app-key': _appSharedKey},
        body: '{}',
      )
      .timeout(_requestTimeout);
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
