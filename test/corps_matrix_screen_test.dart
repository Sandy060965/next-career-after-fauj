import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/models/officer_profile.dart';
import 'package:next_career_after_fauj/core/services/profile_repository.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/corps_matrix/corps_matrix_screen.dart';
import 'package:provider/provider.dart';

Widget _wrap(ProfileRepository repository) {
  return ChangeNotifierProvider.value(
    value: repository,
    child: MaterialApp(theme: AppTheme.light, home: const CorpsMatrixScreen()),
  );
}

void _setTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 8000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('By Corps/Arm', () {
    testWidgets('with no saved profile, shows the picker grouped by service', (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(_wrap(ProfileRepository()));

      expect(find.byKey(const Key('pickCorps_Infantry')), findsOneWidget);
      expect(find.byKey(const Key('pickCorps_Flying Branch')), findsOneWidget);
      expect(find.text('Army'), findsOneWidget);
      expect(find.text('Navy'), findsOneWidget);
      expect(find.text('Air Force'), findsOneWidget);
    });

    testWidgets('defaults straight to results when the officer has a saved Corps/Arm', (tester) async {
      _setTallViewport(tester);
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
            corpsOrArm: 'Corps of Signals',
          ),
        );

      await tester.pumpWidget(_wrap(repository));

      expect(find.byKey(const Key('pickCorps_Corps of Signals')), findsNothing);
      expect(find.text('Corps of Signals'), findsOneWidget);
      expect(find.byKey(const Key('matrixEntry_IT Infrastructure & Cybersecurity')), findsOneWidget);
      // Medical/legal verticals are hard-restricted for a general corps and
      // should never appear as an entry, even under "Limited fit".
      expect(find.byKey(const Key('matrixEntry_Clinical Practice & Hospital Administration')), findsNothing);
      expect(find.byKey(const Key('matrixEntry_Corporate Legal & In-House Counsel')), findsNothing);
    });

    testWidgets('selecting a Corps/Arm shows tiered results, and Change returns to the picker',
        (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(_wrap(ProfileRepository()));

      await tester.tap(find.byKey(const Key('pickCorps_Corps of Signals')));
      await tester.pumpAndSettle();

      expect(find.text('Corps of Signals'), findsOneWidget);
      expect(find.text('Strong fit'), findsOneWidget);
      expect(find.byKey(const Key('matrixEntry_IT Infrastructure & Cybersecurity')), findsOneWidget);

      await tester.tap(find.byKey(const Key('changeMatrixSelectionButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pickCorps_Corps of Signals')), findsOneWidget);
    });

    testWidgets('a medical Corps/Arm shows its medical verticals as Strong fit', (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(_wrap(ProfileRepository()));

      await tester.tap(find.byKey(const Key('pickCorps_Army Medical Corps (AMC)')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('matrixEntry_Clinical Practice & Hospital Administration')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('matrixEntry_Corporate Legal & In-House Counsel')), findsNothing);
    });

    testWidgets('tapping an entry opens its Career Vertical Handbook page', (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(_wrap(ProfileRepository()));

      await tester.tap(find.byKey(const Key('pickCorps_Corps of Signals')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('matrixEntry_IT Infrastructure & Cybersecurity')));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'IT Infrastructure & Cybersecurity'), findsOneWidget);
    });
  });

  group('By vertical (reverse view)', () {
    testWidgets('the toggle switches to a vertical picker grouped by category', (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(_wrap(ProfileRepository()));

      await tester.tap(find.byKey(const Key('toggleMatrixDirectionButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pickVertical_IT Infrastructure & Cybersecurity')), findsOneWidget);
      expect(find.text('Technical & Engineering'), findsOneWidget);
    });

    testWidgets('selecting a vertical shows which Corps/Arms fit it, grouped by tier', (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(_wrap(ProfileRepository()));

      await tester.tap(find.byKey(const Key('toggleMatrixDirectionButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pickVertical_IT Infrastructure & Cybersecurity')));
      await tester.pumpAndSettle();

      expect(find.text('IT Infrastructure & Cybersecurity'), findsOneWidget);
      expect(find.byKey(const Key('matrixEntry_Corps of Signals')), findsOneWidget);
      // Reverse-view entries aren't tappable into anything (no single
      // vertical to route to), so there's no chevron / onTap for them.
      final tile = tester.widget<ListTile>(find.byKey(const Key('matrixEntry_Corps of Signals')));
      expect(tile.onTap, isNull);
    });

    testWidgets('a medical vertical only lists the real medical Corps/Arm entries', (tester) async {
      _setTallViewport(tester);
      await tester.pumpWidget(_wrap(ProfileRepository()));

      await tester.tap(find.byKey(const Key('toggleMatrixDirectionButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pickVertical_Clinical Practice & Hospital Administration')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('matrixEntry_Army Medical Corps (AMC)')), findsOneWidget);
      expect(find.byKey(const Key('matrixEntry_Corps of Signals')), findsNothing);
    });
  });
}
