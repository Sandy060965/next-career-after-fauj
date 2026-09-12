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

    test('business_leader and executive_navy render careerHighlights without error', () async {
      final fonts = await CvPdfFonts.load();
      final withoutHighlights = _sampleData();
      final withHighlights = CvTemplateData(
        fullName: withoutHighlights.fullName,
        rank: withoutHighlights.rank,
        serviceLabel: withoutHighlights.serviceLabel,
        summary: withoutHighlights.summary,
        skills: withoutHighlights.skills,
        careerHighlights: const [
          'Led a major transformation programme spanning multiple locations.',
          'Reduced operating costs by double digits within one budget cycle.',
        ],
        workExperience: withoutHighlights.workExperience,
      );

      for (final id in ['business_leader', 'executive_navy']) {
        final template = kCvPdfTemplates.firstWhere((t) => t.id == id);
        final bytesWith = await template.build(withHighlights, fonts).save();
        expect(bytesWith, isNotEmpty, reason: id);
      }
    });

    // Regression guard for a real bug found while building the 54-example CV
    // Library: buildExecutiveSidebar wraps its whole page body in a single
    // pw.Row, whose cross axis (height) can't be split across pages by the
    // pdf package's Flex-based pagination (only a Row's main/horizontal axis
    // splits cleanly) — so sufficiently detailed data throws a "won't fit"
    // exception instead of flowing to a second page. business_leader avoids
    // this because its page body is a pw.Column (vertical main axis matches
    // the page-break axis, so Flex can split it by child normally).
    test('business_leader accommodates dense, multi-section data without throwing', () async {
      final fonts = await CvPdfFonts.load();
      final template = kCvPdfTemplates.firstWhere((t) => t.id == 'business_leader');
      final dense = CvTemplateData(
        fullName: 'A K Sharma',
        rank: 'Lieutenant General',
        serviceLabel: 'Army',
        summary: List.filled(3, _sampleData().summary).join(' '),
        skills: List.generate(10, (i) => 'Competency Area $i'),
        careerHighlights: List.generate(6, (i) => 'A detailed, sentence-length career highlight number $i.'),
        workExperience: List.generate(
          3,
          (i) => WorkExperienceEntry(
            roleTitle: 'Senior Appointment $i',
            organizationType: '',
            duration: '20${10 + i}–20${13 + i}',
            responsibilities: List.generate(5, (j) => 'A detailed responsibility bullet number $j.').join('\n'),
          ),
        ),
        education: _sampleData().education,
        courses: _sampleData().courses,
        honoursAwards: List.generate(3, (i) => AwardEntry(name: 'Award $i', year: '201$i')),
      );

      final bytes = await template.build(dense, fonts).save();
      expect(bytes, isNotEmpty);
    });

    // Every one of the 20 templates against Lieutenant General-scale data —
    // 13 appointments (3 detailed + 10 brief) and 9 courses, the densest the
    // Sample CV Library actually produces. Regression guard for the same
    // "Row can't paginate vertically" bug above, now checked across all 20
    // template IDs rather than just business_leader/executive_navy — found
    // to affect 13 of the 20 while rolling Career Highlights out further:
    // executive_sidebar's 5 colour IDs, modern_split, consultant,
    // corporate_banner's 4 colour IDs, modern_grid and strategist.
    test('every template accommodates Lieutenant General-scale density without throwing', () async {
      final fonts = await CvPdfFonts.load();
      final dense = CvTemplateData(
        fullName: 'A K Sharma',
        rank: 'Lieutenant General',
        serviceLabel: 'Army',
        summary: List.filled(3, _sampleData().summary).join(' '),
        skills: List.generate(10, (i) => 'Competency Area $i'),
        careerHighlights: List.generate(6, (i) => 'A detailed, sentence-length career highlight number $i.'),
        workExperience: [
          for (var i = 0; i < 3; i++)
            WorkExperienceEntry(
              roleTitle: 'Senior Appointment $i',
              organizationType: '',
              duration: 'Jul 20${10 + i} – Jun 20${13 + i}',
              responsibilities: List.generate(5, (j) => 'A detailed responsibility bullet number $j.').join('\n'),
            ),
          for (var i = 3; i < 13; i++)
            WorkExperienceEntry(
              roleTitle: 'Earlier Appointment $i',
              organizationType: '',
              duration: 'Jul 19${80 + i} – Jun 19${82 + i}',
              responsibilities: '',
            ),
        ],
        education: List.generate(4, (i) => EducationEntry(degree: 'Degree $i', institution: 'Institution $i', year: '20$i')),
        courses: List.generate(9, (i) => CourseEntry(name: 'Course $i', year: '20$i')),
        honoursAwards: List.generate(4, (i) => AwardEntry(name: 'Award $i', year: '20$i')),
      );

      for (final template in kCvPdfTemplates) {
        final bytes = await template.build(dense, fonts).save();
        expect(bytes, isNotEmpty, reason: template.id);
      }
    });
  });
}
