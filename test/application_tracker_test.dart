import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/models/job_application.dart';
import 'package:next_career_after_fauj/core/services/profile_repository.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/application_tracker/application_tracker_screen.dart';
import 'package:provider/provider.dart';

Widget _wrap(Widget child, {ProfileRepository? repository}) {
  return ChangeNotifierProvider<ProfileRepository>.value(
    value: repository ?? ProfileRepository(),
    child: MaterialApp(theme: AppTheme.light, home: child),
  );
}

void main() {
  testWidgets('shows an empty state with no applications tracked', (tester) async {
    await tester.pumpWidget(_wrap(const ApplicationTrackerScreen()));
    expect(find.textContaining('No applications tracked yet'), findsOneWidget);
  });

  testWidgets('adding an application shows it in the list and funnel summary', (tester) async {
    final repository = ProfileRepository();
    await tester.pumpWidget(_wrap(const ApplicationTrackerScreen(), repository: repository));

    await tester.tap(find.byKey(const Key('addApplicationFab')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('companyField')), 'Acme Corp');
    await tester.enterText(find.byKey(const Key('roleField')), 'Head of Operations');
    await tester.ensureVisible(find.byKey(const Key('saveApplicationButton')));
    await tester.tap(find.byKey(const Key('saveApplicationButton')));
    await tester.pumpAndSettle();

    expect(find.text('Acme Corp'), findsOneWidget);
    expect(find.text('Head of Operations'), findsOneWidget);
    expect(find.byKey(const Key('funnelCount_saved')), findsOneWidget);
    expect(repository.applications, hasLength(1));
    expect(repository.applications.single.status, ApplicationStatus.saved);
  });

  testWidgets('editing an application updates its status, deleting removes it', (tester) async {
    final repository = ProfileRepository();
    repository.addApplication(
      JobApplication(
        id: 'app-1',
        companyName: 'Acme Corp',
        roleTitle: 'Head of Operations',
        status: ApplicationStatus.saved,
        createdAt: DateTime(2026, 1, 1),
      ),
    );
    await tester.pumpWidget(_wrap(const ApplicationTrackerScreen(), repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('application_app-1')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('statusDropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Applied').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('saveApplicationButton')));
    await tester.tap(find.byKey(const Key('saveApplicationButton')));
    await tester.pumpAndSettle();

    expect(repository.applications.single.status, ApplicationStatus.applied);
    expect(find.byKey(const Key('funnelCount_applied')), findsOneWidget);

    await tester.tap(find.byKey(const Key('application_app-1')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('deleteApplicationButton')));
    await tester.tap(find.byKey(const Key('deleteApplicationButton')));
    await tester.pumpAndSettle();

    expect(repository.applications, isEmpty);
    expect(find.textContaining('No applications tracked yet'), findsOneWidget);
  });
}
