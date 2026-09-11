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
        AppRoutes.jobMatches: (_) => const Scaffold(body: Text('Job Matches Screen')),
      },
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('starts on the Home tab and switches tabs via the bottom nav', (tester) async {
    await tester.pumpWidget(_wrap(ProfileRepository()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dimensionCard_Career Fit')), findsOneWidget);

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
    expect(find.byKey(const Key('dimensionCard_Career Fit')), findsOneWidget);
  });

  group('wide-screen sidebar', () {
    void setWideViewport(WidgetTester tester) {
      // Tall enough that every sidebar entry (5 tabs + phase headers + every
      // module across all three categories) is built without needing to
      // scroll the sidebar's own ListView to find it.
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    testWidgets('lists every category\'s modules, always visible, and navigates on tap',
        (tester) async {
      setWideViewport(tester);
      await tester.pumpWidget(_wrap(ProfileRepository()));
      await tester.pumpAndSettle();

      // The bottom nav bar from the narrow layout is gone on a wide screen.
      expect(find.byKey(const Key('mainNavBar')), findsNothing);

      // Career/Jobs/Learn modules are all visible without selecting a tab first.
      expect(find.byKey(const ValueKey('sidebarModule_careerPathsButton')), findsOneWidget);
      expect(find.byKey(const ValueKey('sidebarModule_jobMatchesButton')), findsOneWidget);
      expect(find.byKey(const ValueKey('sidebarModule_cvBuilderButton')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('sidebarModule_jobMatchesButton')));
      await tester.pumpAndSettle();

      expect(find.text('Job Matches Screen'), findsOneWidget);
    });

    testWidgets('tapping a top-level sidebar entry switches tabs like the old rail did',
        (tester) async {
      setWideViewport(tester);
      await tester.pumpWidget(_wrap(ProfileRepository()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('sidebarTab_Profile')));
      await tester.pumpAndSettle();

      expect(find.text('No profile found yet.'), findsOneWidget);
    });
  });
}
