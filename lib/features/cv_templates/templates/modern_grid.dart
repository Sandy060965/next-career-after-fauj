import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../cv_pdf_components.dart';
import '../cv_pdf_fonts.dart';
import '../cv_template_data.dart';
import '../cv_template_theme.dart';

/// A two-column grid: Executive Profile + Core Competencies on the left,
/// Professional Experience on the right, with a full-width Education &
/// Certifications + Achievements footer row.
pw.Document buildModernGrid(
    CvTemplateData data, CvPdfFonts fonts, CvTemplateTheme theme) {
  final styles = CvTextStyles(fonts, theme);

  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(36, 40, 36, 36),
      maxPages: 6,
      build: (context) => [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(data.titleLine, style: styles.name),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    [data.serviceLabel, data.corpsOrArm]
                        .whereType<String>()
                        .where((s) => s.isNotEmpty)
                        .join(' • '),
                    style: styles.rankTitle,
                  ),
                ],
              ),
            ),
            if (cvContactLine(data).isNotEmpty)
              pw.Text(cvContactLine(data), style: styles.meta),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Container(height: 2, color: theme.primary),
        pw.SizedBox(height: 18),
        // Only the short, bounded Profile/Competencies box is boxed —
        // Professional Experience is a separate top-level Column child
        // below, since its height scales with the officer's appointment
        // count and a Row can't paginate a child taller than one page.
        pw.Container(
          padding: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(
              color: theme.surface,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (data.summary.trim().isNotEmpty) ...[
                cvSectionHeading('Executive Profile', styles),
                pw.Text(data.summary, style: styles.body),
                pw.SizedBox(height: 12),
              ],
              if (data.careerHighlights.isNotEmpty) ...[
                cvSectionHeading('Career Highlights', styles),
                cvBulletList(data.careerHighlights.join('\n'), styles),
                pw.SizedBox(height: 12),
              ],
              if (data.skills.isNotEmpty) ...[
                cvSectionHeading('Core Competencies', styles),
                cvSkillTags(data.skills, styles, background: PdfColors.white),
              ],
            ],
          ),
        ),
        pw.SizedBox(height: 14),
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
        pw.SizedBox(height: 8),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (data.education.isNotEmpty || data.certifications.isNotEmpty)
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (data.education.isNotEmpty) ...[
                      cvSectionHeading('Education', styles),
                      for (final ed in data.education)
                        cvSimpleLine(
                            '${ed.degree}, ${ed.institution}', ed.year, styles),
                    ],
                    if (data.certifications.isNotEmpty) ...[
                      pw.SizedBox(height: 6),
                      cvSectionHeading('Certifications', styles),
                      for (final c in data.certifications)
                        cvSimpleLine(c.name, c.year, styles),
                    ],
                  ],
                ),
              ),
            if (data.honoursAwards.isNotEmpty) ...[
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    cvSectionHeading('Achievements', styles),
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
  );
  return doc;
}
