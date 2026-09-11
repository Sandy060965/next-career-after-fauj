import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../cv_pdf_components.dart';
import '../cv_pdf_fonts.dart';
import '../cv_template_data.dart';
import '../cv_template_theme.dart';

/// Full-height coloured sidebar (photo, contact, core competencies) beside
/// a white main column (profile, experience, education) — one layout,
/// themed five ways: Executive Navy/Black/Platinum/Burgundy/Teal.
pw.Document buildExecutiveSidebar(CvTemplateData data, CvPdfFonts fonts, CvTemplateTheme theme) {
  final styles = CvTextStyles(fonts, theme);
  final onSidebar = pw.TextStyle(font: fonts.interSemiBold, fontSize: 15, color: PdfColors.white);
  final onSidebarMuted = pw.TextStyle(font: fonts.interRegular, fontSize: 9, color: PdfColor.fromHex('#FFFFFFB3'));
  final onSidebarHeading =
      pw.TextStyle(font: fonts.interSemiBold, fontSize: 9.5, color: PdfColor.fromHex('#FFFFFFD9'), letterSpacing: 1.2);

  pw.Widget sidebarSection(String heading, pw.Widget child) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 18),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(heading.toUpperCase(), style: onSidebarHeading),
            pw.SizedBox(height: 6),
            child,
          ],
        ),
      );

  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      maxPages: 6,
      build: (context) => [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 172,
              color: theme.primary,
              padding: const pw.EdgeInsets.all(20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Center(child: cvAvatar(data: data, theme: theme, fonts: fonts, size: 72)),
                  pw.SizedBox(height: 12),
                  pw.Text(data.titleLine, style: onSidebar, textAlign: pw.TextAlign.center),
                  if (data.serviceLabel.isNotEmpty || data.corpsOrArm != null) ...[
                    pw.SizedBox(height: 2),
                    pw.Text(
                      [data.serviceLabel, data.corpsOrArm].whereType<String>().join(' • '),
                      style: onSidebarMuted,
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                  if (cvContactLine(data).isNotEmpty)
                    sidebarSection(
                      'Contact',
                      pw.Text(
                        [data.mobileNumber, data.email].where((s) => s.trim().isNotEmpty).join('\n'),
                        style: onSidebarMuted.copyWith(fontSize: 8.5),
                      ),
                    ),
                  if (data.skills.isNotEmpty)
                    sidebarSection(
                      'Core Competencies',
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          for (final skill in data.skills)
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 3),
                              child: pw.Text(skill, style: onSidebarMuted),
                            ),
                        ],
                      ),
                    ),
                  if (data.certifications.isNotEmpty)
                    sidebarSection(
                      'Certifications',
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          for (final c in data.certifications)
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 3),
                              child: pw.Text('${c.name} (${c.year})', style: onSidebarMuted),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.fromLTRB(28, 32, 28, 32),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
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
                      pw.SizedBox(height: 6),
                    ],
                    if (data.education.isNotEmpty) ...[
                      cvSectionHeading('Education', styles),
                      for (final ed in data.education)
                        cvSimpleLine('${ed.degree}, ${ed.institution}', ed.year, styles),
                    ],
                    if (data.courses.isNotEmpty) ...[
                      pw.SizedBox(height: 6),
                      cvSectionHeading('Courses', styles),
                      for (final c in data.courses) cvSimpleLine(c.name, c.year, styles),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
  return doc;
}
