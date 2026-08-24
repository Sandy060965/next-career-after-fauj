/// A general-purpose, JD-independent civilian version of the officer's CV —
/// reuses the same reframe-only rewriting discipline as JD Match's refined
/// CV, just without a target job description to tailor toward.
class CivilianizedCv {
  const CivilianizedCv({required this.civilianizedCv, required this.translationNotes});

  final String civilianizedCv;
  final List<String> translationNotes;

  Map<String, dynamic> toJson() => {
        'civilianizedCv': civilianizedCv,
        'translationNotes': translationNotes,
      };

  factory CivilianizedCv.fromJson(Map<String, dynamic> json) => CivilianizedCv(
        civilianizedCv: json['civilianizedCv'] as String,
        translationNotes: (json['translationNotes'] as List).map((e) => e as String).toList(),
      );
}
