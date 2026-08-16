import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:officer_career_app/core/models/officer_profile.dart';
import 'package:officer_career_app/core/routing/app_routes.dart';
import 'package:officer_career_app/core/services/file_picker_service.dart';
import 'package:officer_career_app/core/services/profile_repository.dart';
import 'package:officer_career_app/core/theme/app_theme.dart';
import 'package:officer_career_app/core/utils/date_format.dart';
import 'package:officer_career_app/features/onboarding/onboarding_screen.dart';
import 'package:officer_career_app/features/profile/profile_screen.dart';
import 'package:provider/provider.dart';

Widget _appUnderTest({required FileNamePicker pickFile}) {
  return ChangeNotifierProvider(
    create: (_) => ProfileRepository(),
    child: MaterialApp(
      theme: AppTheme.light,
      initialRoute: AppRoutes.onboarding,
      routes: {
        AppRoutes.onboarding: (_) => OnboardingScreen(pickFile: pickFile),
        AppRoutes.profile: (_) => const ProfileScreen(),
      },
    ),
  );
}

void main() {
  testWidgets(
    'CV-upload onboarding flow creates a profile and lands on Profile screen',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _appUnderTest(pickFile: () async => 'resume.pdf'),
      );

      // Step 1: service verification, in the required
      // service / rank / name / DOB / work experience / mobile / email
      // sequence. Rank is dependent on Service, so Service must be picked
      // first for the Rank dropdown's options to populate.
      await tester.tap(find.byKey(const Key('serviceDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Army').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('rankDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Major').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('nameField')), 'Maj. A Verma');

      await tester.tap(find.byKey(const Key('dobField')));
      await tester.pumpAndSettle();
      // Accept the picker's default initialDate (30 years before today)
      // rather than interacting with the calendar grid.
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('workExperienceYearsDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('12').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('workExperienceMonthsDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('5').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('mobileField')), '9876543210');
      await tester.enterText(find.byKey(const Key('emailField')), 'a.verma@example.com');
      await tester.tap(find.byKey(const Key('consentCheckbox')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('continueButton')));
      await tester.pumpAndSettle();

      // Step 2: segment — one of three (SSC / PMR / Superannuation).
      await tester.tap(find.byKey(const Key('segment_pmr')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('continueButton')));
      await tester.pumpAndSettle();

      // Step 3: CV upload — the only intake path (no ACR / service-record
      // field, no structured-entry alternative).
      await tester.tap(find.byKey(const Key('browseButton')));
      await tester.pumpAndSettle();
      expect(find.text('resume.pdf'), findsOneWidget);
      await tester.tap(find.byKey(const Key('continueButton')));
      await tester.pumpAndSettle();

      final now = DateTime.now();
      final expectedDob = formatDate(DateTime(now.year - 30, now.month, now.day));

      expect(find.text('My Profile'), findsOneWidget);
      expect(find.text('Major'), findsOneWidget);
      expect(find.text('Maj. A Verma'), findsOneWidget);
      expect(find.text(expectedDob), findsOneWidget);
      expect(find.text('12 yrs 5 mos'), findsOneWidget);
      expect(find.text('Army'), findsOneWidget);
      expect(find.text(OfficerSegment.pmr.fullLabel), findsOneWidget);
      expect(find.text('9876543210'), findsOneWidget);
      expect(find.text('a.verma@example.com'), findsOneWidget);
      expect(find.text('resume.pdf'), findsOneWidget);
      expect(find.text('Service number'), findsNothing);
    },
  );
}
