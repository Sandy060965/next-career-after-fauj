import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../cv_pdf_components.dart';
import '../cv_pdf_fonts.dart';
import '../cv_template_data.dart';
import '../cv_template_theme.dart';

/// Warm neutral background, serif type, a centred header with photo, and
/// competencies rendered as elegant inline text (dot-separated) rather
/// than chip tags — a quieter, more editorial register than the corporate
/// templates.
pw.Document buildContemporaryExecutive(
    CvTemplateData data, CvPdfFonts fonts, CvTemplateTheme theme) {
  final styles = CvTextStyles(fonts, theme);

  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(40, 44, 40, 40),
        buildBackground: (context) => pw.FullPage(
            ignoreMargins: true, child: pw.Container(color: theme.background)),
      ),
      maxPages: 6,
      build: (context) => [
        pw.Center(
          child: pw.Column(
            children: [
              cvAvatar(data: data, theme: theme, fonts: fonts, size: 68),
              pw.SizedBox(height: 12),
              pw.Text(
                data.titleLine,
                style: pw.TextStyle(
                  font: fonts.serifBold,
                  fontSize: 22,
                  color: theme.ink,
                  fontFallback: [fonts.interRegular],
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                [data.serviceLabel, data.corpsOrArm]
                    .whereType<String>()
                    .where((s) => s.isNotEmpty)
                    .join('  •  '),
                style: pw.TextStyle(
                  font: fonts.serifRegular,
                  fontSize: 10.5,
                  color: theme.muted,
                  fontFallback: [fonts.interRegular],
                ),
              ),
              if (cvContactLine(data).isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text(cvContactLine(data), style: styles.meta),
              ],
            ],
          ),
        ),
        pw.SizedBox(height: 22),
        if (data.summary.trim().isNotEmpty) ...[
          cvSectionHeading('Executive Profile', styles),
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
          pw.Text(data.skills.join('   •   '), style: styles.body),
          pw.SizedBox(height: 16),
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
        if (data.education.isNotEmpty) ...[
          cvSectionHeading('Education', styles),
          for (final ed in data.education)
            cvSimpleLine('${ed.degree}, ${ed.institution}', ed.year, styles),
        ],
        if (data.certifications.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          cvSectionHeading('Certifications', styles),
          for (final c in data.certifications)
            cvSimpleLine(c.name, c.year, styles),
        ],
      ],
    ),
  );
  return doc;
}
