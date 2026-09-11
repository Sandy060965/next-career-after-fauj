import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../cv_pdf_components.dart';
import '../cv_pdf_fonts.dart';
import '../cv_template_data.dart';
import '../cv_template_theme.dart';

/// Magazine-style: large italic serif name, and the officer's own summary
/// sentence set large as a pull-quote (real data, just styled prominently
/// — never invented copy), then Key Strengths, Experience, Education &
/// Recognition.
pw.Document buildEditorialExecutive(CvTemplateData data, CvPdfFonts fonts, CvTemplateTheme theme) {
  final styles = CvTextStyles(fonts, theme);
  final firstSentence = data.summary.split(RegExp(r'(?<=[.!?])\s')).firstWhere((s) => s.trim().isNotEmpty, orElse: () => '');

  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(40, 44, 40, 40),
      maxPages: 6,
      build: (context) => [
        pw.Text(
          data.titleLine,
          style: pw.TextStyle(
            font: fonts.serifBold,
            fontSize: 26,
            color: theme.primary,
            fontFallback: [fonts.interRegular],
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          [data.serviceLabel, data.corpsOrArm].whereType<String>().where((s) => s.isNotEmpty).join(' | '),
          style: pw.TextStyle(
            font: fonts.serifRegular,
            fontSize: 11,
            color: theme.muted,
            fontFallback: [fonts.interRegular],
          ),
        ),
        if (cvContactLine(data).isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Text(cvContactLine(data), style: styles.meta),
        ],
        if (firstSentence.isNotEmpty) ...[
          pw.SizedBox(height: 18),
          pw.Container(
            padding: const pw.EdgeInsets.only(left: 14),
            decoration: pw.BoxDecoration(border: pw.Border(left: pw.BorderSide(color: theme.accent, width: 2.5))),
            child: pw.Text(
              '"$firstSentence"',
              style: pw.TextStyle(
                font: fonts.serifItalic,
                fontSize: 13.5,
                color: theme.ink,
                fontFallback: [fonts.interRegular],
              ),
            ),
          ),
        ],
        pw.SizedBox(height: 20),
        if (data.summary.trim().isNotEmpty) ...[
          cvSectionHeading('Executive Profile', styles),
          pw.Text(data.summary, style: styles.body),
          pw.SizedBox(height: 14),
        ],
        if (data.skills.isNotEmpty) ...[
          cvSectionHeading('Key Strengths', styles),
          cvSkillTags(data.skills, styles),
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
        if (data.education.isNotEmpty || data.honoursAwards.isNotEmpty) ...[
          cvSectionHeading('Education & Recognition', styles),
          for (final ed in data.education) cvSimpleLine('${ed.degree}, ${ed.institution}', ed.year, styles),
          for (final a in data.honoursAwards) cvSimpleLine(a.name, a.year, styles),
        ],
      ],
    ),
  );
  return doc;
}
