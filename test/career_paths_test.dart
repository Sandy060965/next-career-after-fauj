import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/models/officer_profile.dart';
import 'package:next_career_after_fauj/core/services/profile_repository.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/career_paths/career_paths_screen.dart';
import 'package:next_career_after_fauj/features/career_paths/career_vertical.dart';
import 'package:provider/provider.dart';

Widget _appUnderTest(ProfileRepository repository) {
  return ChangeNotifierProvider.value(
    value: repository,
    child: MaterialApp(theme: AppTheme.light, home: const CareerPathsScreen()),
  );
}

void main() {
  testWidgets('all career verticals render, and expanding one shows the '
      "user's experience-based entry level", (tester) async {
    final repository = ProfileRepository()
      ..saveProfile(
        OfficerProfile(
          rank: 'Lt Col',
          fullName: 'Lt Col A Verma',
          dateOfBirth: DateTime(1978, 5, 10),
          workExperienceYears: 18,
          workExperienceMonths: 2,
          releaseStatus: ReleaseStatus.tentative,
          releaseDate: DateTime(2027, 6, 30),
          service: OfficerService.army,
          mobileNumber: '9876543210',
          email: 'a.verma@example.com',
          segment: OfficerSegment.pmr,
          cvFileName: 'resume.pdf',
        ),
      );

    // Tall enough that all 20 collapsed vertical tiles are laid out at once,
    // without needing to scroll to find each one.
    tester.view.physicalSize = const Size(430, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_appUnderTest(repository));

    // Every vertical's title is browsable without expanding.
    for (final vertical in kCareerVerticals) {
      expect(find.text(vertical.name), findsOneWidget);
    }

    // Expand the Security ladder and confirm the 18-year rung (tier 2,
    // 15-20 yrs: "Regional Security Manager") is highlighted with the
    // "Your level" chip.
    await tester.tap(find.text('Security, Risk & Crisis Management'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('yourLevelChip')), findsOneWidget);
    expect(find.text('Regional Security Manager'), findsOneWidget);

    final chipFinder = find.ancestor(
      of: find.byKey(const Key('yourLevelChip')),
      matching: find.byType(Row),
    );
    expect(
      find.descendant(of: chipFinder.first, matching: find.text('Regional Security Manager')),
      findsOneWidget,
    );
  });

  testWidgets('with no profile yet, no vertical shows a "Your level" chip', (tester) async {
    await tester.pumpWidget(_appUnderTest(ProfileRepository()));

    await tester.tap(find.text('Security, Risk & Crisis Management'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('yourLevelChip')), findsNothing);
  });
}
