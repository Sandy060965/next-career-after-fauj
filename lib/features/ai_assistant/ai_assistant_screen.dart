import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/document_text_extractor.dart';
import '../../core/services/file_picker_service.dart';
import '../../core/services/profile_repository.dart';
import '../../core/services/standalone_mode_stub.dart'
    if (dart.library.html) '../../core/services/standalone_mode_web.dart' as platform_mode;
import '../../core/services/transition_readiness.dart';
import '../../core/services/voice_input_service.dart';
import '../../core/widgets/home_button.dart';
import 'ai_assistant_http_service.dart';
import 'ai_assistant_service.dart';
import 'assistant_message.dart';

// PDF is included alongside DOCX/TXT: Claude reads PDF bytes natively (same
// as the CV upload), so no client-side extraction is needed for it — see
// _pickAttachment.
Future<PickedFile?> _defaultPickAttachment() =>
    pickFileWithBytes(allowedExtensions: const ['pdf', 'docx', 'txt']);

class _QuickAction {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.prompt,
    this.sendImmediately = true,
    this.hint,
  });

  final String label;
  final IconData icon;
  final String prompt;

  /// True sends [prompt] straight into the chat; false just fills the text
  /// field (for prompts that need the officer to complete them — pasting a
  /// JD, naming a term) so nothing is sent half-finished.
  final bool sendImmediately;

  /// Shown as a small banner above the input row once this action is picked
  /// — for an action that needs the officer to supply something themselves,
  /// this is where every way of supplying it is spelled out explicitly,
  /// rather than relying on them to notice the paperclip button is also an
  /// option for whatever this action asked for.
  final String? hint;
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
    hint: 'Paste the JD text below the prompt, or tap the 📎 icon to attach it as a PDF, DOCX or '
        'TXT file instead — either way works.',
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
    this.pickFile = _defaultPickAttachment,
    VoiceInputService? voiceInputService,
  }) : voiceInputService = voiceInputService ?? SpeechToTextVoiceInputService();

  /// Overridable for testing; defaults to sample data until the Cloudflare
  /// Worker backend is wired in.
  final SendAssistantMessage sendMessage;

  /// Overridable for testing so the native file-picker channel never needs
  /// to be invoked.
  final Future<PickedFile?> Function() pickFile;

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
  bool _gotVoiceResult = false;
  String? _voiceError;
  String? _error;

  String? _attachmentName;
  String? _attachmentText;
  Uint8List? _attachmentPdfBytes;
  bool _isProcessingAttachment = false;
  String? _attachmentError;
  String? _activeHint;

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
    // Confirmed this session: Safari's speech recognition silently produces
    // zero results when the site is running as an installed home-screen
    // app, even though it works in a plain Safari tab on the same device —
    // catch this up front rather than let a doomed attempt run.
    if (platform_mode.isRunningAsInstalledApp()) {
      setState(
        () => _voiceError =
            "Voice input doesn't work in the installed app — open the site in your browser "
            'instead (not the home-screen icon) to use the mic.',
      );
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
              _voiceError = "Didn't catch that — try again or type your question.";
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
            _controller.text = text;
            _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
            if (text.trim().isNotEmpty) _gotVoiceResult = true;
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isListening = false;
        _voiceError = "Couldn't use the microphone — try again or type your question.";
      });
    }
  }

  Future<void> _pickAttachment() async {
    final PickedFile? picked;
    try {
      picked = await widget.pickFile();
    } on UnsupportedFileTypeException catch (e) {
      setState(() => _attachmentError = e.message);
      return;
    }
    if (picked == null) {
      if (platform_mode.isRunningAsInstalledApp()) {
        setState(() => _attachmentError = kInstalledAppFilePickerHint);
      }
      return;
    }
    final file = picked;

    setState(() {
      _attachmentName = file.name;
      _attachmentText = null;
      _attachmentPdfBytes = null;
      _attachmentError = null;
    });

    final extension = file.name.split('.').last.toLowerCase();
    if (extension == 'pdf') {
      // A very large PDF can take long enough to base64-encode client-side
      // before the request that the chat looks stuck rather than just slow.
      if (file.bytes.lengthInBytes > kMaxUploadPdfBytes) {
        setState(() {
          _attachmentName = null;
          _attachmentError =
              'This PDF is larger than $kMaxUploadPdfMb MB, which can make the assistant hang. '
              'Try a smaller/compressed PDF, or paste the text into your message instead.';
        });
        return;
      }
      // Claude reads PDFs natively — no client-side extraction needed.
      setState(() => _attachmentPdfBytes = file.bytes);
      return;
    }
    if (extension == 'txt') {
      setState(() => _attachmentText = utf8.decode(file.bytes, allowMalformed: true));
      return;
    }

    setState(() => _isProcessingAttachment = true);
    try {
      final text = await extractDocxText(file.bytes);
      if (!mounted) return;
      setState(() {
        _attachmentText = text;
        _isProcessingAttachment = false;
      });
    } on DocxExtractionException catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessingAttachment = false;
        _attachmentName = null;
        _attachmentError = "Couldn't read this file's text ($e). Try a different file instead.";
      });
    }
  }

  void _removeAttachment() {
    setState(() {
      _attachmentName = null;
      _attachmentText = null;
      _attachmentPdfBytes = null;
      _attachmentError = null;
    });
  }

  void _applyQuickAction(_QuickAction action) {
    if (action.sendImmediately) {
      _send(action.prompt);
    } else {
      _controller.text = action.prompt;
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
      _focusNode.requestFocus();
      setState(() => _activeHint = action.hint);
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
      _activeHint = null;
    });
    _scrollToEnd();

    try {
      final reply = await widget.sendMessage(
        message: trimmed,
        history: history,
        profileContext: _buildProfileContext(repo),
        cvText: profile?.cvExtractedText,
        cvPdfBytes: profile?.cvPdfBytes,
        attachmentName: _attachmentName,
        attachmentText: _attachmentText,
        attachmentPdfBytes: _attachmentPdfBytes,
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
      appBar: AppBar(
        title: const Text('How can I help with your transition?'),
        actions: const [HomeButton()],
      ),
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
          if (_activeHint != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                key: const Key('assistantQuickActionHint'),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Theme.of(context).colorScheme.onTertiaryContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _activeHint!,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Theme.of(context).colorScheme.onTertiaryContainer),
                      ),
                    ),
                    IconButton(
                      key: const Key('dismissQuickActionHintButton'),
                      icon: const Icon(Icons.close, size: 16),
                      visualDensity: VisualDensity.compact,
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                      onPressed: () => setState(() => _activeHint = null),
                    ),
                  ],
                ),
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
          if (_attachmentError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _attachmentError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
              ),
            ),
          if (_attachmentName != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  key: const Key('assistantAttachmentChip'),
                  avatar: const Icon(Icons.attach_file, size: 16),
                  label: Text(_attachmentName!),
                  onDeleted: _removeAttachment,
                  deleteIconColor: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  IconButton(
                    key: const Key('assistantAttachButton'),
                    icon: _isProcessingAttachment
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.attach_file_outlined),
                    tooltip: 'Attach a document (e.g. a job description)',
                    onPressed: _isSending || _isProcessingAttachment ? null : _pickAttachment,
                  ),
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
          'what comes next. Use the paperclip below to attach a document (or paste its text '
          'straight into your message) — either way works.',
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
