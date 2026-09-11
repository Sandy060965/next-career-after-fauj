import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../cv_pdf_components.dart';
import '../cv_pdf_fonts.dart';
import '../cv_template_data.dart';
import '../cv_template_theme.dart';

/// A narrow dark contact-only sidebar (no photo, no skills — just name and
/// contact) beside a white main column carrying everything else, including
/// Core Competencies as a tag grid — the inverse information split from
/// Executive Sidebar, which puts skills in the sidebar instead.
pw.Document buildModernSplit(
    CvTemplateData data, CvPdfFonts fonts, CvTemplateTheme theme) {
  final styles = CvTextStyles(fonts, theme);
  final onSidebar = pw.TextStyle(
      font: fonts.interSemiBold, fontSize: 14, color: PdfColors.white);
  final onSidebarMuted = pw.TextStyle(
      font: fonts.interRegular,
      fontSize: 8.5,
      color: PdfColor.fromHex('#FFFFFFB3'));

  // The dark contact sidebar is short and bounded (name/contact only), so
  // it's safe to pair with the page's first, also-bounded main-column
  // sections (Profile, Career Highlights, Core Competencies) in a Row.
  // Professional Experience and everything after it are separate
  // top-level Column children below — their combined height scales with
  // the officer's appointment count, and a Row can't paginate a child
  // taller than one page — so the sidebar visually appears alongside the
  // opening matter on page 1, with continuation content flowing plainly.
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
              width: 132,
              color: theme.primary,
              padding: const pw.EdgeInsets.fromLTRB(18, 36, 18, 18),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(data.rank, style: onSidebarMuted),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    data.fullName.trim().isEmpty
                        ? ''
                        : '${data.fullName}, Veteran',
                    style: onSidebar,
                  ),
                  pw.SizedBox(height: 14),
                  pw.Container(height: 1, color: PdfColor.fromHex('#FFFFFF33')),
                  pw.SizedBox(height: 14),
                  if (data.mobileNumber.isNotEmpty)
                    pw.Text(data.mobileNumber, style: onSidebarMuted),
                  if (data.email.isNotEmpty) ...[
                    pw.SizedBox(height: 3),
                    pw.Text(data.email, style: onSidebarMuted)
                  ],
                  if (data.serviceLabel.isNotEmpty ||
                      data.corpsOrArm != null) ...[
                    pw.SizedBox(height: 3),
                    pw.Text(
                        [data.serviceLabel, data.corpsOrArm]
                            .whereType<String>()
                            .join(' • '),
                        style: onSidebarMuted),
                  ],
                ],
              ),
            ),
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.fromLTRB(26, 32, 26, 16),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
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
                    if (data.skills.isNotEmpty) ...[
                      cvSectionHeading('Core Competencies', styles),
                      cvSkillTags(data.skills, styles),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(26, 16, 26, 32),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
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
              if (data.certifications.isNotEmpty) ...[
                cvSectionHeading('Certifications', styles),
                for (final c in data.certifications)
                  cvSimpleLine(c.name, c.year, styles),
                pw.SizedBox(height: 6),
              ],
              if (data.education.isNotEmpty) ...[
                cvSectionHeading('Education', styles),
                for (final ed in data.education)
                  cvSimpleLine(
                      '${ed.degree}, ${ed.institution}', ed.year, styles),
              ],
              if (data.honoursAwards.isNotEmpty) ...[
                pw.SizedBox(height: 6),
                cvSectionHeading('Awards', styles),
                for (final a in data.honoursAwards)
                  cvSimpleLine(a.name, a.year, styles),
              ],
            ],
          ),
        ),
      ],
    ),
  );
  return doc;
}
