import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/skill_equivalency/skill_equivalency.dart';
import 'package:next_career_after_fauj/features/skill_equivalency/skill_equivalency_screen.dart';

void main() {
  testWidgets('shows every skill equivalency with its civilian mapping', (tester) async {
    tester.view.physicalSize = const Size(430, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const SkillEquivalencyScreen()),
    );

    for (final entry in kSkillEquivalencies) {
      expect(find.byKey(ValueKey('equivalency_${entry.militaryTerm}')), findsOneWidget);
      expect(find.text(entry.civilianEquivalent), findsOneWidget);
    }
  });
}
