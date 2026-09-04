/// One entry in the Corporate Language Guide — a corporate term/abbreviation
/// with both a quick-reference definition and a deeper transition-focused
/// treatment. The quick-reference fields (term through priorityTier) are
/// taken directly from the source glossary; the deep-dive fields
/// (indianContext through trapForOfficers) are narrative enrichment
/// reviewed for fabrication before use — see `corporate_language_terms.dart`.
class CorporateLanguageTerm {
  const CorporateLanguageTerm({
    required this.term,
    required this.fullForm,
    required this.meaning,
    required this.whereSeen,
    required this.bridge,
    required this.category,
    this.crossCategories = const [],
    this.priorityTier = 0,
    required this.indianContext,
    required this.militaryEquivalent,
    required this.dialogueSnippet,
    required this.trapForOfficers,
  });

  final String term;

  /// '—' when the term isn't an abbreviation of a longer phrase.
  final String fullForm;
  final String meaning;
  final String whereSeen;

  /// Short one-line military-bridge note from the source glossary.
  final String bridge;

  final String category;

  /// Other categories this term also commonly appears under.
  final List<String> crossCategories;

  /// 1 = learn immediately, 2 = within the first month, 3 = build depth as
  /// the role develops, 0 = not in the source's "100 terms" priority list.
  final int priorityTier;

  final String indianContext;
  final String militaryEquivalent;
  final String dialogueSnippet;
  final String trapForOfficers;
}
