import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/routing/app_routes.dart';
import 'package:next_career_after_fauj/core/routing/guided_sequence.dart';

Widget _wrap(String completedStepKey) {
  return MaterialApp(
    home: Scaffold(body: NextStepButton(completedStepKey: completedStepKey)),
    onGenerateRoute: (settings) => MaterialPageRoute(
      settings: settings,
      builder: (_) => Scaffold(body: Text('route:${settings.name}')),
    ),
  );
}

void main() {
  test('kGuidedSequence has the 3 expected steps in order', () {
    expect(kGuidedSequence.map((s) => s.key).toList(), [
      'verticalFit',
      'aiReadiness',
      'cvJdFit',
    ]);
  });

  testWidgets('shows "Next: <step>" and navigates to the next step\'s route', (tester) async {
    await tester.pumpWidget(_wrap('verticalFit'));
    await tester.pumpAndSettle();

    expect(find.text('Next: AI Readiness'), findsOneWidget);

    await tester.tap(find.byKey(const Key('guidedSequenceNextButton')));
    await tester.pumpAndSettle();

    expect(find.text('route:${AppRoutes.aiReadiness}'), findsOneWidget);
  });

  testWidgets('the last step shows "back to Home" instead of "Next"', (tester) async {
    await tester.pumpWidget(_wrap('cvJdFit'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('guidedSequenceNextButton')), findsNothing);
    expect(find.byKey(const Key('guidedSequenceDoneButton')), findsOneWidget);
    expect(find.textContaining('back to Home'), findsOneWidget);
  });

  testWidgets('an unrecognised step key is treated as the end of the sequence', (tester) async {
    await tester.pumpWidget(_wrap('not-a-real-step'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('guidedSequenceDoneButton')), findsOneWidget);
  });
}
