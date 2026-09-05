import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'assistant_message.dart';

const _workerUrl = 'https://next-career-after-fauj-fitment.sandy060965.workers.dev/assistant';
const _appSharedKey = String.fromEnvironment('APP_SHARED_KEY');

const _maxAttempts = 3;
const _retryDelay = Duration(seconds: 2);
const _retryableStatusCodes = {502, 503, 504, 522, 523, 524};

class AssistantException implements Exception {
  AssistantException(this.message);

  final String message;

  @override
  String toString() => message;
}

typedef SendAssistantMessage = Future<String> Function({
  required String message,
  required List<AssistantMessage> history,
  String? profileContext,
  String? cvText,
  Uint8List? cvPdfBytes,
  String? attachmentName,
  String? attachmentText,
  Uint8List? attachmentPdfBytes,
});

Future<String> httpSendAssistantMessage({
  required String message,
  required List<AssistantMessage> history,
  String? profileContext,
  String? cvText,
  Uint8List? cvPdfBytes,
  String? attachmentName,
  String? attachmentText,
  Uint8List? attachmentPdfBytes,
}) async {
  final body = <String, dynamic>{
    'message': message,
    'history': [
      for (final turn in history)
        {'role': turn.role == AssistantRole.assistant ? 'assistant' : 'user', 'content': turn.content},
    ],
    if (profileContext != null) 'profileContext': profileContext,
  };
  if (cvPdfBytes != null) {
    body['cvPdfBase64'] = base64Encode(cvPdfBytes);
  } else if (cvText != null) {
    body['cvText'] = cvText;
  }
  if (attachmentName != null) {
    body['attachmentName'] = attachmentName;
    if (attachmentPdfBytes != null) {
      body['attachmentPdfBase64'] = base64Encode(attachmentPdfBytes);
    } else if (attachmentText != null) {
      body['attachmentText'] = attachmentText;
    }
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
    throw AssistantException('Could not reach the assistant: $lastError');
  }
  if (response.statusCode != 200) {
    throw AssistantException('The assistant could not respond (${response.statusCode}): ${response.body}');
  }

  final json = jsonDecode(response.body) as Map<String, dynamic>;
  return json['reply'] as String;
}
