import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/models/officer_profile.dart';
import 'package:next_career_after_fauj/core/services/file_picker_service.dart';
import 'package:next_career_after_fauj/core/services/profile_repository.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/cv_upload/cv_upload_sheet.dart';
import 'package:provider/provider.dart';

/// Same minimal real .docx builder used in onboarding_flow_test.dart, so
/// docx extraction is exercised for real rather than stubbed.
Uint8List _buildDocxBytes(String bodyText) {
  const xmlTemplate = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body><w:p><w:r><w:t>{{BODY}}</w:t></w:r></w:p></w:body>
</w:document>''';
  final xml = xmlTemplate.replaceFirst('{{BODY}}', bodyText);
  final archive = Archive();
  final bytes = utf8.encode(xml);
  archive.addFile(ArchiveFile('word/document.xml', bytes.length, bytes));
  return Uint8List.fromList(ZipEncoder().encode(archive)!);
}

OfficerProfile _existingProfile() => OfficerProfile(
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
      cvFileName: '', // started with no CV, same as an officer who skipped onboarding's step
    );

Widget _hostScreen(ProfileRepository repository, Future<PickedFile?> Function() pickFile) {
  return ChangeNotifierProvider<ProfileRepository>.value(
    value: repository,
    child: MaterialApp(
      theme: AppTheme.light,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              key: const Key('openSheetButton'),
              onPressed: () => showCvUploadSheet(context, pickFile: pickFile),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('picking a PDF and saving attaches it to the existing profile without touching '
      'any other field', (tester) async {
    final repository = ProfileRepository()..saveProfile(_existingProfile());
    await tester.pumpWidget(
      _hostScreen(
        repository,
        () async => PickedFile(name: 'resume.pdf', bytes: Uint8List.fromList([1, 2, 3])),
      ),
    );

    await tester.tap(find.byKey(const Key('openSheetButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cvUploadSheetBrowseButton')));
    await tester.pumpAndSettle();
    expect(find.text('resume.pdf'), findsOneWidget);

    await tester.tap(find.byKey(const Key('cvUploadSheetSaveButton')));
    await tester.pumpAndSettle();

    // Sheet closes, and only the CV fields changed.
    expect(find.byKey(const Key('cvUploadSheetSaveButton')), findsNothing);
    expect(repository.profile?.cvFileName, 'resume.pdf');
    expect(repository.profile?.cvPdfBytes, isNotNull);
    expect(repository.profile?.fullName, 'Maj A Verma');
    expect(repository.profile?.rank, 'Major');
  });

  testWidgets('tapping Save with no file chosen shows an inline error instead of saving',
      (tester) async {
    final repository = ProfileRepository()..saveProfile(_existingProfile());
    await tester.pumpWidget(_hostScreen(repository, () async => null));

    await tester.tap(find.byKey(const Key('openSheetButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cvUploadSheetSaveButton')));
    await tester.pumpAndSettle();

    expect(find.text('Choose a file to continue'), findsOneWidget);
    expect(repository.profile?.cvFileName, ''); // unchanged
  });

  testWidgets('a .docx CV extracts its text and attaches it to the existing profile',
      (tester) async {
    final repository = ProfileRepository()..saveProfile(_existingProfile());
    final docxBytes = _buildDocxBytes('Commanded a battalion-sized team during the tenure.');

    await tester.pumpWidget(
      _hostScreen(
        repository,
        () async => PickedFile(name: 'resume.docx', bytes: docxBytes),
      ),
    );

    await tester.tap(find.byKey(const Key('openSheetButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cvUploadSheetBrowseButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cvUploadSheetSaveButton')));
    await tester.pumpAndSettle();

    expect(repository.profile?.cvFileName, 'resume.docx');
    expect(repository.profile?.cvExtractedText, contains('Commanded a battalion-sized team'));
  });

  testWidgets('a PDF larger than the size limit is rejected with a clear reason', (tester) async {
    final repository = ProfileRepository()..saveProfile(_existingProfile());
    final oversized = Uint8List(kMaxUploadPdfBytes + 1);
    await tester.pumpWidget(
      _hostScreen(repository, () async => PickedFile(name: 'huge-scan.pdf', bytes: oversized)),
    );

    await tester.tap(find.byKey(const Key('openSheetButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('cvUploadSheetBrowseButton')));
    await tester.pumpAndSettle();

    expect(find.textContaining('larger than $kMaxUploadPdfMb MB'), findsOneWidget);
    expect(find.text('huge-scan.pdf'), findsNothing);
  });
}
