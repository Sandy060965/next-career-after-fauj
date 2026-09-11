import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'cv_pdf_fonts.dart';
import 'cv_template_data.dart';
import 'cv_template_theme.dart';

/// Named text styles for one template render, derived once from its
/// [CvPdfFonts]/[CvTemplateTheme] so every template composes styles by name
/// instead of repeating font/weight/size plumbing.
class CvTextStyles {
  CvTextStyles(this.fonts, this.theme);

  final CvPdfFonts fonts;
  final CvTemplateTheme theme;

  bool get _serif => theme.fontFamily == CvFontFamily.serif;

  // Crimson Text (the serif face) has no ₹ glyph — and rupee figures are
  // exactly what this app's own CV guidance tells officers to quantify
  // achievements with — so every serif style falls back to Inter, which
  // does cover it, for any character Crimson Text is missing.
  List<pw.Font> get _serifFallback => _serif ? [fonts.interRegular] : const [];

  pw.TextStyle get name => pw.TextStyle(
        font: _serif ? fonts.serifBold : fonts.interBold,
        fontSize: 22,
        color: theme.ink,
        fontFallback: _serifFallback,
      );

  pw.TextStyle get rankTitle => pw.TextStyle(
        font: _serif ? fonts.serifRegular : fonts.interMedium,
        fontSize: 11,
        color: theme.muted,
        fontFallback: _serifFallback,
      );

  pw.TextStyle get sectionHeading => pw.TextStyle(
        font: _serif ? fonts.serifSemiBold : fonts.interSemiBold,
        fontSize: 11,
        color: theme.primary,
        letterSpacing: 1.0,
        fontFallback: _serifFallback,
      );

  pw.TextStyle get roleTitle => pw.TextStyle(
        font: _serif ? fonts.serifSemiBold : fonts.interSemiBold,
        fontSize: 10.5,
        color: theme.ink,
        fontFallback: _serifFallback,
      );

  pw.TextStyle get meta => pw.TextStyle(font: fonts.interRegular, fontSize: 8.5, color: theme.muted);

  pw.TextStyle get body => pw.TextStyle(
        font: _serif ? fonts.serifRegular : fonts.interRegular,
        fontSize: 9.3,
        color: theme.ink,
        fontFallback: _serifFallback,
      );

  pw.TextStyle get tag => pw.TextStyle(font: fonts.interMedium, fontSize: 8, color: theme.primary);
}

/// A circular photo, or an initials avatar in the theme's primary colour
/// when no photo was provided — photo is always optional.
pw.Widget cvAvatar({
  required CvTemplateData data,
  required CvTemplateTheme theme,
  required CvPdfFonts fonts,
  double size = 64,
  PdfColor? initialsBackground,
  PdfColor? initialsColor,
}) {
  if (data.photoBytes != null) {
    return pw.ClipOval(
      child: pw.Image(
        pw.MemoryImage(data.photoBytes!),
        width: size,
        height: size,
        fit: pw.BoxFit.cover,
      ),
    );
  }
  return pw.Container(
    width: size,
    height: size,
    decoration: pw.BoxDecoration(
      shape: pw.BoxShape.circle,
      color: initialsBackground ?? theme.primary,
    ),
    alignment: pw.Alignment.center,
    child: pw.Text(
      data.initials,
      style: pw.TextStyle(
        font: fonts.interSemiBold,
        fontSize: size * 0.32,
        color: initialsColor ?? PdfColors.white,
      ),
    ),
  );
}

/// A section heading with a thin accent rule underneath.
pw.Widget cvSectionHeading(String text, CvTextStyles styles, {PdfColor? ruleColor}) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(text.toUpperCase(), style: styles.sectionHeading),
      pw.SizedBox(height: 3),
      pw.Container(height: 1.2, width: 28, color: ruleColor ?? styles.theme.accent),
      pw.SizedBox(height: 6),
    ],
  );
}

/// Splits free-text responsibilities into bullet lines (by newline; falls
/// back to the whole string as one bullet if the officer typed no breaks).
List<String> cvBulletLines(String text) {
  final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
  return lines.isEmpty ? (text.trim().isEmpty ? const [] : [text.trim()]) : lines;
}

pw.Widget cvBulletList(String text, CvTextStyles styles, {PdfColor? bulletColor, pw.TextStyle? style}) {
  final lines = cvBulletLines(text);
  final textStyle = style ?? styles.body;
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      for (final line in lines)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 2),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                margin: const pw.EdgeInsets.only(top: 4, right: 6),
                width: 3,
                height: 3,
                decoration: pw.BoxDecoration(shape: pw.BoxShape.circle, color: bulletColor ?? styles.theme.accent),
              ),
              pw.Expanded(child: pw.Text(line, style: textStyle)),
            ],
          ),
        ),
    ],
  );
}

/// A wrap of small rounded skill/competency tags.
pw.Widget cvSkillTags(List<String> skills, CvTextStyles styles, {PdfColor? background, pw.TextStyle? style}) {
  return pw.Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      for (final skill in skills)
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: pw.BoxDecoration(
            color: background ?? PdfColor.fromHex('#F1F3F6'),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
          ),
          child: pw.Text(skill, style: style ?? styles.tag),
        ),
    ],
  );
}

/// One work-experience entry: role title, organisation/duration meta line,
/// and bullet-listed responsibilities.
pw.Widget cvExperienceEntry({
  required String roleTitle,
  required String organizationType,
  required String duration,
  required String responsibilities,
  required CvTextStyles styles,
  pw.TextStyle? titleStyle,
  pw.TextStyle? metaStyle,
}) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(child: pw.Text(roleTitle, style: titleStyle ?? styles.roleTitle)),
          pw.Text(duration, style: metaStyle ?? styles.meta),
        ],
      ),
      pw.SizedBox(height: 1),
      pw.Text(organizationType, style: metaStyle ?? styles.meta),
      pw.SizedBox(height: 4),
      cvBulletList(responsibilities, styles),
      pw.SizedBox(height: 10),
    ],
  );
}

/// One "Degree, Institution — Year" style line (education/certifications).
pw.Widget cvSimpleLine(String left, String right, CvTextStyles styles, {pw.TextStyle? leftStyle}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 5),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Expanded(child: pw.Text(left, style: leftStyle ?? styles.body)),
        if (right.isNotEmpty) pw.Text(right, style: styles.meta),
      ],
    ),
  );
}

/// "9876543210  •  officer@example.com" — omits either side if empty.
String cvContactLine(CvTemplateData data, {String separator = '   •   '}) {
  return [data.mobileNumber, data.email].where((s) => s.trim().isNotEmpty).join(separator);
}
