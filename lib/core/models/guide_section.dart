/// One Situation -> [What You May Encounter ->] Recommended Response ->
/// Avoid entry within a [GuideSection]. See guide_scenario_card.dart for
/// how this renders.
class GuideScenario {
  const GuideScenario({
    this.heading,
    required this.situation,
    this.whatYouMayEncounter,
    required this.recommendedResponse,
    required this.avoid,
  });

  /// An optional short mini-title, e.g. "When a Younger Colleague Calls
  /// You by Your First Name" — several scenarios in the source documents
  /// have one, used as a scanable lead-in above the Situation line.
  final String? heading;
  final String situation;
  final String? whatYouMayEncounter;
  final String recommendedResponse;
  final String avoid;
}

/// A simple "military-style phrasing -> corporate formulation" pair —
/// both guides' phrasing-playbook sections use this shape.
class GuideTranslation {
  const GuideTranslation({required this.from, required this.to});

  final String from;
  final String to;
}

/// A generic reference table — both guides also include tables that
/// aren't Situation-shaped (e.g. "Meeting type / Your role / Common
/// mistake", "Channel / Typical use / Practical rule", "Period / Primary
/// objective / What to do"). [rows] entries must each have the same
/// length as [columnHeaders].
class GuideReferenceTable {
  const GuideReferenceTable({required this.columnHeaders, required this.rows});

  final List<String> columnHeaders;
  final List<List<String>> rows;
}

/// One numbered section of a guide (Corporate Culture & Work Environment,
/// Business Etiquette & Professional Conduct). Every field is optional
/// except [title] — a section renders whichever combination of narrative
/// paragraphs, scenario cards, a reference table, phrasing translations,
/// and a checklist it actually has in the source document, rather than
/// forcing every section into one fixed shape.
class GuideSection {
  const GuideSection({
    required this.title,
    this.paragraphs = const [],
    this.scenarios = const [],
    this.referenceTable,
    this.translations = const [],
    this.checklistItems = const [],
    this.closingNote,
  });

  final String title;
  final List<String> paragraphs;
  final List<GuideScenario> scenarios;
  final GuideReferenceTable? referenceTable;
  final List<GuideTranslation> translations;
  final List<String> checklistItems;

  /// A short, often emphasised closing line some sections end with.
  final String? closingNote;
}
