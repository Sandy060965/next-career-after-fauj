import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:next_career_after_fauj/features/cv_builder/cv_builder_intake.dart';
import 'package:next_career_after_fauj/features/cv_templates/cv_pdf_fonts.dart';
import 'package:next_career_after_fauj/features/cv_templates/cv_template_data.dart';
import 'package:next_career_after_fauj/features/cv_templates/cv_template_registry.dart';

Uint8List _samplePhotoBytes() {
  final image = img.Image(width: 8, height: 8);
  img.fill(image, color: img.ColorRgb8(120, 130, 150));
  return Uint8List.fromList(img.encodePng(image));
}

CvTemplateData _sampleData({Uint8List? photoBytes}) => CvTemplateData(
      fullName: 'A K Sharma',
      rank: 'Colonel',
      serviceLabel: 'Army',
      corpsOrArm: 'Corps of Signals',
      mobileNumber: '9876543210',
      email: 'a.sharma@example.com',
      photoBytes: photoBytes,
      summary: 'Senior operations leader with 22 years of experience leading large, '
          'cross-functional teams under pressure. Strong track record in logistics, '
          'crisis management, and training delivery.',
      skills: const ['Operations Leadership', 'Logistics', 'Crisis Management', 'Team Building', 'Training Delivery'],
      workExperience: const [
        WorkExperienceEntry(
          roleTitle: 'Commanding Officer',
          organizationType: 'Infantry battalion, ~800 personnel',
          duration: 'Jul 2019 – Jun 2022',
          responsibilities: 'Led all operations, training, and welfare for the unit.\n'
              'Managed an annual budget of ₹4 crore across equipment and stores.',
        ),
        WorkExperienceEntry(
          roleTitle: 'Second-in-Command',
          organizationType: 'Infantry battalion, ~800 personnel',
          duration: 'Jul 2016 – Jun 2019',
          responsibilities: 'Deputised for the Commanding Officer across all functions.',
        ),
      ],
      education: const [
        EducationEntry(degree: 'M.Sc. Defence Studies', institution: 'Madras University', year: '2015'),
      ],
      certifications: const [CertificationEntry(name: 'PMP', year: '2021')],
      courses: const [CourseEntry(name: 'Higher Command Course', year: '2020')],
      honoursAwards: const [AwardEntry(name: 'Sena Medal', year: '2018')],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CV PDF templates', () {
    test('exactly 20 templates are registered, each with a unique id', () {
      expect(kCvPdfTemplates.length, 20);
      expect(kCvPdfTemplates.map((t) => t.id).toSet().length, 20);
    });

    // A full pass (fonts + all 20 templates, with and without a photo) in a
    // single test avoids loading the bundled fonts 40 times over.
    test('every template renders non-empty PDF bytes, with and without a photo', () async {
      final fonts = await CvPdfFonts.load();
      final withPhoto = _sampleData(photoBytes: _samplePhotoBytes());
      final withoutPhoto = _sampleData();

      for (final template in kCvPdfTemplates) {
        final bytesWithPhoto = await template.build(withPhoto, fonts).save();
        expect(bytesWithPhoto, isNotEmpty, reason: '${template.id} (with photo) produced no bytes');

        final bytesWithoutPhoto = await template.build(withoutPhoto, fonts).save();
        expect(bytesWithoutPhoto, isNotEmpty, reason: '${template.id} (without photo) produced no bytes');
      }
    });

    test('every template renders with an empty CV — name/rank only, no fabricated sections', () async {
      final fonts = await CvPdfFonts.load();
      const bareData = CvTemplateData(fullName: 'A K Sharma', rank: 'Colonel', serviceLabel: 'Army');

      for (final template in kCvPdfTemplates) {
        final bytes = await template.build(bareData, fonts).save();
        expect(bytes, isNotEmpty, reason: '${template.id} (bare data) produced no bytes');
      }
    });
  });
}
