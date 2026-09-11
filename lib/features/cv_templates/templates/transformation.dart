import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../cv_pdf_components.dart';
import '../cv_pdf_fonts.dart';
import '../cv_template_data.dart';
import '../cv_template_theme.dart';

/// A horizontal Discover → Design → Deliver → Sustain stage strip under
/// the header (a methodology motif, not a claim about the officer's own
/// history), then Key Achievements and Professional Experience.
pw.Document buildTransformation(
    CvTemplateData data, CvPdfFonts fonts, CvTemplateTheme theme) {
  final styles = CvTextStyles(fonts, theme);
  const stages = ['Discover', 'Design', 'Deliver', 'Sustain'];

  pw.Widget stageDot(String label, bool isLast) => pw.Expanded(
        child: pw.Column(
          children: [
            pw.Row(
              children: [
                pw.Container(
                  width: 10,
                  height: 10,
                  decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle, color: theme.primary),
                ),
                if (!isLast)
                  pw.Expanded(
                      child: pw.Container(height: 1.5, color: theme.accent)),
              ],
            ),
            pw.SizedBox(height: 5),
            pw.Text(label,
                style: pw.TextStyle(
                    font: fonts.interSemiBold,
                    fontSize: 8.5,
                    color: theme.primary)),
          ],
        ),
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
          'Transformation Leadership | Change | Digital',
          style: pw.TextStyle(
              font: fonts.interMedium, fontSize: 10, color: theme.accent),
        ),
        if (cvContactLine(data).isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Text(cvContactLine(data), style: styles.meta),
        ],
        pw.SizedBox(height: 18),
        pw.Row(children: [
          for (var i = 0; i < stages.length; i++)
            stageDot(stages[i], i == stages.length - 1)
        ]),
        pw.SizedBox(height: 20),
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
        if (data.honoursAwards.isNotEmpty) ...[
          cvSectionHeading('Key Transformation Achievements', styles),
          for (final a in data.honoursAwards)
            cvSimpleLine('${a.name}${a.bar.isNotEmpty ? ' (${a.bar})' : ''}',
                a.year, styles),
          pw.SizedBox(height: 10),
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
        if (data.skills.isNotEmpty) ...[
          cvSectionHeading('Core Competencies', styles),
          cvSkillTags(data.skills, styles),
          pw.SizedBox(height: 10),
        ],
        if (data.education.isNotEmpty) ...[
          cvSectionHeading('Education', styles),
          for (final ed in data.education)
            cvSimpleLine('${ed.degree}, ${ed.institution}', ed.year, styles),
        ],
      ],
    ),
  );
  return doc;
}
