import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/models/officer_profile.dart';
import 'package:next_career_after_fauj/core/services/profile_repository.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/cv_civilianizer/civilianized_cv.dart';
import 'package:next_career_after_fauj/features/cv_civilianizer/civilianizer_screen.dart';
import 'package:provider/provider.dart';

const _stubResult = CivilianizedCv(
  civilianizedCv: 'Operations Director with 14+ years leading large organisations.',
  translationNotes: ['Rewrote command language as Operations Director.'],
);

int _callCount = 0;

Future<CivilianizedCv> _stubCivilianize({
  required String cvText,
  Uint8List? cvPdfBytes,
}) async {
  _callCount++;
  return _stubResult;
}

ProfileRepository _repositoryWithProfile() {
  return ProfileRepository()
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
}

Widget _wrap(ProfileRepository repository) {
  return ChangeNotifierProvider<ProfileRepository>.value(
    value: repository,
    child: MaterialApp(
      theme: AppTheme.light,
      home: const CivilianizerScreen(civilianizeCv: _stubCivilianize),
    ),
  );
}

void main() {
  setUp(() => _callCount = 0);

  testWidgets('generates and shows the civilianized CV with translation notes', (tester) async {
    await tester.pumpWidget(_wrap(_repositoryWithProfile()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('civilianizedCvText')), findsOneWidget);
    expect(find.text(_stubResult.civilianizedCv), findsOneWidget);
    expect(find.textContaining('Rewrote command language as Operations Director.'),
        findsOneWidget);
    expect(_callCount, 1);
  });

  testWidgets('caches the result in ProfileRepository so it is not regenerated on rebuild',
      (tester) async {
    final repository = _repositoryWithProfile();
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();
    expect(_callCount, 1);
    expect(repository.lastCivilianizedCv?.civilianizedCv, _stubResult.civilianizedCv);

    // Re-mounting the screen with a repository that already has a cached
    // result should use the cache instead of calling the service again.
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();
    expect(_callCount, 1);
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

    await tester.pumpWidget(_wrap(_repositoryWithProfile()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('copyCivilianizedCvButton')));
    await tester.pumpAndSettle();

    expect(find.text('CV copied to clipboard'), findsOneWidget);
  });

  testWidgets('regenerate button calls the service again even with a cached result',
      (tester) async {
    final repository = _repositoryWithProfile();
    repository.saveCivilianizedCv(_stubResult);
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();
    expect(_callCount, 0); // used the cache, no call yet

    await tester.tap(find.byKey(const Key('regenerateCivilianizedCvButton')));
    await tester.pumpAndSettle();

    expect(_callCount, 1);
  });
}
