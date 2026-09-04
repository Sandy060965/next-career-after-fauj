import 'career_vertical.dart';

/// How an officer's Corps/Arm feeds into Vertical Fit ranking and Target
/// Role Strategy. Two mechanisms, both purely additive/corroborating or
/// fully substitutive — never a blended score:
///
/// - Most Corps/Arm entries get a **fit-tier badge** (Strong/Possible, from
///   `corps_vertical_fit_matrix.dart`): the general 20 verticals remain the
///   ranked universe, and matching entries just get a "this also aligns
///   with your Corps/Arm background" badge. Never changes the fit score or
///   ranking.
/// - A few Corps/Arm entries — medically- or legally-licensed ones — get a
///   **constrained universe**: their entire vertical universe is replaced,
///   not merged. AMC and the Navy/Air Force medical branches are fully
///   replaced by [kMedicalCareerVerticals] — a doctor's civilian
///   employability doesn't extend to the general 20. JAG (all three
///   services) gets a hybrid: its own 5 legal-practice verticals plus the 4
///   general verticals legal training genuinely bridges into, since law
///   (unlike medicine) isn't confined to one licensed practice.

/// The Corps/Arm/Branch entries whose civilian employability stays within
/// medicine — exported so `corps_vertical_fit_matrix.dart` can apply the
/// same hard gate rather than duplicating this list.
const kMedicalCorps = [
  'Army Medical Corps (AMC)',
  'Medical Branch (Navy)',
  'Medical Branch (Air Force)',
];

/// The Judge Advocate General entries across all three services — exported
/// for the same reason as [kMedicalCorps].
const kJagCorps = [
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
/// `corps_vertical_fit_matrix.dart` instead.
final Map<String, List<CareerVertical>> kCorpsConstrainedUniverse = {
  for (final corps in kMedicalCorps) corps: kMedicalCareerVerticals,
  for (final corps in kJagCorps) corps: _jagUniverse,
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
/// `corps_vertical_fit_matrix.dart` — not derived or guessed.
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
  if (kMedicalCorps.contains(corpsOrArm)) {
    return kMedicalJobSearchTitles.map((t) => '"$t"').join(' OR ');
  }
  if (kJagCorps.contains(corpsOrArm)) {
    return kLegalJobSearchTitles.map((t) => '"$t"').join(' OR ');
  }
  return null;
}

/// The title-keyword filter Job Matches should apply to JSearch results for
/// a domain-constrained Corps/Arm — null means no filtering (unconstrained
/// officers see exactly what they see today).
List<String>? domainConstrainedJobTitleKeywords(String? corpsOrArm) {
  if (corpsOrArm == null) return null;
  if (kMedicalCorps.contains(corpsOrArm)) return kMedicalJobTitleKeywords;
  if (kJagCorps.contains(corpsOrArm)) return kLegalJobTitleKeywords;
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
