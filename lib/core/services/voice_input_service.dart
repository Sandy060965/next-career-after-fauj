import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Thin wrapper around device speech-to-text so the practice screen doesn't
/// depend on the plugin directly — makes it injectable/fakeable in tests.
/// Transcription happens entirely on-device via the OS; nothing spoken is
/// ever sent to the Worker or Claude.
abstract class VoiceInputService {
  Future<bool> initialize({void Function(bool isListening)? onListeningChanged});
  Future<void> startListening({required void Function(String text) onResult});
  Future<void> stopListening();
  bool get isListening;
}

class SpeechToTextVoiceInputService implements VoiceInputService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _initialized = false;
  bool _sessionActive = false;
  String _accumulatedText = '';
  void Function(String text)? _onResult;

  @override
  Future<bool> initialize({void Function(bool isListening)? onListeningChanged}) async {
    if (_initialized) return true;
    _initialized = await _speech.initialize(
      onStatus: (status) {
        final listening = status == stt.SpeechToText.listeningStatus;
        // Safari/WebKit (see _listen below) only ever delivers one short
        // final result — often just a handful of words — per listen()
        // call, then reports notListening on its own even mid-sentence.
        // Re-starting automatically here, rather than requiring the user
        // to notice and re-tap the mic every few words, is what turns that
        // into something closer to continuous dictation. The caller only
        // hears about a real "stopped listening" transition (not one of
        // these transient inter-shot gaps), so its UI keeps showing
        // "Listening..." throughout instead of flickering every few words.
        if (listening || !_sessionActive) {
          onListeningChanged?.call(listening);
        }
        if (!listening && _sessionActive) {
          _listen();
        }
      },
    );
    return _initialized;
  }

  void _listen() {
    // partialResults defaults to true in the plugin, which on web also sets
    // both interimResults and continuous to true on the browser's
    // SpeechRecognition object — the two modes documented as unreliable on
    // Safari/WebKit (interim results often never fire; continuous mode
    // produces a forever-growing single result that never finalizes).
    // Forcing partialResults: false switches Safari into single-shot,
    // final-result-only recognition, which is the mode it actually
    // supports. pauseFor/listenFor bound each shot so it reliably ends and
    // delivers a result instead of listening indefinitely.
    _speech.listen(
      onResult: (result) {
        final words = result.recognizedWords;
        if (words.trim().isEmpty) return;
        _accumulatedText = _accumulatedText.isEmpty ? words : '$_accumulatedText $words';
        _onResult?.call(_accumulatedText);
      },
      listenOptions: stt.SpeechListenOptions(
        partialResults: false,
        pauseFor: Duration(seconds: 5),
        listenFor: Duration(seconds: 120),
      ),
    );
  }

  @override
  bool get isListening => _speech.isListening;

  @override
  Future<void> startListening({required void Function(String text) onResult}) async {
    final available = await initialize();
    if (!available) return;
    _onResult = onResult;
    _accumulatedText = '';
    _sessionActive = true;
    _listen();
  }

  @override
  Future<void> stopListening() async {
    _sessionActive = false;
    await _speech.stop();
  }
}
