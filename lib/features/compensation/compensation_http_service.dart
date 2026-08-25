import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'compensation_estimate.dart';

const _workerUrl = 'https://next-career-after-fauj-fitment.sandy060965.workers.dev/compensation';
const _appSharedKey = String.fromEnvironment('APP_SHARED_KEY');
const _maxAttempts = 3;
const _retryDelay = Duration(seconds: 2);
const _retryableStatusCodes = {502, 503, 504, 522, 523, 524};

class CompensationException implements Exception {
  CompensationException(this.message);

  final String message;

  @override
  String toString() => message;
}

Future<CompensationEstimate> httpEstimateCompensation({
  required String jdText,
  Uint8List? jdPdfBytes,
  String? cvText,
}) async {
  final encodedBody = jsonEncode({
    if (jdPdfBytes != null) 'jdPdfBase64': base64Encode(jdPdfBytes) else 'jdText': jdText,
  });

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
    throw CompensationException('Could not reach the compensation service: $lastError');
  }
  if (response.statusCode != 200) {
    throw CompensationException(
      'Compensation guidance failed (${response.statusCode}): ${response.body}',
    );
  }

  final json = jsonDecode(response.body) as Map<String, dynamic>;
  return CompensationEstimate(
    jobTitle: json['job_title'] as String,
    location: json['location'] as String,
    locationIsEstimate: json['location_is_estimate'] as bool? ?? false,
    requestedLocation: json['requested_location'] as String?,
    minSalary: json['min_salary'] as num?,
    maxSalary: json['max_salary'] as num?,
    medianSalary: json['median_salary'] as num?,
    currency: json['salary_currency'] as String?,
    period: json['salary_period'] as String?,
    confidence: json['confidence'] as String?,
    publisher: json['publisher_name'] as String?,
    negotiationGuidance: json['negotiation_guidance'] as String,
  );
}
