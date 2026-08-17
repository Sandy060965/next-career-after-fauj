import 'package:flutter/material.dart';

import 'mock_interview_feedback.dart';
import 'mock_interview_service.dart';
import 'voice_input_service.dart';

class MockInterviewScreen extends StatefulWidget {
  MockInterviewScreen({
    super.key,
    required this.questions,
    this.jdText,
    this.analyzeAnswer = mockAnalyzeInterviewAnswer,
    VoiceInputService? voiceInputService,
  }) : voiceInputService = voiceInputService ?? SpeechToTextVoiceInputService();

  final List<String> questions;
  final String? jdText;

  /// Overridable for testing; defaults to sample data until the Cloudflare
  /// Worker backend is wired in.
  final MockInterviewAnalyzer analyzeAnswer;

  /// Overridable for testing so the native speech-recognition channel never
  /// needs to be invoked.
  final VoiceInputService voiceInputService;

  @override
  State<MockInterviewScreen> createState() => _MockInterviewScreenState();
}

class _MockInterviewScreenState extends State<MockInterviewScreen> {
  final TextEditingController _answerController = TextEditingController();
  int _index = 0;
  bool _isListening = false;
  bool _isSubmitting = false;
  String? _voiceError;
  MockInterviewFeedback? _feedback;

  bool get _isLastQuestion => _index == widget.questions.length - 1;

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
    final available = await widget.voiceInputService.initialize();
    if (!available) {
      if (!mounted) return;
      setState(() => _voiceError = 'Speech recognition isn\'t available on this device.');
      return;
    }
    setState(() {
      _isListening = true;
      _voiceError = null;
    });
    await widget.voiceInputService.startListening(
      onResult: (text) {
        if (!mounted) return;
        setState(() => _answerController.text = text);
      },
    );
  }

  Future<void> _submitAnswer() async {
    final answer = _answerController.text.trim();
    if (answer.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final feedback = await widget.analyzeAnswer(
        question: widget.questions[_index],
        answer: answer,
        jdText: widget.jdText,
      );
      if (!mounted) return;
      setState(() {
        _feedback = feedback;
        _isSubmitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  void _nextQuestion() {
    if (_isLastQuestion) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _index += 1;
      _feedback = null;
      _answerController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mock Interview — Question ${_index + 1} of ${widget.questions.length}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              key: const Key('mockInterviewProgress'),
              value: (_index + 1) / widget.questions.length,
            ),
            const SizedBox(height: 16),
            Text(widget.questions[_index], style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            TextField(
              key: const Key('mockAnswerField'),
              controller: _answerController,
              maxLines: 6,
              enabled: _feedback == null,
              decoration: InputDecoration(
                hintText: 'Answer out loud via the microphone, or type it...',
                suffixIcon: IconButton(
                  key: const Key('mockMicButton'),
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none_outlined),
                  color: _isListening ? Theme.of(context).colorScheme.error : null,
                  onPressed: _feedback == null ? _toggleListening : null,
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
            const SizedBox(height: 16),
            if (_feedback == null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('submitAnswerButton'),
                  onPressed: _isSubmitting ? null : _submitAnswer,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit answer'),
                ),
              )
            else ...[
              _FeedbackCard(feedback: _feedback!),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('nextQuestionButton'),
                  onPressed: _nextQuestion,
                  child: Text(_isLastQuestion ? 'Finish' : 'Next question'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.feedback});

  final MockInterviewFeedback feedback;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('feedbackCard'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(feedback.overallImpression, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Text('Strengths', style: Theme.of(context).textTheme.titleSmall),
            for (final s in feedback.strengths)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('• $s'),
              ),
            const SizedBox(height: 12),
            Text('To improve', style: Theme.of(context).textTheme.titleSmall),
            for (final i in feedback.improvements)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('• $i'),
              ),
          ],
        ),
      ),
    );
  }
}
