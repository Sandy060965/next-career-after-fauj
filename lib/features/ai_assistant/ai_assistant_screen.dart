import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/profile_repository.dart';
import '../../core/services/transition_readiness.dart';
import '../../core/services/voice_input_service.dart';
import 'ai_assistant_http_service.dart';
import 'ai_assistant_service.dart';
import 'assistant_message.dart';

class _QuickAction {
  const _QuickAction({required this.label, required this.icon, required this.prompt, this.sendImmediately = true});

  final String label;
  final IconData icon;
  final String prompt;

  /// True sends [prompt] straight into the chat; false just fills the text
  /// field (for prompts that need the officer to complete them — pasting a
  /// JD, naming a term) so nothing is sent half-finished.
  final bool sendImmediately;
}

const _quickActions = [
  _QuickAction(
    label: 'Analyse my CV',
    icon: Icons.description_outlined,
    prompt: 'Can you give me a quick analysis of my CV — its main strengths and any gaps I '
        'should be aware of?',
  ),
  _QuickAction(
    label: 'Explain this corporate term',
    icon: Icons.menu_book_outlined,
    prompt: 'Explain this corporate term: ',
    sendImmediately: false,
  ),
  _QuickAction(
    label: 'Compare this JD',
    icon: Icons.compare_arrows_outlined,
    prompt: 'Here is a job description I am considering — how well does my profile match it?\n\n',
    sendImmediately: false,
  ),
  _QuickAction(
    label: 'Prepare me for an interview',
    icon: Icons.record_voice_over_outlined,
    prompt: 'What should I focus on to prepare for an interview, based on what you know about '
        'my profile so far?',
  ),
  _QuickAction(
    label: 'Help me understand this offer',
    icon: Icons.payments_outlined,
    prompt: 'Can you help me understand my compensation comparison and what I should look out '
        'for?',
  ),
];

/// Builds a plain-text summary of only the officer's real, already-computed
/// state — never a fabricated fact — for the assistant to ground its
/// replies in. Anything not yet completed is stated as such explicitly, so
/// the assistant tells the officer to go complete it rather than guessing.
String _buildProfileContext(ProfileRepository repo) {
  final profile = repo.profile;
  final summary = TransitionReadinessSummary.fromRepository(repo);
  final buffer = StringBuffer();
  if (profile != null) {
    buffer.writeln('Rank: ${profile.rank}, Service: ${profile.service.label}, '
        'Segment: ${profile.segment.fullLabel}');
  }
  for (final dimension in summary.dimensions) {
    buffer.writeln(
      dimension.score == null
          ? '${dimension.label}: not yet completed'
          : '${dimension.label}: ${dimension.score}/100',
    );
  }
  buffer.writeln(
    repo.lastTargetRoleStrategy == null
        ? 'Target Role Strategy: not yet completed'
        : 'Target Role Strategy: completed',
  );
  buffer.writeln(
    repo.lastFinancialPlanInput == null
        ? 'Financial/compensation plan: not yet completed'
        : 'Financial/compensation plan: completed',
  );
  buffer.writeln('Job applications tracked: ${repo.applications.length}');
  return buffer.toString();
}

class AiAssistantScreen extends StatefulWidget {
  AiAssistantScreen({
    super.key,
    this.sendMessage = mockSendAssistantMessage,
    VoiceInputService? voiceInputService,
  }) : voiceInputService = voiceInputService ?? SpeechToTextVoiceInputService();

  /// Overridable for testing; defaults to sample data until the Cloudflare
  /// Worker backend is wired in.
  final SendAssistantMessage sendMessage;

  /// Overridable for testing so the native speech-recognition channel never
  /// needs to be invoked. Transcription happens entirely on-device via the
  /// OS — nothing spoken is sent anywhere until the officer taps send, same
  /// as typed text.
  final VoiceInputService voiceInputService;

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final List<AssistantMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isSending = false;
  bool _isListening = false;
  String? _voiceError;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
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
        setState(() {
          _controller.text = text;
          _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
        });
      },
    );
  }

  void _applyQuickAction(_QuickAction action) {
    if (action.sendImmediately) {
      _send(action.prompt);
    } else {
      _controller.text = action.prompt;
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
      _focusNode.requestFocus();
    }
  }

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isSending) return;

    final repo = context.read<ProfileRepository>();
    final profile = repo.profile;

    if (_isListening) {
      await widget.voiceInputService.stopListening();
      _isListening = false;
    }

    final history = List<AssistantMessage>.of(_messages);

    setState(() {
      _messages.add(AssistantMessage(role: AssistantRole.user, content: trimmed));
      _controller.clear();
      _isSending = true;
      _error = null;
    });
    _scrollToEnd();

    try {
      final reply = await widget.sendMessage(
        message: trimmed,
        history: history,
        profileContext: _buildProfileContext(repo),
        cvText: profile?.cvExtractedText,
        cvPdfBytes: profile?.cvPdfBytes,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(AssistantMessage(role: AssistantRole.assistant, content: reply));
        _isSending = false;
      });
      _scrollToEnd();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _error = '$e';
      });
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('How can I help with your transition?')),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _QuickActionsPanel(onSelect: _applyQuickAction)
                : ListView.builder(
                    key: const Key('assistantMessageList'),
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) => _MessageBubble(message: _messages[index]),
                  ),
          ),
          if (_isSending)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          if (_voiceError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _voiceError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('assistantInputField'),
                      controller: _controller,
                      focusNode: _focusNode,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: _isListening ? 'Listening...' : 'Ask a question, or use the mic...',
                        suffixIcon: IconButton(
                          key: const Key('assistantMicButton'),
                          icon: Icon(_isListening ? Icons.mic : Icons.mic_none_outlined),
                          color: _isListening ? Theme.of(context).colorScheme.error : null,
                          tooltip: _isListening ? 'Stop listening' : 'Use microphone',
                          onPressed: _isSending ? null : _toggleListening,
                        ),
                      ),
                      onSubmitted: _send,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    key: const Key('assistantSendButton'),
                    onPressed: _isSending ? null : () => _send(_controller.text),
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsPanel extends StatelessWidget {
  const _QuickActionsPanel({required this.onSelect});

  final ValueChanged<_QuickAction> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(Icons.auto_awesome_outlined, size: 40, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 12),
        Text(
          'Ask about your CV, a job description, a corporate term, or how to prepare for '
          'what comes next.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        for (final action in _quickActions)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton.icon(
              key: ValueKey('quickAction_${action.label}'),
              onPressed: () => onSelect(action),
              icon: Icon(action.icon, size: 18),
              label: Align(alignment: Alignment.centerLeft, child: Text(action.label)),
              style: OutlinedButton.styleFrom(alignment: Alignment.centerLeft),
            ),
          ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final AssistantMessage message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUser = message.role == AssistantRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        key: ValueKey('assistantBubble_${message.role.name}_${message.content.hashCode}'),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        decoration: BoxDecoration(
          color: isUser ? colorScheme.primary : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.content,
          style: TextStyle(color: isUser ? colorScheme.onPrimary : colorScheme.onSurface),
        ),
      ),
    );
  }
}
