import 'package:flutter/material.dart';

import 'app_routes.dart';

/// One step in the officer's guided first-run sequence (see
/// start_here_screen.dart) — shared so both Start Here and the "Next"
/// button on each step's completion screen read from one ordered list.
class SequenceStep {
  const SequenceStep({required this.key, required this.label, required this.route});

  final String key;
  final String label;
  final String route;
}

const List<SequenceStep> kGuidedSequence = [
  SequenceStep(key: 'verticalFit', label: 'Career Vertical Fit', route: AppRoutes.verticalFit),
  SequenceStep(key: 'aiReadiness', label: 'AI Readiness', route: AppRoutes.aiReadiness),
  SequenceStep(key: 'cvJdFit', label: 'CV & JD Fit', route: AppRoutes.jdMatch),
];

/// A forward-navigation button for a screen that completes one step of
/// [kGuidedSequence] — looked up by that step's `key`. Renders "Next:
/// <next step>" and pushes its route, or — after the last step — "You're
/// set up — back to Home", which clears the stack back to the main shell
/// exactly like [HomeButton] (core/widgets/home_button.dart) does.
class NextStepButton extends StatelessWidget {
  const NextStepButton({super.key, required this.completedStepKey});

  final String completedStepKey;

  @override
  Widget build(BuildContext context) {
    final index = kGuidedSequence.indexWhere((s) => s.key == completedStepKey);
    final isLast = index == -1 || index == kGuidedSequence.length - 1;
    if (isLast) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          key: const Key('guidedSequenceDoneButton'),
          onPressed: () => Navigator.of(context)
              .pushNamedAndRemoveUntil(AppRoutes.profile, (route) => false),
          icon: const Icon(Icons.home_outlined),
          label: const Text("You're set up — back to Home"),
        ),
      );
    }
    final next = kGuidedSequence[index + 1];
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        key: const Key('guidedSequenceNextButton'),
        onPressed: () => Navigator.of(context).pushNamed(next.route),
        icon: const Icon(Icons.arrow_forward),
        label: Text('Next: ${next.label}'),
      ),
    );
  }
}
