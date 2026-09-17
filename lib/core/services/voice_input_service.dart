import 'dart:async';

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

// pauseFor below — how long the engine waits for a pause in speech before
// ending a shot on its own. The stall watchdog is set comfortably above
// this so a legitimately silent user (engine working fine, just waiting)
// is never mistaken for a stalled restart.
const _pauseFor = Duration(seconds: 5);
const _stallWatchdogDuration = Duration(seconds: 8);

class SpeechToTextVoiceInputService implements VoiceInputService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _initialized = false;
  bool _sessionActive = false;
  String _accumulatedText = '';
  void Function(String text)? _onResult;
  void Function(bool isListening)? _onListeningChanged;
  Timer? _stallWatchdog;

  @override
  Future<bool> initialize({void Function(bool isListening)? onListeningChanged}) async {
    if (_initialized) return true;
    _onListeningChanged = onListeningChanged;
    _initialized = await _speech.initialize(
      onStatus: (status) {
        _stallWatchdog?.cancel();
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
          // Confirmed on a real iPhone this session: restarting
          // SpeechRecognition with zero delay right after it ends works on
          // desktop Safari/Chrome, but on iOS Safari the restart silently
          // no-ops — recognition never actually re-arms, so no further
          // words are ever captured even though nothing throws and the UI
          // (correctly, per the suppression above) still shows
          // "Listening...". A brief pause before restarting is the
          // standard workaround for this WebKit quirk. _sessionActive is
          // re-checked after the delay in case the user tapped stop while
          // this was pending.
          Future<void>.delayed(const Duration(milliseconds: 350), () {
            if (_sessionActive) _listen();
          });
        }
      },
    );
    return _initialized;
  }

  void _armStallWatchdog() {
    _stallWatchdog?.cancel();
    // Confirmed on a real iPhone this session: the auto-restart above
    // sometimes silently no-ops on iOS Safari — neither onStatus nor
    // onResult ever fires again, leaving the mic button stuck showing
    // "Listening..." in red forever with nothing further captured. If
    // nothing at all happens within this window after asking it to
    // listen, treat that as a failed restart and tell the caller
    // listening has genuinely stopped, rather than leave them staring at
    // a mic that looks active but is silently dead.
    _stallWatchdog = Timer(_stallWatchdogDuration, () {
      if (!_sessionActive) return;
      _sessionActive = false;
      _speech.stop();
      _onListeningChanged?.call(false);
    });
  }

  void _listen() {
    _armStallWatchdog();
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
        _stallWatchdog?.cancel();
        final words = result.recognizedWords;
        if (words.trim().isEmpty) return;
        _accumulatedText = _accumulatedText.isEmpty ? words : '$_accumulatedText $words';
        _onResult?.call(_accumulatedText);
      },
      listenOptions: stt.SpeechListenOptions(
        partialResults: false,
        pauseFor: _pauseFor,
        listenFor: const Duration(seconds: 120),
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
    _stallWatchdog?.cancel();
    await _speech.stop();
  }
}
