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

class CourseEntry {
  const CourseEntry({required this.name, required this.year});

  final String name;
  final String year;

  Map<String, dynamic> toJson() => {'name': name, 'year': year};

  factory CourseEntry.fromJson(Map<String, dynamic> json) =>
      CourseEntry(name: json['name'] as String, year: json['year'] as String);
}

/// [name] is either a selection from the curated `kHonourCategories` list
/// (see honours_awards.dart), or the officer's own typed text when they
/// picked the "Other" sentinel — the sentinel itself is never stored here.
class AwardEntry {
  const AwardEntry({required this.name, required this.year, this.bar = '', this.citation = ''});

  final String name;
  final String year;

  /// e.g. "Bar", "2nd award" — a repeat of the same decoration, kept as a
  /// free-text attribute rather than a separate dropdown entry per repeat.
  final String bar;

  /// Optional, short, officer-written note — same confidentiality caution
  /// as the rest of this screen applies.
  final String citation;

  Map<String, dynamic> toJson() => {'name': name, 'year': year, 'bar': bar, 'citation': citation};

  factory AwardEntry.fromJson(Map<String, dynamic> json) => AwardEntry(
        name: json['name'] as String,
        year: json['year'] as String,
        // Added after AwardEntry was already shipping — default so a cached
        // entry from before this change still parses instead of throwing.
        bar: json['bar'] as String? ?? '',
        citation: json['citation'] as String? ?? '',
      );
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
    this.courses = const [],
    this.honoursAwards = const [],
    this.skills = '',
  });

  final String summary;
  final List<WorkExperienceEntry> workExperience;
  final List<EducationEntry> education;
  final List<CertificationEntry> certifications;
  final List<CourseEntry> courses;
  final List<AwardEntry> honoursAwards;
  final String skills;

  Map<String, dynamic> toJson() => {
        'summary': summary,
        'workExperience': workExperience.map((e) => e.toJson()).toList(),
        'education': education.map((e) => e.toJson()).toList(),
        'certifications': certifications.map((e) => e.toJson()).toList(),
        'courses': courses.map((e) => e.toJson()).toList(),
        'honoursAwards': honoursAwards.map((e) => e.toJson()).toList(),
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
        // Added after the intake was already shipping — default to empty so
        // a cached intake saved before this change still parses instead of
        // throwing and wiping the rest of ProfileRepository's cached state
        // (loadFromStorage loads everything under one try/catch).
        courses: (json['courses'] as List?)
                ?.map((e) => CourseEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        honoursAwards: (json['honoursAwards'] as List?)
                ?.map((e) => AwardEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        skills: json['skills'] as String,
      );
}
