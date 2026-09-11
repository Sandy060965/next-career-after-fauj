import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../cv_pdf_components.dart';
import '../cv_pdf_fonts.dart';
import '../cv_template_data.dart';
import '../cv_template_theme.dart';

/// A row of honest count-based "impact" tiles (roles / certifications /
/// education / skills — never a fabricated percentage) under the header,
/// then a two-column Strategic Capabilities + Professional Experience body.
pw.Document buildStrategist(CvTemplateData data, CvPdfFonts fonts, CvTemplateTheme theme) {
  final styles = CvTextStyles(fonts, theme);

  pw.Widget tile(String value, String label) => pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 10),
          decoration: pw.BoxDecoration(color: theme.surface, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
          alignment: pw.Alignment.center,
          child: pw.Column(
            children: [
              pw.Text(value, style: pw.TextStyle(font: fonts.interBold, fontSize: 18, color: theme.primary)),
              pw.SizedBox(height: 2),
              pw.Text(label, style: styles.meta, textAlign: pw.TextAlign.center),
            ],
          ),
        ),
      );

  final tiles = <pw.Widget>[
    tile('${data.workExperience.length}', 'Roles Held'),
    tile('${data.certifications.length + data.courses.length}', 'Certifications'),
    tile('${data.education.length}', 'Qualifications'),
    tile('${data.skills.length}', 'Core Skills'),
  ];

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
          [data.serviceLabel, data.corpsOrArm].whereType<String>().where((s) => s.isNotEmpty).join(' • '),
          style: styles.rankTitle,
        ),
        if (cvContactLine(data).isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Text(cvContactLine(data), style: styles.meta),
        ],
        pw.SizedBox(height: 16),
        pw.Row(children: [for (var i = 0; i < tiles.length; i++) ...[if (i > 0) pw.SizedBox(width: 8), tiles[i]]]),
        pw.SizedBox(height: 18),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 4,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (data.summary.trim().isNotEmpty) ...[
                    cvSectionHeading('Executive Summary', styles),
                    pw.Text(data.summary, style: styles.body),
                    pw.SizedBox(height: 14),
                  ],
                  if (data.skills.isNotEmpty) ...[
                    cvSectionHeading('Strategic Capabilities', styles),
                    for (final s in data.skills)
                      pw.Padding(padding: const pw.EdgeInsets.only(bottom: 4), child: pw.Text(s, style: styles.body)),
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
                    for (final ed in data.education) cvSimpleLine('${ed.degree}, ${ed.institution}', ed.year, styles),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
  return doc;
}
