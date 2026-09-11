enum ResourceCost { free, paid, freeToLearnPaidCertificate }

extension ResourceCostLabel on ResourceCost {
  String get label => switch (this) {
        ResourceCost.free => 'Free',
        ResourceCost.paid => 'Paid',
        ResourceCost.freeToLearnPaidCertificate => 'Free to learn (paid certificate)',
      };
}

enum ResourceType { course, certification, studyMaterial, degreeOrExecutiveProgramme }

extension ResourceTypeLabel on ResourceType {
  String get label => switch (this) {
        ResourceType.course => 'Course',
        ResourceType.certification => 'Certification',
        ResourceType.studyMaterial => 'Study material',
        ResourceType.degreeOrExecutiveProgramme => 'Degree / executive programme',
      };
}

/// The fixed category taxonomy for the Learning Resources Library —
/// mirrors `kCorporateLanguageCategories`'s pattern of a flat, hand-picked
/// list rather than a nested/generated one.
const List<String> kLearningResourceCategories = [
  'AI & Generative AI',
  'Data & Analytics',
  'Project & Programme Management',
  'Operations & Supply Chain',
  'Quality & Process Improvement',
  'Procurement',
  'Finance & Commercial Acumen',
  'Strategy & Leadership',
  'Business Communication',
  'HR & People',
  'IT & Cloud',
  'Cybersecurity',
  'Sales & CRM',
  'ERP & SAP',
  'Corporate Governance & Security',
];

/// One learning resource verified live against the provider's own site
/// (not recited from memory) before being added here — see
/// `learning_resources_data.dart`. Mirrors the "verified, fixed list"
/// discipline already established by `ai_course.dart`'s `AiCourse`, but
/// generalised across every gap dimension the app's Gap Roadmap surfaces
/// (skills, certifications, education), not just AI competencies.
class LearningResource {
  const LearningResource({
    required this.id,
    required this.name,
    required this.provider,
    required this.url,
    required this.category,
    required this.tags,
    required this.level,
    required this.duration,
    required this.cost,
    required this.resourceType,
    required this.description,
    this.practicalProject,
    required this.lastVerified,
  });

  final String id;
  final String name;
  final String provider;
  final String url;

  /// One of [kLearningResourceCategories].
  final String category;

  /// Lowercase keywords used to match this resource against a free-text
  /// Gap Roadmap item — see `learning_resource_matcher.dart`.
  final List<String> tags;

  /// Free-text label (e.g. "Beginner–Intermediate") rather than a strict
  /// enum — many real courses genuinely span more than one level, and
  /// forcing a single value would misrepresent the source.
  final String level;

  final String duration;
  final ResourceCost cost;
  final ResourceType resourceType;
  final String description;

  /// A concrete hands-on exercise that turns the learning into evidence of
  /// capability (e.g. "Build an operations dashboard using a sample
  /// dataset") — null where a practical project doesn't genuinely apply
  /// (e.g. an awareness-level module or a governance credential).
  final String? practicalProject;

  /// ISO date (YYYY-MM-DD) this entry was last checked against the
  /// provider's official site.
  final String lastVerified;
}
