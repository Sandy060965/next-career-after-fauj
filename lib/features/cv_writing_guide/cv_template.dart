/// A downloadable, pre-formatted CV template bundled with the app — every
/// field is a plain, bracketed placeholder for the officer to fill in
/// themselves, never invented sample content. All six are single-column
/// and ATS-safe by design (no text boxes, images, or multi-column layout),
/// styled only through typography, colour, and spacing.
class CvTemplate {
  const CvTemplate({
    required this.name,
    required this.description,
    required this.assetPath,
    required this.fileName,
  });

  final String name;
  final String description;

  /// Path under the bundled Flutter assets (see pubspec.yaml).
  final String assetPath;

  /// Suggested file name when the officer saves/shares it.
  final String fileName;
}

const kCvTemplates = [
  CvTemplate(
    name: 'Classic Professional',
    description: 'A traditional serif layout — the safest default for most corporate '
        'applications and the most reliably ATS-readable of the six.',
    assetPath: 'assets/cv_templates/1_classic_professional.docx',
    fileName: 'CV_Template_Classic_Professional.docx',
  ),
  CvTemplate(
    name: 'Modern Minimal',
    description: 'Clean sans-serif styling with a subtle accent colour — professional '
        'without reading as formal or dated.',
    assetPath: 'assets/cv_templates/2_modern_minimal.docx',
    fileName: 'CV_Template_Modern_Minimal.docx',
  ),
  CvTemplate(
    name: 'Executive Leadership',
    description: 'Leads with a Key Achievements section before your role history — suited '
        'to senior officers targeting VP/CXO-level roles.',
    assetPath: 'assets/cv_templates/3_executive_leadership.docx',
    fileName: 'CV_Template_Executive_Leadership.docx',
  ),
  CvTemplate(
    name: 'Early-Career Compact',
    description: 'A genuinely shorter, one-role layout with combined sections — suited to '
        'SSC officers early in their careers with less to fit on the page.',
    assetPath: 'assets/cv_templates/4_early_career_compact.docx',
    fileName: 'CV_Template_Early_Career_Compact.docx',
  ),
  CvTemplate(
    name: 'Technical Specialist',
    description: 'A monospace-accented style suited to EME, Signals, and other '
        'technical-corps officers targeting engineering or IT roles.',
    assetPath: 'assets/cv_templates/5_technical_specialist.docx',
    fileName: 'CV_Template_Technical_Specialist.docx',
  ),
  CvTemplate(
    name: 'Achievement-Focused',
    description: 'Puts your Key Achievements front and centre, before your role history — '
        'useful when your results speak louder than your job titles.',
    assetPath: 'assets/cv_templates/6_achievement_focused.docx',
    fileName: 'CV_Template_Achievement_Focused.docx',
  ),
];
