import 'dart:typed_data';

import 'ai_competency.dart';
import 'ai_readiness.dart';

typedef AiReadinessAnalyzer = Future<AiReadinessResult> Function({
  required AiSelfAssessment assessment,
  required String cvFileName,
  String? cvExtractedText,
  Uint8List? cvPdfBytes,
  DateTime? releaseDate,
});

/// Placeholder analyzer used until the Cloudflare Worker backend is wired
/// in. Returns fixed sample data regardless of input so the results screens
/// can be built and tested independently of the backend.
Future<AiReadinessResult> mockAnalyzeAiReadiness({
  required AiSelfAssessment assessment,
  required String cvFileName,
  String? cvExtractedText,
  Uint8List? cvPdfBytes,
  DateTime? releaseDate,
}) async {
  await Future.delayed(const Duration(milliseconds: 700));
  return AiReadinessResult(
    readinessScore: assessment.readinessScore,
    scoreRationale:
        'Comfortable with everyday AI assistants and productivity use, but has not yet '
        'used AI for structured decision support or led an AI-enabled initiative.',
    dimensionScores: assessment.dimensionScores,
    skillGaps: const [
      SkillGap(
        competency: AiCompetency(
          id: 'prompting',
          name: 'Prompt Engineering',
          priority: CompetencyPriority.must,
          dimension: AiDimension.productivity,
        ),
        severity: GapSeverity.high,
        reason: 'CV shows AI tool usage but no evidence of structured prompting technique.',
      ),
      SkillGap(
        competency: AiCompetency(
          id: 'data-analysis',
          name: 'AI-assisted Data Analysis',
          priority: CompetencyPriority.must,
          dimension: AiDimension.decisionSupport,
        ),
        severity: GapSeverity.medium,
        reason:
            'Strong track record of data-driven planning, but no direct experience using '
            'AI tools for analysis.',
      ),
      SkillGap(
        competency: AiCompetency(
          id: 'strategy',
          name: 'AI Strategy & Transformation',
          priority: CompetencyPriority.should,
          dimension: AiDimension.leadership,
        ),
        severity: GapSeverity.low,
        reason: 'Leadership experience is strong; AI-specific strategy exposure is untested.',
      ),
    ],
    cvAiBridge:
        'Your logistics digitisation and cross-functional coordination experience maps '
        'directly onto AI-assisted operations: the same discipline used to track inventory '
        'and coordinate teams applies to using AI for research, reporting, and planning. '
        'Building fluency with prompting and AI-assisted analysis would let you apply that '
        'existing judgement faster, with less manual effort.',
    roadmap: const [
      RoadmapItem(
        phase: RoadmapPhase.day30,
        title: 'Build AI fundamentals and everyday fluency',
        description:
            'Complete a foundational course to understand generative AI, LLMs, and safe, '
            'effective everyday use.',
        courseId: 'google-ai-essentials',
      ),
      RoadmapItem(
        phase: RoadmapPhase.day30,
        title: 'Practice structured prompting',
        description:
            'Work through a prompting-focused course to close the largest identified gap.',
        courseId: 'deeplearningai-prompting',
      ),
      RoadmapItem(
        phase: RoadmapPhase.day60,
        title: 'Apply AI to real planning and analysis work',
        description:
            'Use AI assistants for a real research, reporting, or data-analysis task each '
            'week to build practical decision-support experience.',
      ),
      RoadmapItem(
        phase: RoadmapPhase.day60,
        title: 'Attend a live, hands-on workshop',
        description:
            'Join a cohort-based workshop to practice building AI agents and no-code AI '
            'tools alongside peers.',
        courseId: 'outskill-genai-mastermind',
      ),
      RoadmapItem(
        phase: RoadmapPhase.day90,
        title: 'Deepen into AI strategy and governance',
        description:
            'Move from user to advocate: understand responsible AI, governance, and how to '
            'evaluate AI initiatives for a team or business function.',
      ),
    ],
  );
}
