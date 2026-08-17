enum AptitudeDimension {
  operationsExecution,
  peopleLeadership,
  strategyGovernance,
  technicalAnalytical,
  stakeholderRelationship,
  structureProcess,
}

extension AptitudeDimensionLabel on AptitudeDimension {
  String get label => switch (this) {
        AptitudeDimension.operationsExecution => 'Operations & Execution',
        AptitudeDimension.peopleLeadership => 'People Leadership & Development',
        AptitudeDimension.strategyGovernance => 'Strategy & Governance',
        AptitudeDimension.technicalAnalytical => 'Technical & Analytical',
        AptitudeDimension.stakeholderRelationship => 'Stakeholder & Relationship Management',
        AptitudeDimension.structureProcess => 'Structure, Process & Compliance',
      };
}

class AptitudeQuestion {
  const AptitudeQuestion({required this.id, required this.dimension, required this.statement});

  final String id;
  final AptitudeDimension dimension;

  /// A statement the officer rates 1 (strongly disagree) to 5 (strongly
  /// agree) — deliberately self-assessment style, not a fabricated
  /// "psychometric test" with invented scientific claims.
  final String statement;
}

const List<AptitudeQuestion> kAptitudeQuestions = [
  // Operations & Execution
  AptitudeQuestion(id: 'ops-1', dimension: AptitudeDimension.operationsExecution, statement: 'I enjoy taking a complex process and making it run more efficiently.'),
  AptitudeQuestion(id: 'ops-2', dimension: AptitudeDimension.operationsExecution, statement: 'I am energised by hands-on, day-to-day execution rather than long-term planning alone.'),
  AptitudeQuestion(id: 'ops-3', dimension: AptitudeDimension.operationsExecution, statement: 'I prefer environments where I can directly control outcomes through my own actions.'),
  AptitudeQuestion(id: 'ops-4', dimension: AptitudeDimension.operationsExecution, statement: 'I am comfortable managing multiple moving parts — people, schedules, resources — at the same time.'),

  // People Leadership & Development
  AptitudeQuestion(id: 'people-1', dimension: AptitudeDimension.peopleLeadership, statement: 'I get real satisfaction from coaching and developing the people who report to me.'),
  AptitudeQuestion(id: 'people-2', dimension: AptitudeDimension.peopleLeadership, statement: 'I naturally take on the role of mentor within a team.'),
  AptitudeQuestion(id: 'people-3', dimension: AptitudeDimension.peopleLeadership, statement: 'Resolving interpersonal conflict within a team is something I handle well, not avoid.'),
  AptitudeQuestion(id: 'people-4', dimension: AptitudeDimension.peopleLeadership, statement: 'I care more about building a strong team than about my own individual recognition.'),

  // Strategy & Governance
  AptitudeQuestion(id: 'strategy-1', dimension: AptitudeDimension.strategyGovernance, statement: 'I enjoy thinking about long-term direction more than day-to-day execution.'),
  AptitudeQuestion(id: 'strategy-2', dimension: AptitudeDimension.strategyGovernance, statement: 'I am comfortable operating with ambiguity and incomplete information at a policy level.'),
  AptitudeQuestion(id: 'strategy-3', dimension: AptitudeDimension.strategyGovernance, statement: 'I am genuinely interested in how organisations govern themselves — rules, oversight, accountability.'),
  AptitudeQuestion(id: 'strategy-4', dimension: AptitudeDimension.strategyGovernance, statement: 'I would rather advise and influence decision-makers than personally implement the decisions.'),

  // Technical & Analytical
  AptitudeQuestion(id: 'tech-1', dimension: AptitudeDimension.technicalAnalytical, statement: 'I enjoy working with data, systems, or technical detail to solve problems.'),
  AptitudeQuestion(id: 'tech-2', dimension: AptitudeDimension.technicalAnalytical, statement: 'I prefer decisions backed by analysis over decisions made on instinct alone.'),
  AptitudeQuestion(id: 'tech-3', dimension: AptitudeDimension.technicalAnalytical, statement: 'I am comfortable learning new technical tools and systems.'),
  AptitudeQuestion(id: 'tech-4', dimension: AptitudeDimension.technicalAnalytical, statement: 'I like understanding how something works at a genuinely deep, technical level.'),

  // Stakeholder & Relationship Management
  AptitudeQuestion(id: 'stakeholder-1', dimension: AptitudeDimension.stakeholderRelationship, statement: 'I am energised by building relationships with people outside my immediate team.'),
  AptitudeQuestion(id: 'stakeholder-2', dimension: AptitudeDimension.stakeholderRelationship, statement: 'I am comfortable representing my organisation to external parties — clients, government, media.'),
  AptitudeQuestion(id: 'stakeholder-3', dimension: AptitudeDimension.stakeholderRelationship, statement: 'I enjoy negotiating and finding common ground between different interests.'),
  AptitudeQuestion(id: 'stakeholder-4', dimension: AptitudeDimension.stakeholderRelationship, statement: 'Networking and relationship-building come naturally to me.'),

  // Structure, Process & Compliance
  AptitudeQuestion(id: 'structure-1', dimension: AptitudeDimension.structureProcess, statement: 'I value having clear processes, rules, and standards in place.'),
  AptitudeQuestion(id: 'structure-2', dimension: AptitudeDimension.structureProcess, statement: 'I am detail-oriented and rarely let things slip through the cracks.'),
  AptitudeQuestion(id: 'structure-3', dimension: AptitudeDimension.structureProcess, statement: 'I am comfortable being the person who ensures rules and safety standards are actually followed.'),
  AptitudeQuestion(id: 'structure-4', dimension: AptitudeDimension.structureProcess, statement: 'I prefer working within a well-defined structure over a loosely defined one.'),
];

/// Which aptitude dimensions each Career Paths vertical draws on most —
/// used to rank verticals by fit, not to editorialise about any one
/// officer.
const Map<String, List<AptitudeDimension>> kVerticalDimensions = {
  'Security': [AptitudeDimension.operationsExecution, AptitudeDimension.structureProcess],
  'Administration': [AptitudeDimension.structureProcess, AptitudeDimension.operationsExecution],
  'Business Development': [AptitudeDimension.stakeholderRelationship, AptitudeDimension.strategyGovernance],
  'Supply Chain': [AptitudeDimension.operationsExecution, AptitudeDimension.technicalAnalytical],
  'Operations': [AptitudeDimension.operationsExecution, AptitudeDimension.structureProcess],
  'HR': [AptitudeDimension.peopleLeadership, AptitudeDimension.stakeholderRelationship],
  'Manufacturing / Technical': [AptitudeDimension.technicalAnalytical, AptitudeDimension.operationsExecution],
  'Project Management': [AptitudeDimension.operationsExecution, AptitudeDimension.structureProcess],
  'Corporate Affairs & Governance': [AptitudeDimension.strategyGovernance, AptitudeDimension.stakeholderRelationship],
  'L&D': [AptitudeDimension.peopleLeadership, AptitudeDimension.structureProcess],
  'Hospitality / Institutional Management': [AptitudeDimension.stakeholderRelationship, AptitudeDimension.structureProcess],
  'IT / Cybersecurity': [AptitudeDimension.technicalAnalytical, AptitudeDimension.structureProcess],
  'PSU / Government': [AptitudeDimension.strategyGovernance, AptitudeDimension.stakeholderRelationship],
};
