import 'package:flutter/material.dart' as material;
import 'package:pdf/pdf.dart';

enum CvFontFamily { sans, serif }

/// A single "#RRGGBB" colour, usable both as a [PdfColor] (template
/// rendering) and a Flutter [material.Color] (the gallery card preview) —
/// so each template names its brand colour once instead of keeping two
/// colour literals in sync.
class CvSwatch {
  const CvSwatch(this.hex);

  final String hex;

  PdfColor get pdf => PdfColor.fromHex(hex);
  material.Color get flutter => material.Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
}

/// One template's colour + type palette — every template picks its own set
/// of values rather than sharing a single ramp, so 20 templates read as 20
/// deliberate designs rather than one design recoloured 20 times.
class CvTemplateTheme {
  const CvTemplateTheme({
    required this.primary,
    required this.accent,
    required this.ink,
    required this.muted,
    required this.background,
    required this.surface,
    this.fontFamily = CvFontFamily.sans,
  });

  /// The dominant brand colour — sidebar/header fills, name, section rules.
  final PdfColor primary;

  /// Secondary highlight colour — tags, icons, thin accent rules.
  final PdfColor accent;

  /// Primary body-text colour.
  final PdfColor ink;

  /// Secondary/meta text colour (dates, labels, captions).
  final PdfColor muted;

  /// Page background.
  final PdfColor background;

  /// Card/panel background — equal to [background] for templates with no
  /// distinct panels.
  final PdfColor surface;

  final CvFontFamily fontFamily;
}
