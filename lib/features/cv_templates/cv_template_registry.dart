import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'cv_pdf_fonts.dart';
import 'cv_template_data.dart';
import 'cv_template_theme.dart';
import 'templates/business_leader.dart';
import 'templates/consultant.dart';
import 'templates/contemporary_executive.dart';
import 'templates/corporate_banner.dart';
import 'templates/editorial_executive.dart';
import 'templates/executive_sidebar.dart';
import 'templates/modern_grid.dart';
import 'templates/modern_split.dart';
import 'templates/programme_operations.dart';
import 'templates/strategist.dart';
import 'templates/technology_digital.dart';
import 'templates/transformation.dart';

/// One selectable design in the CV templates gallery.
class CvPdfTemplate {
  const CvPdfTemplate({
    required this.id,
    required this.name,
    required this.blurb,
    required this.swatch,
    required this.build,
  });

  final String id;
  final String name;
  final String blurb;

  /// Drives the gallery card's preview swatch.
  final CvSwatch swatch;

  final pw.Document Function(CvTemplateData data, CvPdfFonts fonts) build;

  /// A static image of this template pre-rendered with realistic sample
  /// data (never the officer's own), bundled as an app asset under
  /// assets/cv_template_previews/ — every entry's `id` doubles as its
  /// preview file name. Not auto-regenerated: if a template's layout
  /// changes, re-render its sample PDF and re-rasterize it by hand.
  ///
  /// This is a crop of just the top ~600px — enough to recognise a design
  /// at a glance in a compact gallery grid, not the full page.
  String get previewAssetPath => 'assets/cv_template_previews/$id.png';

  /// The same sample render as [previewAssetPath], but the full first page
  /// uncropped — shown in the enlarged preview when an officer taps a
  /// thumbnail to actually judge the layout before downloading.
  String get previewFullAssetPath => 'assets/cv_template_previews_full/$id.png';
}

final PdfColor _ink = PdfColor.fromHex('#1F2430');
final PdfColor _muted = PdfColor.fromHex('#6B7280');

/// A dark, full-colour theme (used by the sidebar/banner families) where
/// most body text renders white-on-colour rather than ink-on-white — [ink]
/// still matters for the white main-column text those layouts also have.
CvTemplateTheme _theme(String primaryHex, String accentHex, {String surfaceHex = '#F5F6F8'}) => CvTemplateTheme(
      primary: PdfColor.fromHex(primaryHex),
      accent: PdfColor.fromHex(accentHex),
      ink: _ink,
      muted: _muted,
      background: PdfColors.white,
      surface: PdfColor.fromHex(surfaceHex),
    );

// --- Executive Sidebar family (5 colour variants of one layout) -----------
final _executiveNavy = _theme('#1B2A4A', '#C9A15A');
final _executiveBlack = _theme('#1A1A1A', '#B08D57');
final _executivePlatinum = _theme('#4A4A52', '#8C97A6');
final _executiveBurgundy = _theme('#6B1F2A', '#D4A24C');
final _executiveTeal = _theme('#0F4C4C', '#CDA24A');

// --- Corporate Banner family (4 colour variants + Corporate Modern) -------
final _corporateBlue = _theme('#1565C0', '#FFB300');
final _corporateSlate = _theme('#37474F', '#26A69A');
final _corporateIndigo = _theme('#3730A3', '#F59E0B');
final _corporateGreen = _theme('#1E7145', '#F5B841');
final _corporateModern = _theme('#0F766E', '#0F766E', surfaceHex: '#F0FDFA');

// --- Ten unique layouts -----------------------------------------------
final _strategist = _theme('#0B3D91', '#F2A007');
final _consultant = _theme('#22303C', '#C08A2E');
final _transformationTheme = _theme('#7C3AED', '#F97316');
final _businessLeader = _theme('#111827', '#D4AF37');
final _modernGrid = _theme('#0EA5A4', '#F43F5E');
final _modernSplit = _theme('#1E293B', '#38BDF8');
final _contemporaryExecutive = CvTemplateTheme(
  primary: PdfColor.fromHex('#7A5C3E'),
  accent: PdfColor.fromHex('#B08D57'),
  ink: PdfColor.fromHex('#2B2420'),
  muted: PdfColor.fromHex('#8A7B6A'),
  background: PdfColor.fromHex('#FAF6F0'),
  surface: PdfColor.fromHex('#F3ECE2'),
  fontFamily: CvFontFamily.serif,
);
final _editorialExecutive = CvTemplateTheme(
  primary: PdfColor.fromHex('#8B1E3F'),
  accent: PdfColor.fromHex('#C9A15A'),
  ink: _ink,
  muted: _muted,
  background: PdfColors.white,
  surface: PdfColor.fromHex('#FBF5F6'),
  fontFamily: CvFontFamily.serif,
);
final _technologyDigital = _theme('#0B1F3A', '#00B8A9');
final _programmeOperations = _theme('#0F766E', '#14B8A6');

/// All 20 templates — grouped in the order they read naturally in the
/// gallery (Executive, Corporate, then the ten distinct layouts).
final List<CvPdfTemplate> kCvPdfTemplates = [
  CvPdfTemplate(
    id: 'executive_navy',
    name: 'Executive Navy',
    blurb: 'Full-height navy sidebar, white main column — a senior, boardroom-ready register.',
    swatch: const CvSwatch('#1B2A4A'),
    build: (data, fonts) => buildExecutiveSidebar(data, fonts, _executiveNavy),
  ),
  CvPdfTemplate(
    id: 'executive_black',
    name: 'Executive Black',
    blurb: 'The same sidebar layout in a near-black, high-contrast finish.',
    swatch: const CvSwatch('#1A1A1A'),
    build: (data, fonts) => buildExecutiveSidebar(data, fonts, _executiveBlack),
  ),
  CvPdfTemplate(
    id: 'executive_platinum',
    name: 'Executive Platinum',
    blurb: 'A cooler, silver-grey take on the Executive sidebar.',
    swatch: const CvSwatch('#4A4A52'),
    build: (data, fonts) => buildExecutiveSidebar(data, fonts, _executivePlatinum),
  ),
  CvPdfTemplate(
    id: 'executive_burgundy',
    name: 'Executive Burgundy',
    blurb: 'A warmer, deep-red variant of the Executive sidebar.',
    swatch: const CvSwatch('#6B1F2A'),
    build: (data, fonts) => buildExecutiveSidebar(data, fonts, _executiveBurgundy),
  ),
  CvPdfTemplate(
    id: 'executive_teal',
    name: 'Executive Teal',
    blurb: 'The Executive sidebar in a calmer, teal finish.',
    swatch: const CvSwatch('#0F4C4C'),
    build: (data, fonts) => buildExecutiveSidebar(data, fonts, _executiveTeal),
  ),
  CvPdfTemplate(
    id: 'corporate_blue',
    name: 'Corporate Blue',
    blurb: 'A coloured header banner over a clean two-column body.',
    swatch: const CvSwatch('#1565C0'),
    build: (data, fonts) => buildCorporateBanner(data, fonts, _corporateBlue),
  ),
  CvPdfTemplate(
    id: 'corporate_slate',
    name: 'Corporate Slate',
    blurb: 'The banner layout in an understated slate-grey.',
    swatch: const CvSwatch('#37474F'),
    build: (data, fonts) => buildCorporateBanner(data, fonts, _corporateSlate),
  ),
  CvPdfTemplate(
    id: 'corporate_indigo',
    name: 'Corporate Indigo',
    blurb: 'The banner layout in a confident indigo.',
    swatch: const CvSwatch('#3730A3'),
    build: (data, fonts) => buildCorporateBanner(data, fonts, _corporateIndigo),
  ),
  CvPdfTemplate(
    id: 'corporate_green',
    name: 'Corporate Green',
    blurb: 'The banner layout in a grounded forest green.',
    swatch: const CvSwatch('#1E7145'),
    build: (data, fonts) => buildCorporateBanner(data, fonts, _corporateGreen),
  ),
  CvPdfTemplate(
    id: 'corporate_modern',
    name: 'Corporate Modern',
    blurb: 'No photo, no colour block — whitespace-driven with a teal timeline accent.',
    swatch: const CvSwatch('#0F766E'),
    build: (data, fonts) => buildCorporateModern(data, fonts, _corporateModern),
  ),
  CvPdfTemplate(
    id: 'strategist',
    name: 'Strategist',
    blurb: 'Leads with honest at-a-glance counts (roles, certifications) before your capabilities.',
    swatch: const CvSwatch('#0B3D91'),
    build: (data, fonts) => buildStrategist(data, fonts, _strategist),
  ),
  CvPdfTemplate(
    id: 'consultant',
    name: 'Consultant',
    blurb: 'A clean, photo-inline header with expertise and credentials up front.',
    swatch: const CvSwatch('#22303C'),
    build: (data, fonts) => buildConsultant(data, fonts, _consultant),
  ),
  CvPdfTemplate(
    id: 'transformation',
    name: 'Transformation',
    blurb: 'A Discover-Design-Deliver-Sustain stage strip signals a change-leadership register.',
    swatch: const CvSwatch('#7C3AED'),
    build: (data, fonts) => buildTransformation(data, fonts, _transformationTheme),
  ),
  CvPdfTemplate(
    id: 'business_leader',
    name: 'Business Leader',
    blurb: 'Strategy / Operations / People / Growth pillars under a dark header band.',
    swatch: const CvSwatch('#111827'),
    build: (data, fonts) => buildBusinessLeader(data, fonts, _businessLeader),
  ),
  CvPdfTemplate(
    id: 'modern_grid',
    name: 'Modern Grid',
    blurb: 'A panelled two-column grid with a full-width education/achievements footer.',
    swatch: const CvSwatch('#0EA5A4'),
    build: (data, fonts) => buildModernGrid(data, fonts, _modernGrid),
  ),
  CvPdfTemplate(
    id: 'modern_split',
    name: 'Modern Split',
    blurb: 'A slim contact-only dark sidebar; competencies and everything else in the main column.',
    swatch: const CvSwatch('#1E293B'),
    build: (data, fonts) => buildModernSplit(data, fonts, _modernSplit),
  ),
  CvPdfTemplate(
    id: 'contemporary_executive',
    name: 'Contemporary Executive',
    blurb: 'Warm neutral background, serif type, a quieter editorial register.',
    swatch: const CvSwatch('#7A5C3E'),
    build: (data, fonts) => buildContemporaryExecutive(data, fonts, _contemporaryExecutive),
  ),
  CvPdfTemplate(
    id: 'editorial_executive',
    name: 'Editorial Executive',
    blurb: 'Magazine-style — a serif pull-quote drawn from your own profile summary.',
    swatch: const CvSwatch('#8B1E3F'),
    build: (data, fonts) => buildEditorialExecutive(data, fonts, _editorialExecutive),
  ),
  CvPdfTemplate(
    id: 'technology_digital',
    name: 'Technology & Digital',
    blurb: 'A dark tech-toned header with skill tags, suited to digital/technology roles.',
    swatch: const CvSwatch('#0B1F3A'),
    build: (data, fonts) => buildTechnologyDigital(data, fonts, _technologyDigital),
  ),
  CvPdfTemplate(
    id: 'programme_operations',
    name: 'Programme & Operations',
    blurb: 'Clean and minimal, with numbered milestone badges marking each role.',
    swatch: const CvSwatch('#0F766E'),
    build: (data, fonts) => buildProgrammeOperations(data, fonts, _programmeOperations),
  ),
];
