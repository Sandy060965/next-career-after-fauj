import '../career_paths/career_vertical.dart';
import '../career_paths/corps_affinity.dart';

/// Everything in this file is derived directly from the app's own verified
/// vertical data (`career_vertical.dart`) or is generic, non-India-specific
/// business vocabulary — nothing here is generated content, so none of it
/// needs a fabrication check the way the narrative entries do.

/// A single row of the vertical comparison/shortlist table.
class HandbookComparisonRow {
  const HandbookComparisonRow({
    required this.name,
    required this.category,
    required this.restriction,
    required this.bridgeCertifications,
  });

  final String name;
  final String category;

  /// Null for the 20 unrestricted verticals.
  final String? restriction;
  final List<String> bridgeCertifications;
}

const _medicalRestriction = 'Medical branches only';
const _legalRestriction = 'JAG branch only';

/// Null for the 20 unrestricted verticals — derived from the vertical's own
/// category, so this is available immediately, independent of whether a
/// [CareerHandbookEntry]'s narrative content has landed yet.
String? restrictionLabelFor(CareerVertical vertical) {
  if (vertical.category == 'Medical & Healthcare') return _medicalRestriction;
  if (vertical.category == 'Legal & Governance') return _legalRestriction;
  return null;
}

List<HandbookComparisonRow> get kHandbookComparisonRows => kAllBrowsableVerticals
    .map(
      (v) => HandbookComparisonRow(
        name: v.name,
        category: v.category,
        restriction: restrictionLabelFor(v),
        bridgeCertifications: v.bridgeCertifications,
      ),
    )
    .toList();

/// Up to 3 other verticals in the same category — a lightweight "also look
/// at" pointer, computed from the existing category grouping rather than
/// any new claim about which fields are "related."
List<CareerVertical> relatedVerticals(CareerVertical vertical) {
  return kAllBrowsableVerticals
      .where((v) => v.category == vertical.category && v.name != vertical.name)
      .take(3)
      .toList();
}


/// General guidance for officers whose background is a partial match to a
/// restricted vertical's typical entry point — not a claim about any
/// specific employer's policy, just a framing note.
const String kHandbookHybridFitNote =
    'A partial match doesn’t automatically rule a vertical out. For the 20 general '
    'verticals, treat the "what you’d need" line as a strong preference rather than a '
    'hard gate — recruiters weigh demonstrated experience heavily, and a missing '
    'certification can usually be picked up during or after the transition. The medical- '
    'and JAG-restricted verticals are the exception: those restrictions reflect a licensing '
    'requirement (medical registration, or a law degree with Bar enrolment) that experience '
    'alone typically cannot substitute for, so they are realistically only open to officers '
    'who hold that qualification.';

/// The five experience bands every vertical's ladder uses, restated once
/// here as plain guidance rather than repeated inside every entry (matches
/// the tier boundaries already encoded in every CareerLevel).
const String kHandbookTierBandNote =
    'Every vertical’s ladder is anchored to the same five experience bands: '
    'Tier 1 (10–14 years), Tier 2 (15–20 years), Tier 3 (21–27 years), Tier 4 '
    '(28–34 years) and Tier 5 (35–42 years). These are typical bands, not a '
    'promotion guarantee, and your own years of experience already determine which rung is '
    'highlighted for you throughout Career Paths.';
