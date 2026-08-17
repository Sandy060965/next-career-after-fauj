import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Thin wrapper around device speech-to-text so the practice screen doesn't
/// depend on the plugin directly — makes it injectable/fakeable in tests.
/// Transcription happens entirely on-device via the OS; nothing spoken is
/// ever sent to the Worker or Claude.
abstract class VoiceInputService {
  Future<bool> initialize();
  Future<void> startListening({required void Function(String text) onResult});
  Future<void> stopListening();
  bool get isListening;
}

class SpeechToTextVoiceInputService implements VoiceInputService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _initialized = false;

  @override
  Future<bool> initialize() async {
    if (_initialized) return true;
    _initialized = await _speech.initialize();
    return _initialized;
  }

  @override
  bool get isListening => _speech.isListening;

  @override
  Future<void> startListening({required void Function(String text) onResult}) async {
    final available = await initialize();
    if (!available) return;
    await _speech.listen(onResult: (result) => onResult(result.recognizedWords));
  }

  @override
  Future<void> stopListening() async {
    await _speech.stop();
  }
}
