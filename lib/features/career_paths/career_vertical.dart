/// One rung of a vertical's career ladder, anchored to a typical years-of-
/// service band rather than a coarse SSC/PMR/Superannuation segment — the
/// officer's own [OfficerProfile.workExperienceYears] picks the rung
/// directly, so entry level is precise rather than one of three buckets.
/// Bands and titles are indicative/typical, not a promotion guarantee.
class CareerLevel {
  const CareerLevel({
    required this.tier,
    required this.expMin,
    required this.expMax,
    required this.title,
  });

  final int tier;
  final int expMin;
  final int expMax;
  final String title;
}

/// A functional vertical's 5-tier career ladder plus general certifications
/// that help bridge into it. [bridgeCertifications] are broad, real,
/// well-known professional certifications relevant to the whole vertical —
/// distinct from Gap Roadmap's certifications, which are grounded in one
/// specific JD.
class CareerVertical {
  const CareerVertical({
    required this.name,
    required this.category,
    required this.levels,
    this.bridgeCertifications = const [],
  });

  final String name;
  final String category;
  final List<CareerLevel> levels;
  final List<String> bridgeCertifications;

  /// The rung matching the given years of experience — clamped to the
  /// first tier below [CareerLevel.expMin] and the last tier above the
  /// final [CareerLevel.expMax], rather than returning nothing.
  CareerLevel levelForExperience(int years) {
    for (final level in levels) {
      if (years <= level.expMax) return level;
    }
    return levels.last;
  }
}

const List<CareerVertical> kCareerVerticals = [
  CareerVertical(
    name: 'Operations & Process Excellence',
    category: 'Operational & Risk',
    levels: [
      CareerLevel(tier: 1, expMin: 10, expMax: 14, title: 'Operations Manager'),
      CareerLevel(tier: 2, expMin: 15, expMax: 20, title: 'Senior Operations Manager'),
      CareerLevel(tier: 3, expMin: 21, expMax: 27, title: 'Head of Operations'),
      CareerLevel(tier: 4, expMin: 28, expMax: 34, title: 'Vice President – Operations'),
      CareerLevel(tier: 5, expMin: 35, expMax: 42, title: 'Chief Operating Officer (COO)'),
    ],
    bridgeCertifications: ['Six Sigma Green/Black Belt', 'PMP'],
  ),
  CareerVertical(
    name: 'Supply Chain & Procurement',
    category: 'Operational & Risk',
    levels: [
      CareerLevel(tier: 1, expMin: 10, expMax: 14, title: 'Supply Chain Manager'),
      CareerLevel(tier: 2, expMin: 15, expMax: 20, title: 'Senior Manager – Supply Chain'),
      CareerLevel(tier: 3, expMin: 21, expMax: 27, title: 'Head of Supply Chain'),
      CareerLevel(tier: 4, expMin: 28, expMax: 34, title: 'Vice President – Supply Chain & Logistics'),
      CareerLevel(tier: 5, expMin: 35, expMax: 42, title: 'Chief Supply Chain Officer (CSCO)'),
    ],
    bridgeCertifications: ['CSCP (APICS)', 'CPSM'],
  ),
  CareerVertical(
    name: 'Security, Risk & Crisis Management',
    category: 'Operational & Risk',
    levels: [
      CareerLevel(tier: 1, expMin: 10, expMax: 14, title: 'Security Manager'),
      CareerLevel(tier: 2, expMin: 15, expMax: 20, title: 'Regional Security Manager'),
      CareerLevel(tier: 3, expMin: 21, expMax: 27, title: 'Head of Corporate Security'),
      CareerLevel(tier: 4, expMin: 28, expMax: 34, title: 'Vice President – Corporate Security & Resilience'),
      CareerLevel(tier: 5, expMin: 35, expMax: 42, title: 'Chief Security Officer (CSO)'),
    ],
    bridgeCertifications: ['CPP (ASIS)', 'NEBOSH', 'Business Continuity Institute (BCI) certification'],
  ),
  CareerVertical(
    name: 'Integrated Facilities Management',
    category: 'Operational & Risk',
    levels: [
      CareerLevel(tier: 1, expMin: 10, expMax: 14, title: 'Facilities Manager'),
      CareerLevel(tier: 2, expMin: 15, expMax: 20, title: 'Senior Facilities Manager'),
      CareerLevel(tier: 3, expMin: 21, expMax: 27, title: 'Head of Real Estate & Workplace'),
      CareerLevel(
        tier: 4,
        expMin: 28,
        expMax: 34,
        title: 'Vice President – Real Estate, Infrastructure & Corporate Services',
      ),
      CareerLevel(tier: 5, expMin: 35, expMax: 42, title: 'President – Corporate Infrastructure'),
    ],
    bridgeCertifications: ['IFMA CFM', 'RICS'],
  ),
  CareerVertical(
    name: 'Aviation, Maritime & Fleet Management',
    category: 'Operational & Risk',
    levels: [
      CareerLevel(tier: 1, expMin: 10, expMax: 14, title: 'Airport / Port Operations Manager'),
      CareerLevel(tier: 2, expMin: 15, expMax: 20, title: 'Senior Manager – Fleet & Ground Operations'),
      CareerLevel(tier: 3, expMin: 21, expMax: 27, title: 'Head of Aviation / Maritime Operations'),
      CareerLevel(tier: 4, expMin: 28, expMax: 34, title: 'Vice President – Aviation & Maritime Operations'),
      CareerLevel(tier: 5, expMin: 35, expMax: 42, title: 'Director – Global Fleet & Logistics'),
    ],
    bridgeCertifications: ['IATA Airport Operations certification', 'Certificate in Maritime Operations'],
  ),
  CareerVertical(
    name: 'BFSI & Financial Crime Risk',
    category: 'Operational & Risk',
    levels: [
      CareerLevel(tier: 1, expMin: 10, expMax: 14, title: 'AML / KYC Operations Manager'),
      CareerLevel(tier: 2, expMin: 15, expMax: 20, title: 'Senior Manager – Financial Crime Risk'),
      CareerLevel(tier: 3, expMin: 21, expMax: 27, title: 'Head of Financial Crime Operations'),
      CareerLevel(tier: 4, expMin: 28, expMax: 34, title: 'Vice President – Enterprise Risk Management'),
      CareerLevel(tier: 5, expMin: 35, expMax: 42, title: 'Chief Risk Officer (CRO)'),
    ],
    bridgeCertifications: ['CAMS (Certified Anti-Money Laundering Specialist)', 'FRM (Financial Risk Manager)'],
  ),
  CareerVertical(
    name: 'Project & Program Management (PMO)',
    category: 'Strategy, Commercial & People',
    levels: [
      CareerLevel(tier: 1, expMin: 10, expMax: 14, title: 'Project Manager'),
      CareerLevel(tier: 2, expMin: 15, expMax: 20, title: 'Senior Program Manager'),
      CareerLevel(tier: 3, expMin: 21, expMax: 27, title: 'Head of PMO'),
      CareerLevel(tier: 4, expMin: 28, expMax: 34, title: 'Vice President – Program Management'),
      CareerLevel(tier: 5, expMin: 35, expMax: 42, title: 'Chief Transformation Officer'),
    ],
    bridgeCertifications: ['PMP', 'PRINCE2', 'Certified Scrum Master'],
  ),
  CareerVertical(
    name: 'Strategy, Consulting & Chief of Staff',
    category: 'Strategy, Commercial & People',
    levels: [
      CareerLevel(tier: 1, expMin: 10, expMax: 14, title: 'Strategy Associate'),
      CareerLevel(tier: 2, expMin: 15, expMax: 20, title: 'Senior Strategy Manager / Chief of Staff to BU Head'),
      CareerLevel(tier: 3, expMin: 21, expMax: 27, title: 'Chief of Staff to CEO / Director – Corporate Strategy'),
      CareerLevel(tier: 4, expMin: 28, expMax: 34, title: 'Vice President – Corporate Strategy'),
      CareerLevel(tier: 5, expMin: 35, expMax: 42, title: 'Senior Partner / Independent Director'),
    ],
    bridgeCertifications: ['MBA / PGDM (Strategy)', 'Certified Management Consultant (CMC)'],
  ),
  CareerVertical(
    name: 'Business Development & Strategic Sales',
    category: 'Strategy, Commercial & People',
    levels: [
      CareerLevel(tier: 1, expMin: 10, expMax: 14, title: 'Key Account Manager'),
      CareerLevel(tier: 2, expMin: 15, expMax: 20, title: 'Senior BD Manager'),
      CareerLevel(tier: 3, expMin: 21, expMax: 27, title: 'Head of Business Development'),
      CareerLevel(tier: 4, expMin: 28, expMax: 34, title: 'Vice President – Strategic Growth'),
      CareerLevel(tier: 5, expMin: 35, expMax: 42, title: 'Chief Commercial Officer (CCO)'),
    ],
    bridgeCertifications: ['Certified Sales Professional', 'Strategic Account Management (SAMA)'],
  ),
  CareerVertical(
    name: 'HR, Talent Management & L&D',
    category: 'Strategy, Commercial & People',
    levels: [
      CareerLevel(tier: 1, expMin: 10, expMax: 14, title: 'HR Business Partner (HRBP)'),
      CareerLevel(tier: 2, expMin: 15, expMax: 20, title: 'Senior HRBP / Head of L&D'),
      CareerLevel(tier: 3, expMin: 21, expMax: 27, title: 'Head of HR / Director – Talent Management'),
      CareerLevel(tier: 4, expMin: 28, expMax: 34, title: 'Vice President – Human Resources'),
      CareerLevel(tier: 5, expMin: 35, expMax: 42, title: 'Chief Human Resources Officer (CHRO)'),
    ],
    bridgeCertifications: ['SHRM-CP', 'CIPD'],
  ),
  CareerVertical(
    name: 'Corporate Affairs, ESG & Public Policy',
    category: 'Strategy, Commercial & People',
    levels: [
      CareerLevel(tier: 1, expMin: 10, expMax: 14, title: 'Manager – Corporate Affairs'),
      CareerLevel(tier: 2, expMin: 15, expMax: 20, title: 'Senior Manager – Corporate Affairs'),
      CareerLevel(tier: 3, expMin: 21, expMax: 27, title: 'Head of Corporate Affairs & Policy'),
      CareerLevel(tier: 4, expMin: 28, expMax: 34, title: 'Vice President – Corporate Affairs & ESG'),
      CareerLevel(tier: 5, expMin: 35, expMax: 42, title: 'Chief Corporate Affairs Officer'),
    ],
    bridgeCertifications: ['GRI Certified Sustainability Professional', 'Certificate in ESG (CFA Institute)'],
  ),
  CareerVertical(
    name: 'Defence PSUs, Offsets & GovTech',
    category: 'Strategy, Commercial & People',
    levels: [
      CareerLevel(tier: 1, expMin: 10, expMax: 14, title: 'Deputy Manager (PSU)'),
      CareerLevel(tier: 2, expMin: 15, expMax: 20, title: 'Manager – Government Liaison & PSU Affairs'),
      CareerLevel(tier: 3, expMin: 21, expMax: 27, title: 'Deputy General Manager (PSU)'),
      CareerLevel(tier: 4, expMin: 28, expMax: 34, title: 'General Manager / Director (PSU Board)'),
      CareerLevel(tier: 5, expMin: 35, expMax: 42, title: 'Independent Director / Advisor (PSU Board)'),
    ],
    bridgeCertifications: ['Certificate in Public Procurement', 'Defence Offset Management certification'],
  ),
  CareerVertical(
    name: 'IT Infrastructure & Cybersecurity',
    category: 'Technical & Engineering',
    levels: [
      CareerLevel(tier: 1, expMin: 10, expMax: 14, title: 'IT Operations Manager'),
      CareerLevel(tier: 2, expMin: 15, expMax: 20, title: 'Senior InfoSec Manager'),
      CareerLevel(tier: 3, expMin: 21, expMax: 27, title: 'Head of IT Infrastructure / Deputy CISO'),
      CareerLevel(tier: 4, expMin: 28, expMax: 34, title: 'Vice President – Technology Operations'),
      CareerLevel(tier: 5, expMin: 35, expMax: 42, title: 'Chief Information Security Officer (CISO)'),
    ],
    bridgeCertifications: ['CISSP', 'CISM', 'ITIL'],
  ),
  CareerVertical(
    name: 'Tech Product & Data Operations',
    category: 'Technical & Engineering',
    levels: [
      CareerLevel(tier: 1, expMin: 10, expMax: 14, title: 'Technical Program Manager (TPM)'),
      CareerLevel(tier: 2, expMin: 15, expMax: 20, title: 'Senior Product / Data Operations Manager'),
      CareerLevel(tier: 3, expMin: 21, expMax: 27, title: 'Head of Product & Data Operations'),
      CareerLevel(tier: 4, expMin: 28, expMax: 34, title: 'Vice President – Product & Technology'),
      CareerLevel(tier: 5, expMin: 35, expMax: 42, title: 'Chief Product Officer (CPO)'),
    ],
    bridgeCertifications: ['Certified Scrum Product Owner', 'Google Data Analytics Certificate'],
  ),
  CareerVertical(
    name: 'Manufacturing & Technical Systems',
    category: 'Technical & Engineering',
    levels: [
      CareerLevel(tier: 1, expMin: 10, expMax: 14, title: 'Production Manager'),
      CareerLevel(tier: 2, expMin: 15, expMax: 20, title: 'Senior Manager – Manufacturing'),
      CareerLevel(tier: 3, expMin: 21, expMax: 27, title: 'Head of Manufacturing'),
      CareerLevel(tier: 4, expMin: 28, expMax: 34, title: 'Vice President – Manufacturing & Technical Operations'),
      CareerLevel(tier: 5, expMin: 35, expMax: 42, title: 'Chief Technical Officer (CTO)'),
    ],
    bridgeCertifications: ['Six Sigma Black Belt', 'Certified Quality Engineer (ASQ)'],
  ),
  CareerVertical(
    name: 'Aerospace, Drone & Defence Tech',
    category: 'Technical & Engineering',
    levels: [
      CareerLevel(tier: 1, expMin: 10, expMax: 14, title: 'UAV Operations Lead'),
      CareerLevel(tier: 2, expMin: 15, expMax: 20, title: 'Technical Operations Head'),
      CareerLevel(tier: 3, expMin: 21, expMax: 27, title: 'Head of Aerospace / Drone Operations'),
      CareerLevel(tier: 4, expMin: 28, expMax: 34, title: 'Vice President – Aerospace & Defence Programs'),
      CareerLevel(tier: 5, expMin: 35, expMax: 42, title: 'Managing Director – Defence Division'),
    ],
    bridgeCertifications: ['DGCA Remote Pilot Certificate', 'Systems Engineering certification (INCOSE)'],
  ),
];
