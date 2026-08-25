/// Interest dimensions modeled on the RIASEC (Holland Code) framework and
/// work-style dimensions modeled on the Big Five — real, well-established
/// public frameworks. This is a self-assessment *inspired by* their
/// structure, not a reproduction of any specific licensed instrument's
/// exact item text (e.g. O*NET's Interest Profiler or a published IPIP
/// inventory) — we don't have verified verbatim rights to those, and
/// guessing at their precise wording would risk misrepresenting a real
/// published tool. "Emotional Stability" is the same construct usually
/// called Neuroticism, framed positively for a workplace self-assessment.
enum AptitudeDimension {
  realistic,
  investigative,
  artistic,
  social,
  enterprising,
  conventional,
  openness,
  conscientiousness,
  extraversion,
  agreeableness,
  emotionalStability,
}

enum DimensionGroup { interests, workStyle }

extension AptitudeDimensionLabel on AptitudeDimension {
  String get label => switch (this) {
        AptitudeDimension.realistic => 'Realistic',
        AptitudeDimension.investigative => 'Investigative',
        AptitudeDimension.artistic => 'Artistic',
        AptitudeDimension.social => 'Social',
        AptitudeDimension.enterprising => 'Enterprising',
        AptitudeDimension.conventional => 'Conventional',
        AptitudeDimension.openness => 'Openness',
        AptitudeDimension.conscientiousness => 'Conscientiousness',
        AptitudeDimension.extraversion => 'Extraversion',
        AptitudeDimension.agreeableness => 'Agreeableness',
        AptitudeDimension.emotionalStability => 'Emotional Stability',
      };

  DimensionGroup get group => switch (this) {
        AptitudeDimension.realistic ||
        AptitudeDimension.investigative ||
        AptitudeDimension.artistic ||
        AptitudeDimension.social ||
        AptitudeDimension.enterprising ||
        AptitudeDimension.conventional =>
          DimensionGroup.interests,
        AptitudeDimension.openness ||
        AptitudeDimension.conscientiousness ||
        AptitudeDimension.extraversion ||
        AptitudeDimension.agreeableness ||
        AptitudeDimension.emotionalStability =>
          DimensionGroup.workStyle,
      };
}

extension DimensionGroupLabel on DimensionGroup {
  String get label => switch (this) {
        DimensionGroup.interests => 'Interests',
        DimensionGroup.workStyle => 'Work Style',
      };

  String get description => switch (this) {
        DimensionGroup.interests =>
          'What kind of work draws you in — modeled on the RIASEC framework.',
        DimensionGroup.workStyle =>
          'How you tend to operate day to day — modeled on the Big Five.',
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
  // --- Interests (RIASEC-inspired) ---
  AptitudeQuestion(id: 'realistic-1', dimension: AptitudeDimension.realistic, statement: 'I enjoy working with physical equipment, systems, or infrastructure rather than only abstract ideas.'),
  AptitudeQuestion(id: 'realistic-2', dimension: AptitudeDimension.realistic, statement: 'I like troubleshooting and fixing things myself rather than only delegating the hands-on work.'),
  AptitudeQuestion(id: 'realistic-3', dimension: AptitudeDimension.realistic, statement: 'I prefer roles where I can see a tangible, physical result of my work.'),

  AptitudeQuestion(id: 'investigative-1', dimension: AptitudeDimension.investigative, statement: 'I enjoy digging into a complex problem to understand its root cause before acting.'),
  AptitudeQuestion(id: 'investigative-2', dimension: AptitudeDimension.investigative, statement: 'I like researching and comparing options thoroughly before making a decision.'),
  AptitudeQuestion(id: 'investigative-3', dimension: AptitudeDimension.investigative, statement: 'I am drawn to work that involves data, analysis, or technical reasoning.'),

  AptitudeQuestion(id: 'artistic-1', dimension: AptitudeDimension.artistic, statement: 'I enjoy coming up with original ideas or approaches rather than following a set template.'),
  AptitudeQuestion(id: 'artistic-2', dimension: AptitudeDimension.artistic, statement: 'I like work that gives me room for creative expression, not just standard procedure.'),
  AptitudeQuestion(id: 'artistic-3', dimension: AptitudeDimension.artistic, statement: 'I am energised by brainstorming new concepts, designs, or ways of communicating.'),

  AptitudeQuestion(id: 'social-1', dimension: AptitudeDimension.social, statement: 'I get real satisfaction from helping, teaching, or developing other people.'),
  AptitudeQuestion(id: 'social-2', dimension: AptitudeDimension.social, statement: "I enjoy roles centred on people's wellbeing and growth, not just their output."),
  AptitudeQuestion(id: 'social-3', dimension: AptitudeDimension.social, statement: 'I naturally take the time to listen and understand what others need.'),

  AptitudeQuestion(id: 'enterprising-1', dimension: AptitudeDimension.enterprising, statement: 'I enjoy persuading others and driving a plan or deal to a successful close.'),
  AptitudeQuestion(id: 'enterprising-2', dimension: AptitudeDimension.enterprising, statement: 'I am comfortable taking commercial or business risks to pursue an opportunity.'),
  AptitudeQuestion(id: 'enterprising-3', dimension: AptitudeDimension.enterprising, statement: 'I like leading initiatives and being accountable for their outcome.'),

  AptitudeQuestion(id: 'conventional-1', dimension: AptitudeDimension.conventional, statement: 'I value clear procedures and like ensuring things are done accurately and consistently.'),
  AptitudeQuestion(id: 'conventional-2', dimension: AptitudeDimension.conventional, statement: 'I am comfortable with detailed, structured, rules-based work.'),
  AptitudeQuestion(id: 'conventional-3', dimension: AptitudeDimension.conventional, statement: 'I prefer a well-organised system over a loosely defined one.'),

  // --- Work Style (Big-Five-inspired) ---
  AptitudeQuestion(id: 'openness-1', dimension: AptitudeDimension.openness, statement: 'I actively seek out new tools, ideas, or ways of working rather than sticking with the familiar.'),
  AptitudeQuestion(id: 'openness-2', dimension: AptitudeDimension.openness, statement: 'I am comfortable with ambiguity and enjoy exploring unfamiliar territory.'),
  AptitudeQuestion(id: 'openness-3', dimension: AptitudeDimension.openness, statement: 'I get restless doing the same thing the same way for too long.'),

  AptitudeQuestion(id: 'conscientiousness-1', dimension: AptitudeDimension.conscientiousness, statement: 'I reliably follow through on commitments, even without close supervision.'),
  AptitudeQuestion(id: 'conscientiousness-2', dimension: AptitudeDimension.conscientiousness, statement: 'I plan ahead and rarely let deadlines catch me by surprise.'),
  AptitudeQuestion(id: 'conscientiousness-3', dimension: AptitudeDimension.conscientiousness, statement: 'I am detail-oriented and take pride in getting things right.'),

  AptitudeQuestion(id: 'extraversion-1', dimension: AptitudeDimension.extraversion, statement: 'I feel energised, not drained, after a day full of meetings and interactions.'),
  AptitudeQuestion(id: 'extraversion-2', dimension: AptitudeDimension.extraversion, statement: 'I am comfortable being the one who speaks up first in a group.'),
  AptitudeQuestion(id: 'extraversion-3', dimension: AptitudeDimension.extraversion, statement: 'I prefer working with and around people over working alone for long stretches.'),

  AptitudeQuestion(id: 'agreeableness-1', dimension: AptitudeDimension.agreeableness, statement: "I go out of my way to keep a team's working relationships positive and cooperative."),
  AptitudeQuestion(id: 'agreeableness-2', dimension: AptitudeDimension.agreeableness, statement: "I try to see a disagreement from the other person's point of view before responding."),
  AptitudeQuestion(id: 'agreeableness-3', dimension: AptitudeDimension.agreeableness, statement: 'I would rather find common ground than win an argument.'),

  AptitudeQuestion(id: 'stability-1', dimension: AptitudeDimension.emotionalStability, statement: 'I stay calm and think clearly under pressure or when plans change suddenly.'),
  AptitudeQuestion(id: 'stability-2', dimension: AptitudeDimension.emotionalStability, statement: "Setbacks don't throw me off my stride for long."),
  AptitudeQuestion(id: 'stability-3', dimension: AptitudeDimension.emotionalStability, statement: 'I keep my composure even when things around me are stressful or chaotic.'),
];

/// Which aptitude dimensions each Career Paths vertical draws on most —
/// used to rank verticals by fit, not to editorialise about any one
/// officer. Each vertical draws on exactly 3 dimensions, deliberately mixed
/// across Interests and Work Style rather than all from one group.
const Map<String, List<AptitudeDimension>> kVerticalDimensions = {
  'Operations & Process Excellence': [AptitudeDimension.realistic, AptitudeDimension.conventional, AptitudeDimension.conscientiousness],
  'Supply Chain & Procurement': [AptitudeDimension.realistic, AptitudeDimension.conventional, AptitudeDimension.investigative],
  'Security, Risk & Crisis Management': [AptitudeDimension.conventional, AptitudeDimension.emotionalStability, AptitudeDimension.realistic],
  'Integrated Facilities Management': [AptitudeDimension.realistic, AptitudeDimension.conventional, AptitudeDimension.social],
  'Aviation, Maritime & Fleet Management': [AptitudeDimension.realistic, AptitudeDimension.conventional, AptitudeDimension.conscientiousness],
  'BFSI & Financial Crime Risk': [AptitudeDimension.investigative, AptitudeDimension.conventional, AptitudeDimension.conscientiousness],
  'Project & Program Management (PMO)': [AptitudeDimension.conventional, AptitudeDimension.conscientiousness, AptitudeDimension.enterprising],
  'Strategy, Consulting & Chief of Staff': [AptitudeDimension.investigative, AptitudeDimension.enterprising, AptitudeDimension.openness],
  'Business Development & Strategic Sales': [AptitudeDimension.enterprising, AptitudeDimension.extraversion, AptitudeDimension.social],
  'HR, Talent Management & L&D': [AptitudeDimension.social, AptitudeDimension.agreeableness, AptitudeDimension.extraversion],
  'Corporate Affairs, ESG & Public Policy': [AptitudeDimension.social, AptitudeDimension.enterprising, AptitudeDimension.agreeableness],
  'Defence PSUs, Offsets & GovTech': [AptitudeDimension.enterprising, AptitudeDimension.conventional, AptitudeDimension.agreeableness],
  'IT Infrastructure & Cybersecurity': [AptitudeDimension.investigative, AptitudeDimension.conventional, AptitudeDimension.realistic],
  'Tech Product & Data Operations': [AptitudeDimension.investigative, AptitudeDimension.openness, AptitudeDimension.conventional],
  'Manufacturing & Technical Systems': [AptitudeDimension.realistic, AptitudeDimension.investigative, AptitudeDimension.conscientiousness],
  'Aerospace, Drone & Defence Tech': [AptitudeDimension.realistic, AptitudeDimension.investigative, AptitudeDimension.openness],
};
