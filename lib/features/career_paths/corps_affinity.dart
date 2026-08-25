import 'career_vertical.dart';

/// How an officer's Corps/Arm feeds into Vertical Fit ranking and Target
/// Role Strategy. Two mechanisms, both purely additive/corroborating or
/// fully substitutive — never a blended score:
///
/// - Most Corps/Arm entries get a **soft affinity badge**: the general 20
///   verticals remain the ranked universe, and matching entries just get a
///   "this also aligns with your Corps/Arm background" badge. Never changes
///   the fit score or ranking.
/// - A few Corps/Arm entries — medically- or legally-licensed ones — get a
///   **constrained universe**: their entire vertical universe is replaced,
///   not merged. AMC and the Navy/Air Force medical branches are fully
///   replaced by [kMedicalCareerVerticals] — a doctor's civilian
///   employability doesn't extend to the general 20. JAG (all three
///   services) gets a hybrid: its own 5 legal-practice verticals plus the 4
///   general verticals legal training genuinely bridges into, since law
///   (unlike medicine) isn't confined to one licensed practice.

const _medicalCorps = [
  'Army Medical Corps (AMC)',
  'Medical Branch (Navy)',
  'Medical Branch (Air Force)',
];

const _jagCorps = [
  "Judge Advocate General's Department (JAG)",
  "Judge Advocate General's Branch (Navy)",
  "Judge Advocate General's Branch (Air Force)",
];

const _jagAffiliatedGeneralVerticals = {
  'Corporate Governance',
  'Corporate Affairs, ESG & Public Policy',
  'Corporate Investigations',
  'Defence PSUs, Offsets & GovTech',
};

final List<CareerVertical> _jagUniverse = [
  ...kLegalCareerVerticals,
  ...kCareerVerticals.where((v) => _jagAffiliatedGeneralVerticals.contains(v.name)),
];

/// Corps/Arm name -> its replacement vertical universe. Absence from this
/// map means the officer isn't domain-constrained — see
/// [kCorpsSoftAffinity] instead.
final Map<String, List<CareerVertical>> kCorpsConstrainedUniverse = {
  for (final corps in _medicalCorps) corps: kMedicalCareerVerticals,
  for (final corps in _jagCorps) corps: _jagUniverse,
};

/// Corps/Arm name -> general-vertical names it corroborates with a badge.
/// Only consulted when the Corps/Arm has no entry in
/// [kCorpsConstrainedUniverse]. Intentionally not exhaustive — only
/// well-known, defensible functional associations are included; anything
/// not listed here simply gets no badge, never a guessed one.
const Map<String, List<String>> kCorpsSoftAffinity = {
  'Infantry': ['Security, Risk & Crisis Management', 'Corporate Investigations', 'Operations & Process Excellence'],
  'Armoured Corps': ['Manufacturing & Technical Systems', 'Operations & Process Excellence', 'Security, Risk & Crisis Management'],
  'Regiment of Artillery': ['Manufacturing & Technical Systems', 'Aerospace, Drone & Defence Tech'],
  'Corps of Army Air Defence': ['Aerospace, Drone & Defence Tech', 'IT Infrastructure & Cybersecurity'],
  'Corps of Engineers': ['Manufacturing & Technical Systems', 'Integrated Facilities Management', 'Project & Program Management (PMO)'],
  'Corps of Signals': ['IT Infrastructure & Cybersecurity', 'Tech Product & Data Operations', 'Intelligence & Vigilance'],
  'Army Aviation Corps': ['Aviation, Maritime & Fleet Management', 'Aerospace, Drone & Defence Tech'],
  'Mechanised Infantry': ['Manufacturing & Technical Systems', 'Operations & Process Excellence'],
  'Army Service Corps (ASC)': ['Supply Chain & Procurement', 'Operations & Process Excellence'],
  'Army Ordnance Corps (AOC)': ['Supply Chain & Procurement', 'Manufacturing & Technical Systems', 'Defence PSUs, Offsets & GovTech'],
  'Corps of Electronics & Mechanical Engineers (EME)': ['Manufacturing & Technical Systems', 'Aviation, Maritime & Fleet Management'],
  'Army Dental Corps (ADC)': [],
  'Military Nursing Service (MNS)': [],
  'Corps of Military Police (CMP)': ['Security, Risk & Crisis Management', 'Corporate Investigations'],
  'Military Intelligence': ['Intelligence & Vigilance', 'Corporate Investigations', 'BFSI & Financial Crime Risk'],
  'Intelligence Corps': ['Intelligence & Vigilance', 'Corporate Investigations'],
  'Army Education Corps (AEC)': ['HR, Talent Management & L&D'],
  'Army Postal Service (APS)': ['Supply Chain & Procurement', 'Operations & Process Excellence'],
  'Remount & Veterinary Corps (RVC)': ['Manufacturing & Technical Systems'],
  'Pioneer Corps': ['Manufacturing & Technical Systems', 'Integrated Facilities Management'],
  'Executive Branch (Seaman/Gunnery/Navigation)': ['Aviation, Maritime & Fleet Management', 'Security, Risk & Crisis Management'],
  'Executive Branch (Air Traffic Control/Observer)': ['Aviation, Maritime & Fleet Management', 'Aerospace, Drone & Defence Tech'],
  'Engineering Branch': ['Manufacturing & Technical Systems', 'Aviation, Maritime & Fleet Management'],
  'Electrical Branch': ['Manufacturing & Technical Systems', 'IT Infrastructure & Cybersecurity'],
  'Education Branch': ['HR, Talent Management & L&D'],
  'Logistics Branch': ['Supply Chain & Procurement', 'Operations & Process Excellence'],
  'Flying Branch': ['Aviation, Maritime & Fleet Management', 'Aerospace, Drone & Defence Tech'],
  'Technical Branch (Engineering)': ['Manufacturing & Technical Systems', 'Aerospace, Drone & Defence Tech'],
  'Administration Branch': ['Operations & Process Excellence', 'Integrated Facilities Management'],
  'Accounts Branch': ['BFSI & Financial Crime Risk', 'Operations & Process Excellence'],
  'Meteorology Branch': ['Aerospace, Drone & Defence Tech', 'Aviation, Maritime & Fleet Management'],
};

/// Realistic, India-context job titles used to search JSearch directly for
/// a domain-constrained officer (AMC, JAG) — replacing, not supplementing,
/// the CV-derived free-text query the Worker would otherwise ask Claude to
/// generate for Job Matches. The boundary itself must stay deterministic
/// and auditable, not AI-inferred — see `job_matches_http_service.dart`
/// and the Worker's `handleJobMatches`.
const List<String> kMedicalJobSearchTitles = [
  'Medical Officer',
  'Occupational Health Physician',
  'Corporate Medical Officer',
  'Medical Advisor',
  'Clinical Research Physician',
  'Hospital Administrator',
  'Public Health Physician',
];

const List<String> kLegalJobSearchTitles = [
  'Legal Counsel',
  'Compliance Officer',
  'Regulatory Affairs Manager',
  'Contract Manager',
  'Litigation Manager',
  'Corporate Governance Manager',
  'Arbitrator',
];

/// Lowercase title fragments used to keep JSearch results within the
/// officer's professional domain — a listing whose title contains none of
/// these is dropped before ranking, never shown as a "close enough"
/// adjacent role. Short and hand-reviewed, the same discipline as
/// [kCorpsSoftAffinity] — not derived or guessed.
const List<String> kMedicalJobTitleKeywords = [
  'medical', 'physician', 'clinical', 'health', 'hospital', 'doctor',
];

const List<String> kLegalJobTitleKeywords = [
  'legal', 'counsel', 'compliance', 'regulatory', 'litigation', 'arbitrat',
  'governance', 'contract', 'labour', 'labor',
];

/// The JSearch query to use in place of the CV-derived one, for a
/// domain-constrained Corps/Arm — null means the officer isn't constrained
/// and Job Matches should keep deriving the query from the CV as before.
String? domainConstrainedJobQuery(String? corpsOrArm) {
  if (corpsOrArm == null) return null;
  if (_medicalCorps.contains(corpsOrArm)) {
    return kMedicalJobSearchTitles.map((t) => '"$t"').join(' OR ');
  }
  if (_jagCorps.contains(corpsOrArm)) {
    return kLegalJobSearchTitles.map((t) => '"$t"').join(' OR ');
  }
  return null;
}

/// The title-keyword filter Job Matches should apply to JSearch results for
/// a domain-constrained Corps/Arm — null means no filtering (unconstrained
/// officers see exactly what they see today).
List<String>? domainConstrainedJobTitleKeywords(String? corpsOrArm) {
  if (corpsOrArm == null) return null;
  if (_medicalCorps.contains(corpsOrArm)) return kMedicalJobTitleKeywords;
  if (_jagCorps.contains(corpsOrArm)) return kLegalJobTitleKeywords;
  return null;
}

/// Every browsable vertical regardless of Corps/Arm — Career Paths uses
/// this so anyone can explore any ladder; the Corps/Arm constraint only
/// ever applies to ranking/recommendation, never to what's browsable.
List<CareerVertical> get kAllBrowsableVerticals =>
    [...kCareerVerticals, ...kMedicalCareerVerticals, ...kLegalCareerVerticals];

/// The vertical universe Vertical Fit / Target Role Strategy should rank
/// for this officer — the constrained list if their Corps/Arm has one,
/// otherwise the general 20.
List<CareerVertical> effectiveVerticalUniverse(String? corpsOrArm) {
  if (corpsOrArm == null) return kCareerVerticals;
  return kCorpsConstrainedUniverse[corpsOrArm] ?? kCareerVerticals;
}

bool isDomainConstrained(String? corpsOrArm) =>
    corpsOrArm != null && kCorpsConstrainedUniverse.containsKey(corpsOrArm);
