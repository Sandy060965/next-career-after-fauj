import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/models/officer_profile.dart';
import 'package:next_career_after_fauj/core/services/profile_repository.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/profile/profile_screen.dart';
import 'package:provider/provider.dart';

OfficerProfile _profile({String cvFileName = ''}) => OfficerProfile(
      rank: 'Major',
      fullName: 'Maj A Verma',
      dateOfBirth: DateTime(1990, 1, 1),
      workExperienceYears: 12,
      workExperienceMonths: 0,
      releaseStatus: ReleaseStatus.tentative,
      releaseDate: DateTime(2027, 1, 1),
      service: OfficerService.army,
      mobileNumber: '9876543210',
      email: 'a.verma@example.com',
      segment: OfficerSegment.ssc,
      cvFileName: cvFileName,
    );

Widget _wrap(ProfileRepository repository) {
  return ChangeNotifierProvider<ProfileRepository>.value(
    value: repository,
    child: MaterialApp(theme: AppTheme.light, home: const ProfileScreen()),
  );
}

void _setTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('with no CV on file, shows "Not uploaded" and an Add CV button', (tester) async {
    _setTallViewport(tester);
    final repository = ProfileRepository()..saveProfile(_profile());
    await tester.pumpWidget(_wrap(repository));

    expect(find.text('Not uploaded'), findsOneWidget);
    expect(find.byKey(const Key('addCvButton')), findsOneWidget);
  });

  testWidgets('with a CV on file, shows the filename instead of "Not uploaded"', (tester) async {
    _setTallViewport(tester);
    final repository = ProfileRepository()..saveProfile(_profile(cvFileName: 'resume.pdf'));
    await tester.pumpWidget(_wrap(repository));

    expect(find.text('resume.pdf'), findsOneWidget);
    expect(find.text('Not uploaded'), findsNothing);
    expect(find.byKey(const Key('addCvButton')), findsNothing);
  });

  testWidgets('Add CV opens the CV upload sheet', (tester) async {
    _setTallViewport(tester);
    final repository = ProfileRepository()..saveProfile(_profile());
    await tester.pumpWidget(_wrap(repository));

    await tester.tap(find.byKey(const Key('addCvButton')));
    await tester.pumpAndSettle();

    expect(find.text('Upload your CV'), findsOneWidget);
  });
}
