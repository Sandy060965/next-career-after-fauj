import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../cv_pdf_components.dart';
import '../cv_pdf_fonts.dart';
import '../cv_template_data.dart';
import '../cv_template_theme.dart';

/// A coloured top banner (photo, name, contact) over a two-column body —
/// one layout, themed four ways: Corporate Blue/Slate/Indigo/Green.
pw.Document buildCorporateBanner(CvTemplateData data, CvPdfFonts fonts, CvTemplateTheme theme) {
  final styles = CvTextStyles(fonts, theme);
  final onBanner = pw.TextStyle(font: fonts.interBold, fontSize: 20, color: PdfColors.white);
  final onBannerMuted = pw.TextStyle(font: fonts.interRegular, fontSize: 9.5, color: PdfColor.fromHex('#FFFFFFCC'));

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
          padding: const pw.EdgeInsets.fromLTRB(28, 24, 28, 24),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              cvAvatar(data: data, theme: theme, fonts: fonts, size: 56, initialsBackground: PdfColor.fromHex('#FFFFFF33')),
              pw.SizedBox(width: 14),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(data.titleLine, style: onBanner),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      [data.serviceLabel, data.corpsOrArm].whereType<String>().where((s) => s.isNotEmpty).join(' | '),
                      style: onBannerMuted,
                    ),
                    if (cvContactLine(data).isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(cvContactLine(data), style: onBannerMuted),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(28, 24, 28, 28),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 4,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (data.skills.isNotEmpty) ...[
                      cvSectionHeading('Core Competencies', styles),
                      cvSkillTags(data.skills, styles),
                      pw.SizedBox(height: 14),
                    ],
                    if (data.education.isNotEmpty) ...[
                      cvSectionHeading('Education', styles),
                      for (final ed in data.education) cvSimpleLine('${ed.degree}, ${ed.institution}', ed.year, styles),
                      pw.SizedBox(height: 8),
                    ],
                    if (data.certifications.isNotEmpty) ...[
                      cvSectionHeading('Certifications', styles),
                      for (final c in data.certifications) cvSimpleLine(c.name, c.year, styles),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(width: 24),
              pw.Expanded(
                flex: 6,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (data.summary.trim().isNotEmpty) ...[
                      cvSectionHeading('Professional Profile', styles),
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
                    if (data.honoursAwards.isNotEmpty) ...[
                      cvSectionHeading('Key Achievements', styles),
                      for (final a in data.honoursAwards)
                        cvSimpleLine('${a.name}${a.bar.isNotEmpty ? ' (${a.bar})' : ''}', a.year, styles),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  return doc;
}

/// "Corporate Modern" — visually distinct from the banner family: no photo,
/// no colour block, whitespace-driven with a thin rule under the header and
/// small timeline dots marking each role.
pw.Document buildCorporateModern(CvTemplateData data, CvPdfFonts fonts, CvTemplateTheme theme) {
  final styles = CvTextStyles(fonts, theme);

  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(36, 40, 36, 36),
      maxPages: 6,
      build: (context) => [
        pw.Text(data.titleLine, style: pw.TextStyle(font: fonts.interBold, fontSize: 24, color: theme.ink)),
        pw.SizedBox(height: 3),
        pw.Text(
          [data.serviceLabel, data.corpsOrArm].whereType<String>().where((s) => s.isNotEmpty).join('  •  '),
          style: styles.rankTitle,
        ),
        if (cvContactLine(data).isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Text(cvContactLine(data), style: styles.meta),
        ],
        pw.SizedBox(height: 10),
        pw.Container(height: 2, color: theme.accent),
        pw.SizedBox(height: 18),
        if (data.summary.trim().isNotEmpty) ...[
          cvSectionHeading('Profile', styles),
          pw.Text(data.summary, style: styles.body),
          pw.SizedBox(height: 16),
        ],
        if (data.skills.isNotEmpty) ...[
          cvSectionHeading('Core Competencies', styles),
          cvSkillTags(data.skills, styles),
          pw.SizedBox(height: 16),
        ],
        if (data.workExperience.isNotEmpty) ...[
          cvSectionHeading('Professional Experience', styles),
          for (final e in data.workExperience)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 5, right: 10),
                    child: pw.Container(
                      width: 7,
                      height: 7,
                      decoration: pw.BoxDecoration(shape: pw.BoxShape.circle, color: theme.accent),
                    ),
                  ),
                  pw.Expanded(
                    child: cvExperienceEntry(
                      roleTitle: e.roleTitle,
                      organizationType: e.organizationType,
                      duration: e.duration,
                      responsibilities: e.responsibilities,
                      styles: styles,
                    ),
                  ),
                ],
              ),
            ),
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
  );
  return doc;
}
