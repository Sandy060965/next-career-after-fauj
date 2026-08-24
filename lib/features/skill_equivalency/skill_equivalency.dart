/// A military course, institution, or appointment mapped to its civilian
/// corporate equivalent. Fixed, curated content — every entry is either a
/// well-known, real defence training institution, or a role/responsibility
/// description rather than a guessed specialist course title, so nothing
/// here is invented.
class SkillEquivalency {
  const SkillEquivalency({
    required this.militaryTerm,
    required this.civilianEquivalent,
    required this.description,
  });

  final String militaryTerm;
  final String civilianEquivalent;
  final String description;
}

const List<SkillEquivalency> kSkillEquivalencies = [
  SkillEquivalency(
    militaryTerm: 'Defence Services Staff College (DSSC), Wellington',
    civilianEquivalent: 'Strategic Management & Cross-Functional Leadership',
    description:
        'The tri-service Staff Course is broadly comparable to an executive strategy '
        'programme — planning, joint operations, and cross-functional coordination at '
        'a scale similar to senior management roles.',
  ),
  SkillEquivalency(
    militaryTerm: 'National Defence College (NDC), New Delhi',
    civilianEquivalent: 'National/Corporate Strategy & Board-Level Advisory',
    description:
        'A senior-most strategic studies programme, comparable to the kind of '
        'national and organisational strategy work expected at board-advisory level.',
  ),
  SkillEquivalency(
    militaryTerm: 'Higher Command Course',
    civilianEquivalent: 'Advanced Executive Leadership (General Manager / VP level)',
    description:
        'Prepares officers to lead large, complex organisations — the closest civilian '
        'equivalent is executive leadership development for GM/VP-level general management.',
  ),
  SkillEquivalency(
    militaryTerm: 'Higher Defence Management Course, College of Defence Management (CDM)',
    civilianEquivalent: 'Organisational Strategy & Resource Management',
    description:
        'Covers management theory, resource optimisation, and organisational '
        'behaviour — directly transferable to corporate strategy and operations roles.',
  ),
  SkillEquivalency(
    militaryTerm: 'Command of a unit (Battalion / Regiment / Squadron / Ship)',
    civilianEquivalent: 'General Management / P&L & Operations Leadership',
    description:
        'End-to-end accountability for people, resources, discipline, and outcomes at '
        'unit scale maps directly to running a business unit or large operating team.',
  ),
  SkillEquivalency(
    militaryTerm: 'Instructional or Directing Staff appointment at a training establishment',
    civilianEquivalent: 'Learning & Development / Corporate Training Leadership',
    description:
        'Designing and delivering structured training programmes to adult learners is '
        'the core of a civilian L&D or corporate training role.',
  ),
  SkillEquivalency(
    militaryTerm: 'Logistics, Supply, or Maintenance appointment (EME / AOC / ASC / '
        'Naval Logistics / IAF Maintenance)',
    civilianEquivalent: 'Supply Chain & Operations Management',
    description:
        'Managing inventory, procurement, fleet/equipment readiness, and distribution '
        'under operational constraints is directly comparable to civilian supply chain '
        'and operations roles.',
  ),
  SkillEquivalency(
    militaryTerm: 'Corps of Engineers project or works appointment',
    civilianEquivalent: 'Infrastructure & Project Management',
    description:
        'Planning and executing construction, infrastructure, or works projects to '
        'deadline and budget maps to civilian project and infrastructure management.',
  ),
  SkillEquivalency(
    militaryTerm: 'Signals, Communications, or IT appointment',
    civilianEquivalent: 'IT Infrastructure & Telecom Systems Management',
    description:
        'Running communications networks and systems under operational demands is '
        'directly relevant to civilian IT infrastructure and telecom operations roles.',
  ),
  SkillEquivalency(
    militaryTerm: 'Adjutant or Administration appointment',
    civilianEquivalent: 'HR & Administration Management',
    description:
        'Personnel administration, discipline, welfare, and unit records management is '
        'close to civilian HR operations and administration leadership.',
  ),
  SkillEquivalency(
    militaryTerm: 'Intelligence or Security appointment',
    civilianEquivalent: 'Corporate Security, Risk & Investigations',
    description:
        'Threat assessment, information verification, and security planning transfer '
        'directly to corporate security, risk, and investigations roles.',
  ),
  SkillEquivalency(
    militaryTerm: 'Aide-de-Camp or Personal Staff Officer to senior leadership',
    civilianEquivalent: 'Chief of Staff / Executive Assistant to a CXO',
    description:
        'Coordinating a senior leader\'s priorities, communications, and schedule '
        'across a large organisation is close to a Chief of Staff or senior EA role.',
  ),
];
