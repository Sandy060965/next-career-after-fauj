import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/profile_repository.dart';
import '../../core/widgets/home_button.dart';
import 'support_ticket_service.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key, this.submitTicket = httpSubmitSupportTicket});

  /// Overridable for testing; defaults to the real backend call.
  final SubmitSupportTicket submitTicket;

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _controller = TextEditingController();
  bool _isSending = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final message = _controller.text.trim();
    if (message.isEmpty) {
      setState(() => _error = 'Please describe what you need help with.');
      return;
    }
    setState(() {
      _isSending = true;
      _error = null;
    });
    try {
      await widget.submitTicket(
        repository: context.read<ProfileRepository>(),
        message: message,
      );
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _sent = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support'), actions: const [HomeButton()]),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (_sent) ...[
            Icon(Icons.check_circle_outline, color: Theme.of(context).colorScheme.primary, size: 40),
            const SizedBox(height: 12),
            const Text(
              "Thanks — your message has been sent. We'll get back to you as soon as we can.",
              key: Key('supportTicketSentMessage'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              key: const Key('sendAnotherSupportMessageButton'),
              onPressed: () => setState(() {
                _sent = false;
                _controller.clear();
              }),
              child: const Text('Send another message'),
            ),
          ] else ...[
            Text(
              'Stuck on something, found a bug, or have a question about your transition '
              "plan? Describe it below and we'll get back to you directly.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            TextField(
              key: const Key('supportMessageField'),
              controller: _controller,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'What do you need help with?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('submitSupportTicketButton'),
                onPressed: _isSending ? null : _submit,
                child: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
