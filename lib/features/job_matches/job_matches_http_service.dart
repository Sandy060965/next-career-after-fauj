import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../career_paths/corps_affinity.dart';
import 'india_cities.dart';
import 'job_match.dart';

const _workerUrl = 'https://next-career-after-fauj-fitment.sandy060965.workers.dev/job-matches';
const _appSharedKey = String.fromEnvironment('APP_SHARED_KEY');
const _maxAttempts = 3;
const _retryDelay = Duration(seconds: 2);
const _retryableStatusCodes = {502, 503, 504, 522, 523, 524};

class JobMatchesException implements Exception {
  JobMatchesException(this.message);

  final String message;

  @override
  String toString() => message;
}

Future<List<JobMatch>> httpAnalyzeJobMatches({
  required String cvText,
  CityTier? cityTier,
  Uint8List? cvPdfBytes,
  String? corpsOrArm,
}) async {
  // For a domain-constrained officer (AMC, JAG), the query and result
  // filter are computed deterministically here from their Corps/Arm — see
  // corps_affinity.dart — rather than left to the Worker's CV-derived
  // query, which carries no domain signal at all.
  final overrideQuery = domainConstrainedJobQuery(corpsOrArm);
  final titleKeywords = domainConstrainedJobTitleKeywords(corpsOrArm);
  final body = <String, dynamic>{
    if (cityTier != null) 'cityTier': cityTier == CityTier.tier1 ? 'tier1' : 'tier2',
    if (overrideQuery != null) 'overrideQuery': overrideQuery,
    if (titleKeywords != null) 'titleKeywords': titleKeywords,
  };
  if (cvPdfBytes != null) {
    body['cvPdfBase64'] = base64Encode(cvPdfBytes);
  } else {
    body['cvText'] = cvText;
  }
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
    throw JobMatchesException('Could not reach the job search service: $lastError');
  }
  if (response.statusCode != 200) {
    throw JobMatchesException(
      'Job search failed (${response.statusCode}): ${response.body}',
    );
  }

  final json = jsonDecode(response.body) as Map<String, dynamic>;
  return (json['matches'] as List)
      .map(
        (m) => JobMatch(
          title: m['title'] as String,
          company: m['company'] as String,
          portal: JobPortalLabel.fromUrl(m['applyUrl'] as String),
          applyUrl: m['applyUrl'] as String,
          fitReason: m['fitReason'] as String,
          location: m['location'] as String?,
          postedDate: m['postedDate'] as String?,
          ctcRange: m['ctcRange'] as String?,
          isTopCompany: m['isTopCompany'] as bool? ?? false,
        ),
      )
      .toList();
}
