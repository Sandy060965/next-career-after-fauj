/// The result of civilianizing an officer-named course that wasn't in the
/// curated [kSkillEquivalencies] list. [verified] is true only when the
/// backend's web search found a credible, independent source for the
/// course/institution — false means the translation rests solely on the
/// officer's own description, which the UI must say plainly rather than
/// implying the same confidence as a curated entry.
class CourseCivilianizationResult {
  const CourseCivilianizationResult({
    required this.civilianEquivalent,
    required this.description,
    required this.verified,
    required this.sourceNote,
  });

  final String civilianEquivalent;
  final String description;
  final bool verified;
  final String sourceNote;

  factory CourseCivilianizationResult.fromJson(Map<String, dynamic> json) => CourseCivilianizationResult(
        civilianEquivalent: json['civilianEquivalent'] as String,
        description: json['description'] as String,
        verified: json['verified'] as bool? ?? false,
        sourceNote: json['sourceNote'] as String? ?? '',
      );
}
