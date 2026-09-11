import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

/// Every font weight/style any template needs, loaded once and passed into
/// each template's build function — mirrors the loading pattern already
/// used by pdf_export.dart, just with more weights and a second family.
class CvPdfFonts {
  const CvPdfFonts({
    required this.interRegular,
    required this.interMedium,
    required this.interSemiBold,
    required this.interBold,
    required this.serifRegular,
    required this.serifItalic,
    required this.serifSemiBold,
    required this.serifBold,
  });

  final pw.Font interRegular;
  final pw.Font interMedium;
  final pw.Font interSemiBold;
  final pw.Font interBold;

  /// Crimson Text — the editorial/serif face for templates that call for
  /// one (Editorial Executive, Contemporary Executive).
  final pw.Font serifRegular;
  final pw.Font serifItalic;
  final pw.Font serifSemiBold;
  final pw.Font serifBold;

  static Future<CvPdfFonts> load() async {
    Future<pw.Font> ttf(String path) async => pw.Font.ttf(await rootBundle.load(path));
    final loaded = await Future.wait([
      ttf('assets/fonts/Inter/Inter-Regular.ttf'),
      ttf('assets/fonts/Inter/Inter-Medium.ttf'),
      ttf('assets/fonts/Inter/Inter-SemiBold.ttf'),
      ttf('assets/fonts/Inter/Inter-Bold.ttf'),
      ttf('assets/fonts/CrimsonText/CrimsonText-Regular.ttf'),
      ttf('assets/fonts/CrimsonText/CrimsonText-Italic.ttf'),
      ttf('assets/fonts/CrimsonText/CrimsonText-SemiBold.ttf'),
      ttf('assets/fonts/CrimsonText/CrimsonText-Bold.ttf'),
    ]);
    return CvPdfFonts(
      interRegular: loaded[0],
      interMedium: loaded[1],
      interSemiBold: loaded[2],
      interBold: loaded[3],
      serifRegular: loaded[4],
      serifItalic: loaded[5],
      serifSemiBold: loaded[6],
      serifBold: loaded[7],
    );
  }
}
