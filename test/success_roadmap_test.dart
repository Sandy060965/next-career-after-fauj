import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/success_roadmap/ninety_day_roadmap_screen.dart';

void main() {
  testWidgets('shows all three phases and known checklist items', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const NinetyDayRoadmapScreen()),
    );

    expect(find.text('First 30 days'), findsOneWidget);
    expect(find.text('Map your key stakeholders'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Days 31-60'), 300);
    expect(find.text('Days 31-60'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Days 61-90'), 300);
    expect(find.text('Days 61-90'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Deliver one visible, measurable result'), 300);
    expect(find.text('Deliver one visible, measurable result'), findsOneWidget);
  });
}
