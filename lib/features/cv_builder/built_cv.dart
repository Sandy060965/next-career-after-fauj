/// The CV text produced from a [CvBuilderIntake] — plain text, ready to
/// display/export.
class BuiltCv {
  const BuiltCv({required this.cvText});

  final String cvText;

  Map<String, dynamic> toJson() => {'cvText': cvText};

  factory BuiltCv.fromJson(Map<String, dynamic> json) => BuiltCv(cvText: json['cvText'] as String);
}
