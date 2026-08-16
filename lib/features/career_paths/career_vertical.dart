import '../../core/models/officer_profile.dart';

/// A functional vertical's career ladder: an ordered list of role titles
/// from the most junior rung to the most senior, plus which rung each
/// segment typically enters at (SSC enters junior, PMR mid-senior,
/// Superannuation senior/advisory — per the PRD's segment definitions).
class CareerVertical {
  const CareerVertical({
    required this.name,
    required this.ladder,
    required this.entryIndex,
  });

  final String name;
  final List<String> ladder;
  final Map<OfficerSegment, int> entryIndex;
}

const List<CareerVertical> kCareerVerticals = [
  CareerVertical(
    name: 'Security',
    ladder: [
      'Security Manager',
      'Senior Security Manager',
      'Head of Security',
      'VP / Chief Security Officer',
      'Security Advisor (Board Level)',
    ],
    entryIndex: {
      OfficerSegment.ssc: 0,
      OfficerSegment.pmr: 2,
      OfficerSegment.superannuation: 4,
    },
  ),
  CareerVertical(
    name: 'Administration',
    ladder: [
      'Administration Manager',
      'Senior Manager – Administration',
      'Head of Administration',
      'VP – Administration & Facilities',
      'Chief Administrative Officer',
    ],
    entryIndex: {
      OfficerSegment.ssc: 0,
      OfficerSegment.pmr: 2,
      OfficerSegment.superannuation: 4,
    },
  ),
  CareerVertical(
    name: 'Business Development',
    ladder: [
      'Business Development Manager',
      'Senior BD Manager',
      'Head of Business Development',
      'VP – Business Development',
      'Chief Business Officer',
    ],
    entryIndex: {
      OfficerSegment.ssc: 0,
      OfficerSegment.pmr: 2,
      OfficerSegment.superannuation: 4,
    },
  ),
  CareerVertical(
    name: 'Supply Chain',
    ladder: [
      'Supply Chain Manager',
      'Senior Manager – Supply Chain',
      'Head of Supply Chain',
      'VP – Supply Chain & Logistics',
      'Chief Supply Chain Officer',
    ],
    entryIndex: {
      OfficerSegment.ssc: 0,
      OfficerSegment.pmr: 2,
      OfficerSegment.superannuation: 4,
    },
  ),
  CareerVertical(
    name: 'Operations',
    ladder: [
      'Operations Manager',
      'Senior Operations Manager',
      'Head of Operations',
      'VP – Operations',
      'Chief Operating Officer',
    ],
    entryIndex: {
      OfficerSegment.ssc: 0,
      OfficerSegment.pmr: 2,
      OfficerSegment.superannuation: 4,
    },
  ),
  CareerVertical(
    name: 'HR',
    ladder: [
      'HR Manager',
      'Senior HR Manager',
      'Head of HR',
      'VP – Human Resources',
      'Chief Human Resources Officer',
    ],
    entryIndex: {
      OfficerSegment.ssc: 0,
      OfficerSegment.pmr: 2,
      OfficerSegment.superannuation: 4,
    },
  ),
  CareerVertical(
    name: 'Manufacturing / Technical',
    ladder: [
      'Production Manager',
      'Senior Manager – Manufacturing',
      'Head of Manufacturing',
      'VP – Manufacturing & Technical Operations',
      'Chief Technical Officer',
    ],
    entryIndex: {
      OfficerSegment.ssc: 0,
      OfficerSegment.pmr: 2,
      OfficerSegment.superannuation: 4,
    },
  ),
  CareerVertical(
    name: 'Project Management',
    ladder: [
      'Project Manager',
      'Senior Project Manager',
      'Head of Project Management (PMO)',
      'VP – Programs & Projects',
      'Chief Projects Officer',
    ],
    entryIndex: {
      OfficerSegment.ssc: 0,
      OfficerSegment.pmr: 2,
      OfficerSegment.superannuation: 4,
    },
  ),
  CareerVertical(
    name: 'Corporate Affairs & Governance',
    ladder: [
      'Manager – Corporate Affairs',
      'Senior Manager – Corporate Affairs',
      'Head of Corporate Affairs & Governance',
      'VP – Corporate Affairs',
      'Chief Governance Officer (Board Advisory)',
    ],
    entryIndex: {
      OfficerSegment.ssc: 0,
      OfficerSegment.pmr: 2,
      OfficerSegment.superannuation: 4,
    },
  ),
  CareerVertical(
    name: 'L&D',
    ladder: [
      'L&D Manager',
      'Senior Manager – L&D',
      'Head of Learning & Development',
      'VP – Talent & Capability Building',
      'Chief Learning Officer',
    ],
    entryIndex: {
      OfficerSegment.ssc: 0,
      OfficerSegment.pmr: 2,
      OfficerSegment.superannuation: 4,
    },
  ),
  CareerVertical(
    name: 'Hospitality / Institutional Management',
    ladder: [
      'Facility / Hospitality Manager',
      'Senior Manager – Institutional Services',
      'Head of Hospitality & Institutional Management',
      'VP – Hospitality & Guest Services',
      'Chief Institutional Services Officer',
    ],
    entryIndex: {
      OfficerSegment.ssc: 0,
      OfficerSegment.pmr: 2,
      OfficerSegment.superannuation: 4,
    },
  ),
  CareerVertical(
    name: 'IT / Cybersecurity',
    ladder: [
      'IT / Cybersecurity Manager',
      'Senior Manager – Cybersecurity',
      'Head of IT & Cybersecurity',
      'VP / CISO',
      'Chief Information Security Officer (Board Advisory)',
    ],
    entryIndex: {
      OfficerSegment.ssc: 0,
      OfficerSegment.pmr: 2,
      OfficerSegment.superannuation: 4,
    },
  ),
  CareerVertical(
    name: 'PSU / Government',
    ladder: [
      'Deputy Manager (PSU / Govt Undertaking)',
      'Manager – Government Liaison & PSU Affairs',
      'Deputy General Manager (PSU)',
      'General Manager / Director (PSU Board)',
      'Independent Director / Advisor (PSU Board)',
    ],
    entryIndex: {
      OfficerSegment.ssc: 0,
      OfficerSegment.pmr: 2,
      OfficerSegment.superannuation: 4,
    },
  ),
];
