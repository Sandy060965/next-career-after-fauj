import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'linkedin_writeup.dart';

const _workerUrl = 'https://next-career-after-fauj-fitment.sandy060965.workers.dev/linkedin-writeup';
const _appSharedKey = String.fromEnvironment('APP_SHARED_KEY');
const _maxAttempts = 3;
const _retryDelay = Duration(seconds: 2);
const _retryableStatusCodes = {502, 503, 504, 522, 523, 524};

class LinkedInWriteupException implements Exception {
  LinkedInWriteupException(this.message);

  final String message;

  @override
  String toString() => message;
}

Future<LinkedInWriteup> httpGenerateLinkedInWriteup({
  required String cvText,
  Uint8List? cvPdfBytes,
}) async {
  final body = <String, dynamic>{};
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
    throw LinkedInWriteupException('Could not reach the write-up service: $lastError');
  }
  if (response.statusCode != 200) {
    throw LinkedInWriteupException(
      'Write-up generation failed (${response.statusCode}): ${response.body}',
    );
  }

  final json = jsonDecode(response.body) as Map<String, dynamic>;
  return LinkedInWriteup(
    headline: json['headline'] as String,
    aboutSection: json['about_section'] as String,
    announcementPost: json['announcement_post'] as String,
  );
}
