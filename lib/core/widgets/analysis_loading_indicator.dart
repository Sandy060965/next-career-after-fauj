import 'dart:async';

import 'package:flutter/material.dart';

/// A small progress spinner paired with rotating status text, so a
/// multi-second AI analysis reads as "working through real steps" rather
/// than an indefinite, possibly-stuck spinner. Cycles through [messages] in
/// order and holds on the last one — never loops back to implying the work
/// just started over.
class AnalysisLoadingIndicator extends StatefulWidget {
  const AnalysisLoadingIndicator({
    super.key,
    required this.messages,
    this.interval = const Duration(milliseconds: 1800),
  });

  final List<String> messages;
  final Duration interval;

  @override
  State<AnalysisLoadingIndicator> createState() => _AnalysisLoadingIndicatorState();
}

class _AnalysisLoadingIndicatorState extends State<AnalysisLoadingIndicator> {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scheduleNext();
  }

  void _scheduleNext() {
    if (widget.messages.length <= 1) return;
    _timer = Timer(widget.interval, () {
      if (!mounted) return;
      if (_index >= widget.messages.length - 1) return;
      setState(() => _index += 1);
      _scheduleNext();
    });
  }

  @override
  void dispose() {
    // Without this, a still-pending real Timer outlives a fast-resolving
    // analysis (or a test tearing the widget down mid-cycle) and trips
    // Flutter's "timer still pending" leak check.
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            widget.messages[_index],
            key: ValueKey('analysisLoadingText_$_index'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
