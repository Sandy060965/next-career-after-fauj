import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'aptitude_question.dart';
import 'cv_evidence.dart';

const _workerUrl = 'https://next-career-after-fauj-fitment.sandy060965.workers.dev/cv-evidence';
const _appSharedKey = String.fromEnvironment('APP_SHARED_KEY');
const _maxAttempts = 3;
const _retryDelay = Duration(seconds: 2);
const _retryableStatusCodes = {502, 503, 504, 522, 523, 524};

class CvEvidenceException implements Exception {
  CvEvidenceException(this.message);

  final String message;

  @override
  String toString() => message;
}

Future<CvEvidenceResult> httpGroundCvEvidence({
  required String cvText,
  Uint8List? cvPdfBytes,
  required List<VerticalEvidenceRequest> requests,
}) async {
  final body = <String, dynamic>{
    'verticals': requests
        .map(
          (r) => {
            'vertical': r.verticalName,
            'dimensions': r.dimensions.map((d) => d.label).toList(),
          },
        )
        .toList(),
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
    throw CvEvidenceException('Could not reach the CV evidence service: $lastError');
  }
  if (response.statusCode != 200) {
    throw CvEvidenceException(
      'Checking your CV for evidence failed (${response.statusCode}): ${response.body}',
    );
  }

  final json = jsonDecode(response.body) as Map<String, dynamic>;
  final rawVerticals = (json['verticals'] as List? ?? const []);
  // Match by vertical/dimension name rather than trusting response order —
  // never trust the model's own echo blindly.
  final rawByVertical = <String, Map<String, dynamic>>{
    for (final r in rawVerticals)
      if (r is Map && r['vertical'] is String) r['vertical'] as String: r as Map<String, dynamic>,
  };

  final verticals = requests.map((req) {
    final raw = rawByVertical[req.verticalName];
    final rawDims = (raw?['dimensions'] as List? ?? const []);
    final rawDimByLabel = <String, Map<String, dynamic>>{
      for (final d in rawDims)
        if (d is Map && d['dimension'] is String) d['dimension'] as String: d as Map<String, dynamic>,
    };
    return VerticalEvidence(
      verticalName: req.verticalName,
      dimensionEvidence: req.dimensions.map((dim) {
        final rawDim = rawDimByLabel[dim.label];
        return DimensionEvidence(
          dimension: dim,
          found: rawDim?['found'] as bool? ?? false,
          evidence: rawDim?['evidence'] as String?,
        );
      }).toList(),
    );
  }).toList();

  return CvEvidenceResult(verticals: verticals);
}
