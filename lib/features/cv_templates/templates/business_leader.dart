import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../cv_pdf_components.dart';
import '../cv_pdf_fonts.dart';
import '../cv_template_data.dart';
import '../cv_template_theme.dart';

/// A row of four labelled leadership-pillar boxes (Strategy / Operations /
/// People / Growth — a positioning motif, not officer-specific data) under
/// a dark header band, then Professional Experience and Education & Awards.
pw.Document buildBusinessLeader(
    CvTemplateData data, CvPdfFonts fonts, CvTemplateTheme theme) {
  final styles = CvTextStyles(fonts, theme);
  const pillars = ['Strategy', 'Operations', 'People', 'Growth'];

  pw.Widget pillarBox(String label) => pw.Expanded(
        child: pw.Container(
          margin: const pw.EdgeInsets.only(right: 8),
          padding: const pw.EdgeInsets.symmetric(vertical: 9),
          decoration: pw.BoxDecoration(
            color: theme.surface,
            border: pw.Border.all(color: theme.accent, width: 0.75),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
          ),
          alignment: pw.Alignment.center,
          child: pw.Text(label,
              style: pw.TextStyle(
                  font: fonts.interSemiBold,
                  fontSize: 9,
                  color: theme.primary)),
        ),
      );

  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      maxPages: 6,
      build: (context) => [
        pw.Container(
          width: double.infinity,
          color: theme.primary,
          padding: const pw.EdgeInsets.fromLTRB(32, 28, 32, 20),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(data.titleLine,
                  style: pw.TextStyle(
                      font: fonts.interBold,
                      fontSize: 22,
                      color: PdfColors.white)),
              pw.SizedBox(height: 3),
              pw.Text(
                [data.serviceLabel, data.corpsOrArm]
                    .whereType<String>()
                    .where((s) => s.isNotEmpty)
                    .join(' • '),
                style: pw.TextStyle(
                    font: fonts.interRegular,
                    fontSize: 10,
                    color: PdfColor.fromHex('#FFFFFFCC')),
              ),
              if (cvContactLine(data).isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text(cvContactLine(data),
                    style: pw.TextStyle(
                        font: fonts.interRegular,
                        fontSize: 9,
                        color: PdfColor.fromHex('#FFFFFFCC'))),
              ],
            ],
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(32, 20, 32, 28),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(children: [for (final p in pillars) pillarBox(p)]),
              pw.SizedBox(height: 18),
              if (data.summary.trim().isNotEmpty) ...[
                cvSectionHeading('Leadership Profile', styles),
                pw.Text(data.summary, style: styles.body),
                pw.SizedBox(height: 14),
              ],
              if (data.careerHighlights.isNotEmpty) ...[
                cvSectionHeading('Career Highlights', styles),
                cvBulletList(data.careerHighlights.join('\n'), styles),
                pw.SizedBox(height: 14),
              ],
              if (data.skills.isNotEmpty) ...[
                cvSectionHeading('Core Competencies', styles),
                cvSkillTags(data.skills, styles),
                pw.SizedBox(height: 14),
              ],
              if (data.workExperience.isNotEmpty) ...[
                cvSectionHeading('Professional Experience', styles),
                for (final e in data.workExperience)
                  cvExperienceEntry(
                    roleTitle: e.roleTitle,
                    organizationType: e.organizationType,
                    duration: e.duration,
                    responsibilities: e.responsibilities,
                    styles: styles,
                  ),
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
                            cvSimpleLine('${ed.degree}, ${ed.institution}',
                                ed.year, styles),
                        ],
                      ),
                    ),
                  if (data.honoursAwards.isNotEmpty) ...[
                    pw.SizedBox(width: 20),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          cvSectionHeading('Awards', styles),
                          for (final a in data.honoursAwards)
                            cvSimpleLine(a.name, a.year, styles),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
  return doc;
}
