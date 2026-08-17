import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/models/officer_profile.dart';
import 'package:next_career_after_fauj/core/services/profile_repository.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/linkedin_writeup/linkedin_writeup.dart';
import 'package:next_career_after_fauj/features/linkedin_writeup/linkedin_writeup_screen.dart';
import 'package:provider/provider.dart';

const _stubWriteup = LinkedInWriteup(
  headline: 'Test Headline',
  aboutSection: 'Test About Section content.',
  announcementPost: 'Test Announcement Post content.',
);

Future<LinkedInWriteup> _stubGenerate({
  required String cvText,
  Uint8List? cvPdfBytes,
}) async =>
    _stubWriteup;

Widget _appUnderTest() {
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
        cvExtractedText: 'Sample CV text',
      ),
    );
  return ChangeNotifierProvider<ProfileRepository>.value(
    value: repository,
    child: MaterialApp(
      theme: AppTheme.light,
      home: const LinkedInWriteupScreen(generateWriteup: _stubGenerate),
    ),
  );
}

void main() {
  testWidgets('shows headline, about section, and announcement post with copy buttons',
      (tester) async {
    await tester.pumpWidget(_appUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Headline'), findsOneWidget);
    expect(find.text('Test Headline'), findsOneWidget);
    expect(find.byKey(const Key('headlineCopyButton')), findsOneWidget);

    expect(find.text('About section'), findsOneWidget);
    expect(find.text('Test About Section content.'), findsOneWidget);
    expect(find.byKey(const Key('aboutSectionCopyButton')), findsOneWidget);

    expect(find.text('Announcement post'), findsOneWidget);
    expect(find.text('Test Announcement Post content.'), findsOneWidget);
    expect(find.byKey(const Key('announcementPostCopyButton')), findsOneWidget);
  });

  testWidgets('tapping copy shows a confirmation snackbar', (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall methodCall) async => null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(_appUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('headlineCopyButton')));
    await tester.pumpAndSettle();

    expect(find.text('Headline copied to clipboard'), findsOneWidget);
  });
}
