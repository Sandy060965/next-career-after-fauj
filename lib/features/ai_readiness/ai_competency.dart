enum AiDimension { awareness, productivity, decisionSupport, leadership, governance }

extension AiDimensionLabel on AiDimension {
  String get label => switch (this) {
        AiDimension.awareness => 'AI Awareness',
        AiDimension.productivity => 'AI Productivity',
        AiDimension.decisionSupport => 'AI Decision Support',
        AiDimension.leadership => 'AI Leadership',
        AiDimension.governance => 'AI Governance',
      };

  String get description => switch (this) {
        AiDimension.awareness =>
          'Understand AI, GenAI, LLMs, agents, and their limitations.',
        AiDimension.productivity => 'Use AI to dramatically improve personal productivity.',
        AiDimension.decisionSupport =>
          'Use AI for analysis, research, planning, and decision-making.',
        AiDimension.leadership => 'Lead AI-enabled teams and evaluate AI initiatives.',
        AiDimension.governance =>
          'Understand security, privacy, ethics, and responsible AI.',
      };
}

enum CompetencyPriority { must, should, good }

extension CompetencyPriorityLabel on CompetencyPriority {
  String get label => switch (this) {
        CompetencyPriority.must => 'Must know',
        CompetencyPriority.should => 'Should know',
        CompetencyPriority.good => 'Good to know',
      };
}

/// A fixed reference competency the LLM may select from when identifying
/// gaps — never an invented skill name.
class AiCompetency {
  const AiCompetency({
    required this.id,
    required this.name,
    required this.priority,
    required this.dimension,
  });

  final String id;
  final String name;
  final CompetencyPriority priority;
  final AiDimension dimension;
}

const List<AiCompetency> kAiCompetencies = [
  AiCompetency(
    id: 'fundamentals',
    name: 'AI & Generative AI Fundamentals',
    priority: CompetencyPriority.must,
    dimension: AiDimension.awareness,
  ),
  AiCompetency(
    id: 'llms',
    name: 'LLMs & AI Models',
    priority: CompetencyPriority.must,
    dimension: AiDimension.awareness,
  ),
  AiCompetency(
    id: 'prompting',
    name: 'Prompt Engineering',
    priority: CompetencyPriority.must,
    dimension: AiDimension.productivity,
  ),
  AiCompetency(
    id: 'assistants',
    name: 'Using ChatGPT / Gemini / Claude / Copilot effectively',
    priority: CompetencyPriority.must,
    dimension: AiDimension.productivity,
  ),
  AiCompetency(
    id: 'research',
    name: 'AI-powered Research',
    priority: CompetencyPriority.must,
    dimension: AiDimension.decisionSupport,
  ),
  AiCompetency(
    id: 'productivity',
    name: 'AI Productivity & Office Automation',
    priority: CompetencyPriority.must,
    dimension: AiDimension.productivity,
  ),
  AiCompetency(
    id: 'data-analysis',
    name: 'AI-assisted Data Analysis',
    priority: CompetencyPriority.must,
    dimension: AiDimension.decisionSupport,
  ),
  AiCompetency(
    id: 'communication',
    name: 'AI-assisted Presentations & Communication',
    priority: CompetencyPriority.must,
    dimension: AiDimension.productivity,
  ),
  AiCompetency(
    id: 'agents',
    name: 'AI Agents & Workflow Automation',
    priority: CompetencyPriority.should,
    dimension: AiDimension.productivity,
  ),
  AiCompetency(
    id: 'cybersecurity',
    name: 'AI + Cybersecurity / Deepfakes',
    priority: CompetencyPriority.should,
    dimension: AiDimension.governance,
  ),
  AiCompetency(
    id: 'responsible-ai',
    name: 'Responsible AI / Governance',
    priority: CompetencyPriority.should,
    dimension: AiDimension.governance,
  ),
  AiCompetency(
    id: 'strategy',
    name: 'AI Strategy & Transformation',
    priority: CompetencyPriority.should,
    dimension: AiDimension.leadership,
  ),
  AiCompetency(
    id: 'business-functions',
    name: 'AI for Specific Business Functions',
    priority: CompetencyPriority.should,
    dimension: AiDimension.decisionSupport,
  ),
  AiCompetency(
    id: 'defence-ai',
    name: 'AI in Defence & National Security',
    priority: CompetencyPriority.good,
    dimension: AiDimension.awareness,
  ),
  AiCompetency(
    id: 'ai-business-building',
    name: 'Building AI-enabled Businesses',
    priority: CompetencyPriority.good,
    dimension: AiDimension.leadership,
  ),
];
