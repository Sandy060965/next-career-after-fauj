/// Narrative supporting content for one [CareerVertical] — how the field
/// actually works, how officers typically grow through it, and what it
/// takes to get in. Deliberately does NOT restate job titles or
/// certifications: those live only in `career_vertical.dart` so there is
/// exactly one source of truth for anything a fabrication check would need
/// to verify. This class is prose only.
class CareerHandbookEntry {
  const CareerHandbookEntry({
    required this.verticalName,
    required this.whatItDoes,
    required this.careerRoadmap,
    required this.whoSucceeds,
    required this.whoStruggles,
    required this.whatYoudNeed,
    this.restrictionNote,
  });

  /// Must exactly match a [CareerVertical.name] in `career_vertical.dart`.
  final String verticalName;
  final String whatItDoes;
  final String careerRoadmap;
  final List<String> whoSucceeds;
  final List<String> whoStruggles;
  final String whatYoudNeed;

  /// Set only for the medical- and JAG-restricted verticals.
  final String? restrictionNote;
}
