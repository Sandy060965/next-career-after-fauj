/// One position the officer describes themselves — [organizationType] is
/// deliberately a generic, officer-written description (e.g. "Infantry
/// battalion, ~800 personnel"), never a unit-identifying designation, since
/// this whole form is officer-authored input, not a service record.
class WorkExperienceEntry {
  const WorkExperienceEntry({
    required this.roleTitle,
    required this.organizationType,
    required this.duration,
    required this.responsibilities,
  });

  final String roleTitle;
  final String organizationType;
  final String duration;
  final String responsibilities;

  Map<String, dynamic> toJson() => {
        'roleTitle': roleTitle,
        'organizationType': organizationType,
        'duration': duration,
        'responsibilities': responsibilities,
      };

  factory WorkExperienceEntry.fromJson(Map<String, dynamic> json) => WorkExperienceEntry(
        roleTitle: json['roleTitle'] as String,
        organizationType: json['organizationType'] as String,
        duration: json['duration'] as String,
        responsibilities: json['responsibilities'] as String,
      );
}

class EducationEntry {
  const EducationEntry({required this.degree, required this.institution, required this.year});

  final String degree;
  final String institution;
  final String year;

  Map<String, dynamic> toJson() => {'degree': degree, 'institution': institution, 'year': year};

  factory EducationEntry.fromJson(Map<String, dynamic> json) => EducationEntry(
        degree: json['degree'] as String,
        institution: json['institution'] as String,
        year: json['year'] as String,
      );
}

class CertificationEntry {
  const CertificationEntry({required this.name, required this.year});

  final String name;
  final String year;

  Map<String, dynamic> toJson() => {'name': name, 'year': year};

  factory CertificationEntry.fromJson(Map<String, dynamic> json) =>
      CertificationEntry(name: json['name'] as String, year: json['year'] as String);
}

/// Everything the officer typed in themselves for a from-scratch CV build —
/// no upload, no extraction, so there's no anti-fabrication ambiguity: the
/// AI call can only ever reorganise and reword these exact facts.
class CvBuilderIntake {
  const CvBuilderIntake({
    this.summary = '',
    this.workExperience = const [],
    this.education = const [],
    this.certifications = const [],
    this.skills = '',
  });

  final String summary;
  final List<WorkExperienceEntry> workExperience;
  final List<EducationEntry> education;
  final List<CertificationEntry> certifications;
  final String skills;

  Map<String, dynamic> toJson() => {
        'summary': summary,
        'workExperience': workExperience.map((e) => e.toJson()).toList(),
        'education': education.map((e) => e.toJson()).toList(),
        'certifications': certifications.map((e) => e.toJson()).toList(),
        'skills': skills,
      };

  factory CvBuilderIntake.fromJson(Map<String, dynamic> json) => CvBuilderIntake(
        summary: json['summary'] as String,
        workExperience: (json['workExperience'] as List)
            .map((e) => WorkExperienceEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        education: (json['education'] as List)
            .map((e) => EducationEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        certifications: (json['certifications'] as List)
            .map((e) => CertificationEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        skills: json['skills'] as String,
      );
}
