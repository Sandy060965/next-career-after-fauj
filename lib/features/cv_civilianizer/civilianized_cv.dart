/// One bullet/line that was reframed from military to civilian language —
/// shown as a before/after pair with the civilian-facing skills it now
/// surfaces, so the officer can see exactly what changed and why.
class CvTranslation {
  const CvTranslation({required this.before, required this.after, this.skillTags = const []});

  final String before;
  final String after;
  final List<String> skillTags;

  Map<String, dynamic> toJson() => {
        'before': before,
        'after': after,
        'skillTags': skillTags,
      };

  factory CvTranslation.fromJson(Map<String, dynamic> json) => CvTranslation(
        before: json['before'] as String,
        after: json['after'] as String,
        skillTags: (json['skillTags'] as List? ?? const []).map((e) => e as String).toList(),
      );
}

/// A general-purpose, JD-independent civilian version of the officer's CV —
/// reuses the same reframe-only rewriting discipline as JD Match's refined
/// CV, just without a target job description to tailor toward.
class CivilianizedCv {
  const CivilianizedCv({required this.civilianizedCv, required this.translations});

  final String civilianizedCv;
  final List<CvTranslation> translations;

  Map<String, dynamic> toJson() => {
        'civilianizedCv': civilianizedCv,
        'translations': translations.map((t) => t.toJson()).toList(),
      };

  factory CivilianizedCv.fromJson(Map<String, dynamic> json) => CivilianizedCv(
        civilianizedCv: json['civilianizedCv'] as String,
        translations: (json['translations'] as List? ?? const [])
            .map((e) => CvTranslation.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
