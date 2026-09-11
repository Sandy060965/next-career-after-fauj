import '../cv_templates/cv_template_data.dart';

/// Which of the library's three career tracks this example targets —
/// mirrors the source library's A/B/C archetypes.
enum CvExampleArchetype {
  operationsAndGeneralManagement('Operations & General Management'),
  technologyAndFunctional('Technology, Systems & Functional Leadership'),
  strategyAndTransformation('Strategy, Transformation & Corporate Leadership');

  const CvExampleArchetype(this.label);

  final String label;
}

/// One entry in the 54-sample CV reference library — a fictional composite
/// meant to show officers how a professional CV writer would phrase their
/// CV at a given service/rank/career-track, never real per-officer data.
/// See lib/features/cv_examples/cv_examples_data.dart (generated) for the
/// 54 instances, and scratchpad/parse_cv_library.py (this session's
/// scratchpad, not part of the app) for how they were extracted from the
/// source library.
class CvExample {
  const CvExample({
    required this.serviceLabel,
    required this.rank,
    required this.archetype,
    required this.templateId,
    required this.data,
  });

  final String serviceLabel;
  final String rank;
  final CvExampleArchetype archetype;

  /// Which of the 20 CV templates (see cv_template_registry.dart) this
  /// example renders with by default — one fixed template per archetype,
  /// so all examples in the same career track share one visual language.
  /// Officers can still switch to a different template from the gallery.
  final String templateId;

  final CvTemplateData data;
}
