import 'package:flutter/material.dart';

import 'interview_question.dart';
import '../../core/services/voice_input_service.dart';
import '../../core/widgets/home_button.dart';

class InterviewPracticeScreen extends StatefulWidget {
  InterviewPracticeScreen({super.key, required this.question, VoiceInputService? voiceInputService})
      : voiceInputService = voiceInputService ?? SpeechToTextVoiceInputService();

  final InterviewQuestion question;

  /// Overridable for testing so the native speech-recognition channel never
  /// needs to be invoked.
  final VoiceInputService voiceInputService;

  @override
  State<InterviewPracticeScreen> createState() => _InterviewPracticeScreenState();
}

class _InterviewPracticeScreenState extends State<InterviewPracticeScreen> {
  final TextEditingController _answerController = TextEditingController();
  bool _isListening = false;
  bool _gotVoiceResult = false;
  String? _voiceError;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await widget.voiceInputService.stopListening();
      if (!mounted) return;
      setState(() => _isListening = false);
      return;
    }

    // The underlying plugin can throw on some browsers rather than
    // resolving `initialize()` to false (e.g. an unexpected mic-permission
    // API shape on iOS Safari) — without this, that exception was silently
    // swallowed by Flutter's zone error handling and the mic button just
    // did nothing at all, with no feedback of any kind.
    try {
      final available = await widget.voiceInputService.initialize(
        onListeningChanged: (listening) {
          if (!mounted) return;
          setState(() {
            final wasListening = _isListening;
            _isListening = listening;
            if (wasListening && !listening && !_gotVoiceResult) {
              _voiceError = "Didn't catch that — try again or type your answer.";
            }
          });
        },
      );
      if (!available) {
        if (!mounted) return;
        setState(() => _voiceError = 'Speech recognition isn\'t available on this device.');
        return;
      }

      setState(() {
        _isListening = true;
        _gotVoiceResult = false;
        _voiceError = null;
      });
      await widget.voiceInputService.startListening(
        onResult: (text) {
          if (!mounted) return;
          setState(() {
            _answerController.text = text;
            if (text.trim().isNotEmpty) _gotVoiceResult = true;
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isListening = false;
        _voiceError = "Couldn't use the microphone — try again or type your answer.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.question.category;
    return Scaffold(
      appBar: AppBar(title: const Text('Practice'), actions: const [HomeButton()]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Chip(label: Text(category.label), visualDensity: VisualDensity.compact),
            const SizedBox(height: 12),
            Text(widget.question.question, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Card(
              key: const Key('categoryGuidanceCard'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('How to approach this', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Text(category.guidance, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Draft your answer', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Type it out, or tap the microphone to dictate — nothing you say leaves this '
              'device.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('practiceAnswerField'),
              controller: _answerController,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: 'Your practice answer...',
                suffixIcon: IconButton(
                  key: const Key('micButton'),
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none_outlined),
                  color: _isListening ? Theme.of(context).colorScheme.error : null,
                  tooltip: _isListening ? 'Stop dictating' : 'Dictate your answer',
                  onPressed: _toggleListening,
                ),
              ),
            ),
            if (_voiceError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _voiceError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
