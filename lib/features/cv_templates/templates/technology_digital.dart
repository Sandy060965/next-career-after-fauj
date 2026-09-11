import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../cv_pdf_components.dart';
import '../cv_pdf_fonts.dart';
import '../cv_template_data.dart';
import '../cv_template_theme.dart';

/// A dark tech-toned header band with photo and role-focus tags, on a
/// light body — Professional Experience, then Education & Certifications.
pw.Document buildTechnologyDigital(CvTemplateData data, CvPdfFonts fonts, CvTemplateTheme theme) {
  final styles = CvTextStyles(fonts, theme);
  final tagStyle = pw.TextStyle(font: fonts.interMedium, fontSize: 8, color: PdfColors.white);

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
          padding: const pw.EdgeInsets.fromLTRB(30, 28, 30, 24),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              cvAvatar(data: data, theme: theme, fonts: fonts, size: 58, initialsBackground: theme.accent),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(data.titleLine, style: pw.TextStyle(font: fonts.interBold, fontSize: 19, color: PdfColors.white)),
                    pw.SizedBox(height: 5),
                    if (data.skills.isNotEmpty)
                      pw.Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final s in data.skills.take(6))
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: pw.BoxDecoration(
                                color: theme.accent,
                                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                              ),
                              child: pw.Text(s, style: tagStyle),
                            ),
                        ],
                      ),
                    if (cvContactLine(data).isNotEmpty) ...[
                      pw.SizedBox(height: 6),
                      pw.Text(cvContactLine(data), style: pw.TextStyle(font: fonts.interRegular, fontSize: 8.5, color: PdfColor.fromHex('#FFFFFFCC'))),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(30, 24, 30, 28),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (data.summary.trim().isNotEmpty) ...[
                cvSectionHeading('Digital Leadership Profile', styles),
                pw.Text(data.summary, style: styles.body),
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
                          for (final ed in data.education) cvSimpleLine('${ed.degree}, ${ed.institution}', ed.year, styles),
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
                          for (final c in data.certifications) cvSimpleLine(c.name, c.year, styles),
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
