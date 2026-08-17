import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'fitment_result.dart';

const _workerUrl = 'https://next-career-after-fauj-fitment.sandy060965.workers.dev';

// Passed at build/run time so the shared secret never lives in source
// control: flutter run --dart-define=APP_SHARED_KEY=<value>
const _appSharedKey = String.fromEnvironment('APP_SHARED_KEY');

class FitmentAnalysisException implements Exception {
  FitmentAnalysisException(this.message);

  final String message;

  @override
  String toString() => message;
}

const _maxAttempts = 3;
const _retryDelay = Duration(seconds: 2);

/// Status codes worth retrying: gateway/upstream timeouts and transient
/// server errors. Deliberately excludes 401 (bad key) and 400 (bad
/// request) — retrying those would just fail the same way again.
const _retryableStatusCodes = {502, 503, 504, 522, 523, 524};

Future<FitmentResult> httpAnalyzeFitment({
  required String jdText,
  required String cvFileName,
  String? cvExtractedText,
  Uint8List? cvPdfBytes,
}) async {
  // Prefer real content: extracted .docx text, or the raw PDF (Claude reads
  // PDFs natively, so no client-side extraction needed there). Only fall
  // back to sending the bare filename if neither is available — the Worker
  // treats that case as "no CV content" rather than fabricating from it.
  final body = <String, dynamic>{'jdText': jdText};
  if (cvPdfBytes != null) {
    body['cvPdfBase64'] = base64Encode(cvPdfBytes);
  } else {
    body['cvText'] = cvExtractedText ?? cvFileName;
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
    throw FitmentAnalysisException('Could not reach the analysis service: $lastError');
  }

  if (response.statusCode != 200) {
    throw FitmentAnalysisException(
      'Analysis failed (${response.statusCode}): ${response.body}',
    );
  }

  final json = jsonDecode(response.body) as Map<String, dynamic>;
  return FitmentResult(
    fitmentScore: json['fitment_score'] as int,
    scoreRationale: json['score_rationale'] as String,
    requirementBreakdown: (json['requirement_breakdown'] as List)
        .map(
          (e) => RequirementBreakdownItem(
            requirement: e['requirement'] as String,
            status: _parseStatus(e['status'] as String),
            notes: e['notes'] as String,
          ),
        )
        .toList(),
    originalCvExcerpt: json['original_cv_excerpt'] as String? ?? '',
    refinedCv: json['refined_cv'] as String,
    certificationGuidance: (json['certification_guidance'] as List)
        .map(
          (e) => CertificationRecommendation(
            name: e['name'] as String,
            closesGap: e['closes_gap'] as String,
            timeToAcquire: e['time_to_acquire'] as String,
            priority: e['priority'] as int,
          ),
        )
        .toList(),
  );
}

RequirementStatus _parseStatus(String raw) => switch (raw) {
      'Met' => RequirementStatus.met,
      'Partially Met' => RequirementStatus.partiallyMet,
      _ => RequirementStatus.gap,
    };
