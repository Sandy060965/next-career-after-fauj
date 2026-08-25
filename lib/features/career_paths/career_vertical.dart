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
  CareerVertical(
    name: 'Corporate Governance',
    category: 'Strategy, Commercial & People',
    levels: [
      CareerLevel(tier: 1, expMin: 10, expMax: 14, title: 'Manager – Corporate Governance'),
      CareerLevel(tier: 2, expMin: 15, expMax: 20, title: 'Senior Manager – Governance & Compliance'),
      CareerLevel(tier: 3, expMin: 21, expMax: 27, title: 'Head of Corporate Governance'),
      CareerLevel(tier: 4, expMin: 28, expMax: 34, title: 'Vice President – Governance, Risk & Compliance'),
      CareerLevel(tier: 5, expMin: 35, expMax: 42, title: 'Chief Governance Officer'),
    ],
    bridgeCertifications: ['Company Secretary (ICSI)', 'Certified Governance Professional'],
  ),
  CareerVertical(
    name: 'Intelligence & Vigilance',
    category: 'Operational & Risk',
    levels: [
      CareerLevel(tier: 1, expMin: 10, expMax: 14, title: 'Vigilance Officer'),
      CareerLevel(tier: 2, expMin: 15, expMax: 20, title: 'Senior Manager – Corporate Vigilance'),
      CareerLevel(tier: 3, expMin: 21, expMax: 27, title: 'Head of Vigilance & Internal Intelligence'),
      CareerLevel(tier: 4, expMin: 28, expMax: 34, title: 'Vice President – Corporate Security & Vigilance'),
      CareerLevel(tier: 5, expMin: 35, expMax: 42, title: 'Chief Vigilance Officer (CVO)'),
    ],
    bridgeCertifications: ['Certified Fraud Examiner (CFE)', 'Certificate in Corporate Vigilance'],
  ),
  CareerVertical(
    name: 'Corporate Investigations',
    category: 'Operational & Risk',
    levels: [
      CareerLevel(tier: 1, expMin: 10, expMax: 14, title: 'Corporate Investigator'),
      CareerLevel(tier: 2, expMin: 15, expMax: 20, title: 'Senior Investigator'),
      CareerLevel(tier: 3, expMin: 21, expMax: 27, title: 'Head of Corporate Investigations'),
      CareerLevel(tier: 4, expMin: 28, expMax: 34, title: 'Vice President – Investigations & Forensic Services'),
      CareerLevel(tier: 5, expMin: 35, expMax: 42, title: 'Chief Investigations Officer'),
    ],
    bridgeCertifications: ['Certified Fraud Examiner (CFE)', 'Certified Forensic Investigation Professional'],
  ),
  CareerVertical(
    name: 'Brand Protection & IPR',
    category: 'Operational & Risk',
    levels: [
      CareerLevel(tier: 1, expMin: 10, expMax: 14, title: 'Brand Protection Manager'),
      CareerLevel(tier: 2, expMin: 15, expMax: 20, title: 'Senior Manager – IPR & Anti-Counterfeiting'),
      CareerLevel(tier: 3, expMin: 21, expMax: 27, title: 'Head of Brand Protection & IPR Enforcement'),
      CareerLevel(tier: 4, expMin: 28, expMax: 34, title: 'Vice President – Brand Protection & Intellectual Property'),
      CareerLevel(tier: 5, expMin: 35, expMax: 42, title: 'Chief IP & Brand Protection Officer'),
    ],
    bridgeCertifications: ['Certified Fraud Examiner (CFE)', 'IP/Brand Protection fundamentals certificate'],
  ),
];

/// A dedicated career universe for medically-licensed officers (Army
/// Medical Corps and the Navy/Air Force medical branches) — not merged
/// into [kCareerVerticals]. A physician's civilian employability is
/// fundamentally different from a generalist officer's: it stays within
/// medicine, healthcare, occupational health, and clinical/scientific
/// services, never "translated" into generic corporate roles. See
/// `corps_affinity.dart` for how a Corps/Arm is wired to this list instead
/// of the general one.
const List<CareerVertical> kMedicalCareerVerticals = [
  CareerVertical(
    name: 'Clinical Practice & Hospital Administration',
    category: 'Medical & Healthcare',
    levels: [
      CareerLevel(tier: 1, expMin: 10, expMax: 14, title: 'Medical Officer'),
      CareerLevel(tier: 2, expMin: 15, expMax: 20, title: 'Consultant / Senior Medical Officer'),
      CareerLevel(tier: 3, expMin: 21, expMax: 27, title: 'Deputy Medical Superintendent'),
      CareerLevel(tier: 4, expMin: 28, expMax: 34, title: 'Medical Superintendent'),
      CareerLevel(tier: 5, expMin: 35, expMax: 42, title: 'Chief Medical Officer / Hospital Director'),
    ],
    bridgeCertifications: ['Fellowship in Hospital Administration', 'NABH-aligned healthcare quality certification'],
  ),
  CareerVertical(
    name: 'Occupational & Industrial Health',
    category: 'Medical & Healthcare',
    levels: [
      CareerLevel(tier: 1, expMin: 10, expMax: 14, title: 'Factory / Plant Medical Officer'),
      CareerLevel(tier: 2, expMin: 15, expMax: 20, title: 'Senior Occupational Health Physician'),
      CareerLevel(tier: 3, expMin: 21, expMax: 27, title: 'Occupational Health Manager'),
      CareerLevel(tier: 4, expMin: 28, expMax: 34, title: 'Regional Occupational Health Lead'),
      CareerLevel(tier: 5, expMin: 35, expMax: 42, title: 'Chief Medical Officer (Occupational Health)'),
    ],
    bridgeCertifications: ['Diploma in Industrial Health (DIH)'],
  ),
  CareerVertical(
    name: 'Corporate & Employee Health',
    category: 'Medical & Healthcare',
    levels: [
      CareerLevel(tier: 1, expMin: 10, expMax: 14, title: 'Corporate Medical Officer'),
      CareerLevel(tier: 2, expMin: 15, expMax: 20, title: 'Senior Corporate Physician'),
      CareerLevel(tier: 3, expMin: 21, expMax: 27, title: 'Employee Health Manager'),
      CareerLevel(tier: 4, expMin: 28, expMax: 34, title: 'Head of Employee Health & Wellness'),
      CareerLevel(tier: 5, expMin: 35, expMax: 42, title: 'Chief Medical Officer (Corporate)'),
    ],
    bridgeCertifications: ['Diploma in Industrial Health (DIH)', 'Certificate in Occupational Medicine'],
  ),
  CareerVertical(
    name: 'Pharmaceutical & Life Sciences Medicine',
    category: 'Medical & Healthcare',
    levels: [
      CareerLevel(tier: 1, expMin: 10, expMax: 14, title: 'Medical Advisor'),
      CareerLevel(tier: 2, expMin: 15, expMax: 20, title: 'Senior Medical Advisor / Clinical Research Physician'),
      CareerLevel(tier: 3, expMin: 21, expMax: 27, title: 'Medical Affairs Manager / Drug Safety Lead'),
      CareerLevel(tier: 4, expMin: 28, expMax: 34, title: 'Medical Affairs Lead / Therapy Area Lead'),
      CareerLevel(tier: 5, expMin: 35, expMax: 42, title: 'Medical Director'),
    ],
    bridgeCertifications: ['PG Diploma in Clinical Research'],
  ),
  CareerVertical(
    name: 'Health Insurance & Managed Care',
    category: 'Medical & Healthcare',
    levels: [
      CareerLevel(tier: 1, expMin: 10, expMax: 14, title: 'Medical Claims Officer'),
      CareerLevel(tier: 2, expMin: 15, expMax: 20, title: 'Senior Medical Reviewer'),
      CareerLevel(tier: 3, expMin: 21, expMax: 27, title: 'Medical Underwriting / Utilization Review Manager'),
      CareerLevel(tier: 4, expMin: 28, expMax: 34, title: 'Head of Medical Claims & Underwriting'),
      CareerLevel(tier: 5, expMin: 35, expMax: 42, title: 'Chief Medical Officer (Insurance)'),
    ],
    bridgeCertifications: ['Diploma in Healthcare Management'],
  ),
  CareerVertical(
    name: 'Digital Health / HealthTech',
    category: 'Medical & Healthcare',
    levels: [
      CareerLevel(tier: 1, expMin: 10, expMax: 14, title: 'Clinical Product Specialist'),
      CareerLevel(tier: 2, expMin: 15, expMax: 20, title: 'Medical Advisor (Digital Health)'),
      CareerLevel(tier: 3, expMin: 21, expMax: 27, title: 'Clinical Product Manager'),
      CareerLevel(tier: 4, expMin: 28, expMax: 34, title: 'Head of Clinical / Medical Product'),
      CareerLevel(tier: 5, expMin: 35, expMax: 42, title: 'Chief Medical Officer (HealthTech)'),
    ],
    bridgeCertifications: ['Certificate in Digital Health / Health Informatics'],
  ),
  CareerVertical(
    name: 'Public Health, Research & Medical Education',
    category: 'Medical & Healthcare',
    levels: [
      CareerLevel(tier: 1, expMin: 10, expMax: 14, title: 'Programme Medical Officer'),
      CareerLevel(tier: 2, expMin: 15, expMax: 20, title: 'Public Health Physician / Clinical Researcher'),
      CareerLevel(tier: 3, expMin: 21, expMax: 27, title: 'Senior Epidemiologist / Research Lead'),
      CareerLevel(tier: 4, expMin: 28, expMax: 34, title: 'Head of Public Health Programme'),
      CareerLevel(tier: 5, expMin: 35, expMax: 42, title: 'Director, Public Health / Research'),
    ],
    bridgeCertifications: ['Master of Public Health (MPH)'],
  ),
  CareerVertical(
    name: 'Specialized Environment Medicine',
    category: 'Medical & Healthcare',
    levels: [
      CareerLevel(tier: 1, expMin: 10, expMax: 14, title: 'Site / Ship / Aviation Medical Officer'),
      CareerLevel(tier: 2, expMin: 15, expMax: 20, title: 'Senior Medical Officer (Specialized Environment)'),
      CareerLevel(tier: 3, expMin: 21, expMax: 27, title: 'Regional Medical Lead'),
      CareerLevel(tier: 4, expMin: 28, expMax: 34, title: 'Head of Emergency & Specialized Medicine'),
      CareerLevel(tier: 5, expMin: 35, expMax: 42, title: 'Chief Medical Officer (Operations)'),
    ],
    bridgeCertifications: ['Diploma in Aviation Medicine (DAvMed)'],
  ),
  CareerVertical(
    name: 'Government / PSU / Institutional Healthcare',
    category: 'Medical & Healthcare',
    levels: [
      CareerLevel(tier: 1, expMin: 10, expMax: 14, title: 'Medical Officer (Institutional)'),
      CareerLevel(tier: 2, expMin: 15, expMax: 20, title: 'Senior Medical Officer'),
      CareerLevel(tier: 3, expMin: 21, expMax: 27, title: 'Chief Medical Officer (Unit)'),
      CareerLevel(tier: 4, expMin: 28, expMax: 34, title: 'Regional Medical Director'),
      CareerLevel(tier: 5, expMin: 35, expMax: 42, title: 'Director, Medical Services'),
    ],
    bridgeCertifications: ['Diploma in Hospital Administration'],
  ),
];

/// A small set of dedicated legal-practice verticals for JAG officers (all
/// three services) — unlike medicine, legal training bridges naturally into
/// several of the general 20 verticals too (Corporate Governance, Corporate
/// Affairs & Public Policy, Corporate Investigations, Defence PSUs &
/// GovTech), so JAG's constrained universe is this list *plus* those four,
/// not a full replacement the way [kMedicalCareerVerticals] is. See
/// `corps_affinity.dart`.
const List<CareerVertical> kLegalCareerVerticals = [
  CareerVertical(
    name: 'Corporate Legal & In-House Counsel',
    category: 'Legal & Governance',
    levels: [
      CareerLevel(tier: 1, expMin: 10, expMax: 14, title: 'Legal Manager'),
      CareerLevel(tier: 2, expMin: 15, expMax: 20, title: 'Senior Legal Counsel'),
      CareerLevel(tier: 3, expMin: 21, expMax: 27, title: 'Associate General Counsel'),
      CareerLevel(tier: 4, expMin: 28, expMax: 34, title: 'Deputy General Counsel'),
      CareerLevel(tier: 5, expMin: 35, expMax: 42, title: 'General Counsel / Chief Legal Officer'),
    ],
    bridgeCertifications: ['PG Diploma in Corporate Law'],
  ),
  CareerVertical(
    name: 'Litigation & Dispute Management',
    category: 'Legal & Governance',
    levels: [
      CareerLevel(tier: 1, expMin: 10, expMax: 14, title: 'Litigation Manager'),
      CareerLevel(tier: 2, expMin: 15, expMax: 20, title: 'Senior Litigation Counsel'),
      CareerLevel(tier: 3, expMin: 21, expMax: 27, title: 'Head of Litigation'),
      CareerLevel(tier: 4, expMin: 28, expMax: 34, title: 'Vice President – Legal (Disputes)'),
      CareerLevel(tier: 5, expMin: 35, expMax: 42, title: 'General Counsel (Disputes)'),
    ],
    bridgeCertifications: ['LLM (Dispute Resolution)'],
  ),
  CareerVertical(
    name: 'Arbitration & Alternative Dispute Resolution',
    category: 'Legal & Governance',
    levels: [
      CareerLevel(tier: 1, expMin: 10, expMax: 14, title: 'Arbitration Associate'),
      CareerLevel(tier: 2, expMin: 15, expMax: 20, title: 'Empanelled Arbitrator / Mediator'),
      CareerLevel(tier: 3, expMin: 21, expMax: 27, title: 'Senior Arbitrator'),
      CareerLevel(tier: 4, expMin: 28, expMax: 34, title: 'Head of ADR Practice'),
      CareerLevel(tier: 5, expMin: 35, expMax: 42, title: 'Chief Arbitrator / Institutional Head'),
    ],
    bridgeCertifications: ['Chartered Institute of Arbitrators (CIArb) certification'],
  ),
  CareerVertical(
    name: 'Regulatory & Compliance Affairs',
    category: 'Legal & Governance',
    levels: [
      CareerLevel(tier: 1, expMin: 10, expMax: 14, title: 'Compliance Officer'),
      CareerLevel(tier: 2, expMin: 15, expMax: 20, title: 'Senior Compliance Manager'),
      CareerLevel(tier: 3, expMin: 21, expMax: 27, title: 'Head of Regulatory Affairs'),
      CareerLevel(tier: 4, expMin: 28, expMax: 34, title: 'Vice President – Compliance'),
      CareerLevel(tier: 5, expMin: 35, expMax: 42, title: 'Chief Compliance Officer'),
    ],
    bridgeCertifications: ['Certified Compliance Professional'],
  ),
  CareerVertical(
    name: 'Labour & Employee Relations Law',
    category: 'Legal & Governance',
    levels: [
      CareerLevel(tier: 1, expMin: 10, expMax: 14, title: 'Employee Relations Manager'),
      CareerLevel(tier: 2, expMin: 15, expMax: 20, title: 'Senior ER / IR Manager'),
      CareerLevel(tier: 3, expMin: 21, expMax: 27, title: 'Head of Employee Relations'),
      CareerLevel(tier: 4, expMin: 28, expMax: 34, title: 'Vice President – HR (ER & Compliance)'),
      CareerLevel(tier: 5, expMin: 35, expMax: 42, title: 'Chief HR Officer (ER track)'),
    ],
    bridgeCertifications: ['PG Diploma in Labour Law'],
  ),
];
