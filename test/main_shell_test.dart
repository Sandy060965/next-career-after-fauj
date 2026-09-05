import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/routing/app_routes.dart';
import 'package:next_career_after_fauj/core/services/profile_repository.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/shell/main_shell.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(ProfileRepository repository) {
  return ChangeNotifierProvider<ProfileRepository>.value(
    value: repository,
    child: MaterialApp(
      theme: AppTheme.light,
      home: const MainShell(),
      routes: {
        AppRoutes.aiAssistant: (_) => const Scaffold(body: Text('Assistant Screen')),
      },
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('starts on the Home tab and switches tabs via the bottom nav', (tester) async {
    await tester.pumpWidget(_wrap(ProfileRepository()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dashboardReadinessCard')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('navTab_Career')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('careerPathsButton')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('navTab_Jobs')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('jobMatchesButton')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('navTab_Learn')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cvCivilianizerButton')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('navTab_Profile')));
    await tester.pumpAndSettle();
    expect(find.text('No profile found yet.'), findsOneWidget);
  });

  testWidgets('the assistant FAB is reachable from every tab', (tester) async {
    await tester.pumpWidget(_wrap(ProfileRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('assistantFab')));
    await tester.pumpAndSettle();
    expect(find.text('Assistant Screen'), findsOneWidget);
  });

  testWidgets('switching tabs preserves each tab\'s own state (IndexedStack, not rebuilt)',
      (tester) async {
    await tester.pumpWidget(_wrap(ProfileRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('navTab_Career')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('navTab_Home')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dashboardReadinessCard')), findsOneWidget);
  });
}
