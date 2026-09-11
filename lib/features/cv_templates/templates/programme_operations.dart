import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../cv_pdf_components.dart';
import '../cv_pdf_fonts.dart';
import '../cv_template_data.dart';
import '../cv_template_theme.dart';

/// Clean and minimal, numbered milestone badges (not plain dots) marking
/// each role — distinct from Corporate Modern's timeline-dot treatment.
pw.Document buildProgrammeOperations(
    CvTemplateData data, CvPdfFonts fonts, CvTemplateTheme theme) {
  final styles = CvTextStyles(fonts, theme);

  pw.Widget milestoneBadge(int n) => pw.Container(
        width: 18,
        height: 18,
        margin: const pw.EdgeInsets.only(top: 2, right: 10),
        decoration:
            pw.BoxDecoration(shape: pw.BoxShape.circle, color: theme.primary),
        alignment: pw.Alignment.center,
        child: pw.Text('$n',
            style: pw.TextStyle(
                font: fonts.interSemiBold,
                fontSize: 8.5,
                color: PdfColors.white)),
      );

  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(36, 40, 36, 36),
      maxPages: 6,
      build: (context) => [
        pw.Text(data.titleLine, style: styles.name),
        pw.SizedBox(height: 2),
        pw.Text(
          [data.serviceLabel, data.corpsOrArm]
              .whereType<String>()
              .where((s) => s.isNotEmpty)
              .join(' • '),
          style: styles.rankTitle,
        ),
        if (cvContactLine(data).isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Text(cvContactLine(data), style: styles.meta),
        ],
        pw.SizedBox(height: 6),
        pw.Container(height: 1.5, color: theme.accent),
        pw.SizedBox(height: 18),
        if (data.summary.trim().isNotEmpty) ...[
          cvSectionHeading('Profile', styles),
          pw.Text(data.summary, style: styles.body),
          pw.SizedBox(height: 14),
        ],
        if (data.careerHighlights.isNotEmpty) ...[
          cvSectionHeading('Career Highlights', styles),
          cvBulletList(data.careerHighlights.join('\n'), styles),
          pw.SizedBox(height: 14),
        ],
        if (data.workExperience.isNotEmpty) ...[
          cvSectionHeading('Professional Experience', styles),
          for (var i = 0; i < data.workExperience.length; i++)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  milestoneBadge(i + 1),
                  pw.Expanded(
                    child: cvExperienceEntry(
                      roleTitle: data.workExperience[i].roleTitle,
                      organizationType: data.workExperience[i].organizationType,
                      duration: data.workExperience[i].duration,
                      responsibilities: data.workExperience[i].responsibilities,
                      styles: styles,
                    ),
                  ),
                ],
              ),
            ),
        ],
        if (data.skills.isNotEmpty) ...[
          cvSectionHeading('Core Competencies', styles),
          cvSkillTags(data.skills, styles),
          pw.SizedBox(height: 12),
        ],
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (data.education.isNotEmpty)
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    cvSectionHeading('Education', styles),
                    for (final ed in data.education)
                      cvSimpleLine(
                          '${ed.degree}, ${ed.institution}', ed.year, styles),
                  ],
                ),
              ),
            if (data.certifications.isNotEmpty) ...[
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    cvSectionHeading('Certifications', styles),
                    for (final c in data.certifications)
                      cvSimpleLine(c.name, c.year, styles),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    ),
  );
  return doc;
}
