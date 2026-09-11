import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:next_career_after_fauj/core/models/officer_profile.dart';
import 'package:next_career_after_fauj/core/services/file_picker_service.dart';
import 'package:next_career_after_fauj/core/services/profile_repository.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/cv_builder/cv_builder_intake.dart';
import 'package:next_career_after_fauj/features/cv_templates/cv_pdf_fonts.dart';
import 'package:next_career_after_fauj/features/cv_templates/cv_template_registry.dart';
import 'package:next_career_after_fauj/features/cv_writing_guide/cv_writing_guide_screen.dart';
import 'package:provider/provider.dart';

void _setTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 12000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

final _profileWithCv = OfficerProfile(
  rank: 'Colonel',
  fullName: 'A K Sharma',
  dateOfBirth: DateTime(1975, 4, 12),
  workExperienceYears: 22,
  workExperienceMonths: 0,
  releaseStatus: ReleaseStatus.tentative,
  releaseDate: DateTime(2027, 6, 30),
  service: OfficerService.army,
  mobileNumber: '9876543210',
  email: 'a.sharma@example.com',
  segment: OfficerSegment.pmr,
  cvFileName: 'resume.pdf',
);

const _intakeWithExperience = CvBuilderIntake(
  summary: 'Senior operations leader with 22 years of experience.',
  workExperience: [
    WorkExperienceEntry(
      roleTitle: 'Commanding Officer',
      organizationType: 'Infantry battalion, ~800 personnel',
      duration: 'Jul 2019 - Jun 2022',
      responsibilities: 'Led all operations and training for the unit.',
    ),
  ],
  skills: 'Leadership, Logistics, Crisis Management',
);

Widget _wrap(Widget child, {ProfileRepository? repository}) {
  return ChangeNotifierProvider<ProfileRepository>.value(
    value: repository ?? ProfileRepository(),
    child: MaterialApp(theme: AppTheme.light, home: child),
  );
}

// Real font loading (rootBundle works fine in flutter test) but a fake
// delivery hook — every test must override the latter, or it would fire a
// real platform share/download call and fail in the test sandbox.
Future<CvPdfFonts> _realLoadFonts() => CvPdfFonts.load();

void main() {
  testWidgets('lists all 20 templates as tappable gallery thumbnails', (tester) async {
    _setTallViewport(tester);
    final repo = ProfileRepository()..saveProfile(_profileWithCv);
    await repo.saveCvBuilderIntake(_intakeWithExperience);
    await tester.pumpWidget(
      _wrap(
        CvWritingGuideScreen(loadFonts: _realLoadFonts, onDeliverPdf: (_, __) async {}),
        repository: repo,
      ),
    );

    expect(kCvPdfTemplates.length, 20);
    for (final template in kCvPdfTemplates) {
      expect(find.byKey(ValueKey('cvPdfTemplate_${template.id}')), findsOneWidget);
    }
  });

  testWidgets('tapping a thumbnail opens the full-page preview with a download action',
      (tester) async {
    _setTallViewport(tester);
    final repo = ProfileRepository()..saveProfile(_profileWithCv);
    await repo.saveCvBuilderIntake(_intakeWithExperience);
    await tester.pumpWidget(
      _wrap(
        CvWritingGuideScreen(loadFonts: _realLoadFonts, onDeliverPdf: (_, __) async {}),
        repository: repo,
      ),
    );

    final target = kCvPdfTemplates[3]; // Executive Burgundy
    await tester.ensureVisible(find.byKey(ValueKey('cvPdfTemplate_${target.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('cvPdfTemplate_${target.id}')));
    await tester.pumpAndSettle();

    // The dialog names the template — the whole point of the redesign was
    // that a bare grid of thumbnails made it easy to lose track of which
    // design was which. (The name also appears on the thumbnail underneath,
    // so scope the check to inside the dialog.)
    expect(
      find.descendant(of: find.byType(Dialog), matching: find.text(target.name)),
      findsOneWidget,
    );
    expect(find.byKey(ValueKey('downloadCvTemplate_${target.id}')), findsOneWidget);
  });

  testWidgets('downloading from the preview dialog builds a real PDF and hands it to the injected delivery hook',
      (tester) async {
    _setTallViewport(tester);
    final repo = ProfileRepository()..saveProfile(_profileWithCv);
    await repo.saveCvBuilderIntake(_intakeWithExperience);

    String? deliveredFileName;
    Uint8List? deliveredBytes;
    await tester.pumpWidget(
      _wrap(
        CvWritingGuideScreen(
          loadFonts: _realLoadFonts,
          onDeliverPdf: (bytes, fileName) async {
            deliveredBytes = bytes;
            deliveredFileName = fileName;
          },
        ),
        repository: repo,
      ),
    );

    final target = kCvPdfTemplates[3]; // Executive Burgundy
    await tester.ensureVisible(find.byKey(ValueKey('cvPdfTemplate_${target.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('cvPdfTemplate_${target.id}')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ValueKey('downloadCvTemplate_${target.id}')));
    await tester.pumpAndSettle();

    expect(deliveredFileName, 'CV_${target.name}.pdf');
    expect(deliveredBytes, isNotNull);
    expect(deliveredBytes, isNotEmpty);
  });

  testWidgets('a delivery failure shows an error instead of failing silently', (tester) async {
    _setTallViewport(tester);
    final repo = ProfileRepository()..saveProfile(_profileWithCv);
    await repo.saveCvBuilderIntake(_intakeWithExperience);
    await tester.pumpWidget(
      _wrap(
        CvWritingGuideScreen(
          loadFonts: _realLoadFonts,
          onDeliverPdf: (_, __) async => throw Exception('no share sheet available'),
        ),
        repository: repo,
      ),
    );

    final target = kCvPdfTemplates.first;
    await tester.ensureVisible(find.byKey(ValueKey('cvPdfTemplate_${target.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('cvPdfTemplate_${target.id}')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ValueKey('downloadCvTemplate_${target.id}')));
    await tester.pumpAndSettle();

    // A SnackBar (via the Scaffold's overlay) rather than an inline banner
    // — it floats above the dialog regardless of scroll position.
    expect(find.textContaining("Couldn't generate"), findsOneWidget);
  });

  testWidgets('shows a banner prompting CV Builder when there is no work experience yet, and blocks download',
      (tester) async {
    _setTallViewport(tester);
    final repo = ProfileRepository()..saveProfile(_profileWithCv);
    await tester.pumpWidget(
      _wrap(
        CvWritingGuideScreen(loadFonts: _realLoadFonts, onDeliverPdf: (_, __) async {}),
        repository: repo,
      ),
    );

    expect(find.byKey(const Key('cvTemplatesNoDataBanner')), findsOneWidget);

    // Downloads are blocked, not just discouraged — there's nothing to put
    // in the PDF without CV Builder data.
    final target = kCvPdfTemplates.first;
    await tester.ensureVisible(find.byKey(ValueKey('cvPdfTemplate_${target.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('cvPdfTemplate_${target.id}')));
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(find.byKey(ValueKey('downloadCvTemplate_${target.id}')));
    expect(button.onPressed, isNull);
  });

  testWidgets('the banner is hidden once CV Builder work experience exists', (tester) async {
    _setTallViewport(tester);
    final repo = ProfileRepository()..saveProfile(_profileWithCv);
    await repo.saveCvBuilderIntake(_intakeWithExperience);
    await tester.pumpWidget(
      _wrap(
        CvWritingGuideScreen(loadFonts: _realLoadFonts, onDeliverPdf: (_, __) async {}),
        repository: repo,
      ),
    );

    expect(find.byKey(const Key('cvTemplatesNoDataBanner')), findsNothing);
  });

  testWidgets('adding a photo switches the affordance from Add to Remove', (tester) async {
    _setTallViewport(tester);
    final repo = ProfileRepository()..saveProfile(_profileWithCv);
    // Image.memory decodes this asynchronously — arbitrary bytes would
    // throw a decode error mid-test, so use a real (tiny) valid PNG.
    final sampleImage = img.Image(width: 4, height: 4);
    img.fill(sampleImage, color: img.ColorRgb8(120, 130, 150));
    final pickedBytes = Uint8List.fromList(img.encodePng(sampleImage));
    await tester.pumpWidget(
      _wrap(
        CvWritingGuideScreen(
          loadFonts: _realLoadFonts,
          onDeliverPdf: (_, __) async {},
          pickPhoto: () async => PickedFile(name: 'me.jpg', bytes: pickedBytes),
        ),
        repository: repo,
      ),
    );

    expect(find.byKey(const Key('addPhotoButton')), findsOneWidget);
    expect(find.byKey(const Key('removePhotoButton')), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('addPhotoButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('addPhotoButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('addPhotoButton')), findsNothing);
    expect(find.byKey(const Key('removePhotoButton')), findsOneWidget);
    expect(repo.profile?.photoBytes, pickedBytes);

    await tester.ensureVisible(find.byKey(const Key('removePhotoButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('removePhotoButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('addPhotoButton')), findsOneWidget);
    expect(repo.profile?.photoBytes, isNull);
  });

  testWidgets('shows the CV structure guidance and the writing guidelines', (tester) async {
    _setTallViewport(tester);
    final repo = ProfileRepository()..saveProfile(_profileWithCv);
    await tester.pumpWidget(
      _wrap(
        CvWritingGuideScreen(loadFonts: _realLoadFonts, onDeliverPdf: (_, __) async {}),
        repository: repo,
      ),
    );

    // Structure section headings.
    for (final heading in [
      'Header',
      'Target Role / Professional Summary',
      'Core Skills',
      'Professional Experience',
      'Education',
      'Certifications',
      'Languages',
    ]) {
      await tester.ensureVisible(find.byKey(ValueKey('cvStructure_$heading')));
    await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('cvStructure_$heading')), findsOneWidget);
    }

    // A representative sample of the guideline titles the user specifically
    // asked for — defence jargon, challenges, KPI-based achievements.
    for (final title in [
      'Never use defence abbreviations or jargon',
      'Never include ACR, classified, or unit-identifying content',
      'Describe challenges, not just duties',
      'Quantify achievements — build a real KPI-based achievement matrix',
      'State designation and exact dates for every role',
      'List qualifications, certifications, and languages clearly',
    ]) {
      await tester.ensureVisible(find.byKey(ValueKey('cvGuideline_$title')));
    await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('cvGuideline_$title')), findsOneWidget);
    }
  });
}
