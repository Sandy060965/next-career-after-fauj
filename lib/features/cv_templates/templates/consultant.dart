import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../cv_pdf_components.dart';
import '../cv_pdf_fonts.dart';
import '../cv_template_data.dart';
import '../cv_template_theme.dart';

/// A clean white header (small inline photo, no colour block) over a
/// narrow Education/Certifications column beside Professional Experience —
/// distinct from Corporate Banner by having no coloured header panel.
pw.Document buildConsultant(
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
            cvAvatar(data: data, theme: theme, fonts: fonts, size: 52),
            pw.SizedBox(width: 14),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(data.titleLine,
                      style: styles.name.copyWith(fontSize: 19)),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    [data.serviceLabel, data.corpsOrArm]
                        .whereType<String>()
                        .where((s) => s.isNotEmpty)
                        .join(' • '),
                    style: styles.rankTitle,
                  ),
                  if (cvContactLine(data).isNotEmpty)
                    pw.Text(cvContactLine(data), style: styles.meta),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Container(height: 1, color: theme.accent),
        pw.SizedBox(height: 18),
        if (data.summary.trim().isNotEmpty) ...[
          cvSectionHeading('Executive Profile', styles),
          pw.Text(data.summary, style: styles.body),
          pw.SizedBox(height: 16),
        ],
        if (data.careerHighlights.isNotEmpty) ...[
          cvSectionHeading('Career Highlights', styles),
          cvBulletList(data.careerHighlights.join('\n'), styles),
          pw.SizedBox(height: 16),
        ],
        // Professional Experience is a separate top-level Column child
        // below (not sharing a Row with these), since its height scales
        // with the officer's appointment count and a Row can't paginate a
        // child taller than one page.
        if (data.skills.isNotEmpty) ...[
          cvSectionHeading('Areas of Expertise', styles),
          cvSkillTags(data.skills, styles),
          pw.SizedBox(height: 10),
        ],
        if (data.education.isNotEmpty || data.certifications.isNotEmpty)
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
        pw.SizedBox(height: 10),
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
      ],
    ),
  );
  return doc;
}
