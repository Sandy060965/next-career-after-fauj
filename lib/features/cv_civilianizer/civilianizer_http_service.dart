import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'civilianized_cv.dart';

const _workerUrl = 'https://next-career-after-fauj-fitment.sandy060965.workers.dev/civilianize-cv';
const _appSharedKey = String.fromEnvironment('APP_SHARED_KEY');
const _maxAttempts = 3;
const _retryDelay = Duration(seconds: 2);
const _retryableStatusCodes = {502, 503, 504, 522, 523, 524};

class CivilianizerException implements Exception {
  CivilianizerException(this.message);

  final String message;

  @override
  String toString() => message;
}

Future<CivilianizedCv> httpCivilianizeCv({
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
    throw CivilianizerException('Could not reach the CV service: $lastError');
  }
  if (response.statusCode != 200) {
    throw CivilianizerException('Civilianizing your CV failed (${response.statusCode}): ${response.body}');
  }

  final json = jsonDecode(response.body) as Map<String, dynamic>;
  return CivilianizedCv(
    civilianizedCv: json['civilianized_cv'] as String,
    translationNotes:
        (json['translation_notes'] as List? ?? const []).map((e) => e as String).toList(),
  );
}
