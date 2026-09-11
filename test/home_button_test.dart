import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/routing/app_routes.dart';
import 'package:next_career_after_fauj/core/widgets/home_button.dart';

void main() {
  testWidgets('tapping the Home button clears the stack back to the shell route, however deep',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.profile,
        routes: {
          AppRoutes.profile: (context) => Scaffold(
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Main Shell'),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pushNamed('/deeper'),
                        child: const Text('Go deeper'),
                      ),
                    ],
                  ),
                ),
              ),
        },
        onGenerateRoute: (settings) {
          // Simulate a screen several levels deep, each with its own Home button.
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => Scaffold(
              appBar: AppBar(title: Text(settings.name ?? 'unknown'), actions: const [HomeButton()]),
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pushNamed('/deeper'),
                  child: const Text('Go deeper'),
                ),
              ),
            ),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    // Navigate three levels deep from the shell.
    await tester.tap(find.text('Go deeper'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Go deeper'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Go deeper'));
    await tester.pumpAndSettle();

    expect(find.text('Main Shell'), findsNothing);

    await tester.tap(find.byKey(const Key('homeButton')));
    await tester.pumpAndSettle();

    expect(find.text('Main Shell'), findsOneWidget);
    // The whole stack was cleared, not just one level popped.
    expect(find.byKey(const Key('homeButton')), findsNothing);
  });
}
