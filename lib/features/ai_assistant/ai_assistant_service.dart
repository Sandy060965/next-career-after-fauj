import 'dart:typed_data';

import 'assistant_message.dart';

/// Placeholder reply used until the Cloudflare Worker backend is wired in,
/// so the chat screen can be built and tested independently of the backend.
Future<String> mockSendAssistantMessage({
  required String message,
  required List<AssistantMessage> history,
  String? profileContext,
  String? cvText,
  Uint8List? cvPdfBytes,
  String? attachmentName,
  String? attachmentText,
  Uint8List? attachmentPdfBytes,
}) async {
  await Future.delayed(const Duration(milliseconds: 500));
  return "I'm a placeholder reply — the real assistant isn't wired in yet in this context.";
}
