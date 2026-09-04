// Static supporting content for the Reading Programme — extracted
// directly from the source programme document, not AI-generated, so none
// of it needs the fabrication review the per-book deep-dive content does.

class ReadingSequencePhase {
  const ReadingSequencePhase(this.phase, this.items);
  final String phase;
  final String items;
}

class MilitaryCorporateMapping {
  const MilitaryCorporateMapping(this.military, this.corporate);
  final String military;
  final String corporate;
}

/// The doc's own minimum-viable 5-book set for a time-constrained officer.
const List<String> kFiveBookMinimum = [
  'The First 90 Days — Michael D. Watkins: the transition operating manual.',
  'Financial Intelligence — Berman, Knight & Case: business and financial literacy.',
  'What Got You Here Won’t Get You There — Marshall Goldsmith: behavioural adaptation.',
  'The Effective Executive — Peter F. Drucker: contribution, priorities and results.',
  'Good Strategy/Bad Strategy — Richard P. Rumelt: disciplined strategic thinking.',
];

const List<ReadingSequencePhase> kReadingSequence = [
  ReadingSequencePhase('Before transition', 'Working Identity; What Got You Here Won’t Get You There; The 7 Habits; How to Win Friends and Influence People; Turn the Ship Around!'),
  ReadingSequencePhase('Before joining / Week 1', 'The First 90 Days; Financial Intelligence; The Effective Executive; The Making of a Manager'),
  ReadingSequencePhase('Days 30–90', 'Crucial Conversations; Influence; Never Split the Difference; Radical Candor; Act Like a Leader, Think Like a Leader'),
  ReadingSequencePhase('Months 3–12', 'Good Strategy/Bad Strategy; Playing to Win; The Culture Map; Good to Great'),
  ReadingSequencePhase('Functional depth', 'The Goal for operations, supply chain, manufacturing and project roles; Multipliers for larger people-leadership roles'),
];

const List<MilitaryCorporateMapping> kMilitaryCorporateMap = [
  MilitaryCorporateMapping('Command authority → influence', 'Persuade peers, customers and seniors who do not report to you.'),
  MilitaryCorporateMapping('Mission activity → business outcome', 'Connect activity to revenue, margin, cash, customer value, productivity or risk.'),
  MilitaryCorporateMapping('Hierarchy → matrix', 'Expect cross-functional accountability and influence without direct authority.'),
  MilitaryCorporateMapping('Commander\'s intent → strategy', 'Understand where the company will play, how it will win and what capabilities it needs.'),
  MilitaryCorporateMapping('Operational success → commercial success', 'A well-executed activity is valuable only when it contributes to the business outcome.'),
  MilitaryCorporateMapping('Staff coordination → stakeholder management', 'Different functions have different KPIs, incentives and power bases.'),
  MilitaryCorporateMapping('Resource allocation → financial thinking', 'Understand the consequences of headcount, inventory, capital, pricing and working capital.'),
  MilitaryCorporateMapping('After-action review → feedback culture', 'Use continuous feedback, including upward feedback and self-correction.'),
];

const List<String> kReadingProgrammeCautions = [
  'Do not try to read all 20 before leaving service. The list is staged.',
  'Do not treat corporate practice as inherently superior to military practice. The goal is contextual adaptation.',
  'Do not memorise frameworks without understanding the business problem they are meant to solve.',
  'Several classics contain dated examples or debatable claims. Extract durable principles and retain critical judgement.',
  'Country-level culture frameworks are heuristics, not labels for individuals.',
  'Use influence and negotiation principles ethically.',
];
