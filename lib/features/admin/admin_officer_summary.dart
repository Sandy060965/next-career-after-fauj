/// One officer's signup + onboarding-progress snapshot, as seen by the
/// admin dashboard. Progress fields are self-reported by the officer's own
/// app session the last time it synced — honest-client data, not
/// independently verified, good enough to see who's using the app and
/// where people stall, not a source of truth for anything else.
class AdminOfficerSummary {
  const AdminOfficerSummary({
    required this.id,
    this.mobileNumber,
    this.email,
    required this.createdAt,
    required this.entitlementTier,
    this.rank,
    this.fullName,
    this.service,
    this.segment,
    this.readinessScore,
    required this.readinessDimensionsCompleted,
    required this.readinessDimensionsTotal,
    required this.cvUploaded,
    required this.civilianizedCvDone,
    required this.builtCvDone,
    required this.jdMatchDone,
    required this.financialPlanDone,
    required this.targetRoleStrategyDone,
    required this.applicationsCount,
    this.progressUpdatedAt,
  });

  final String id;
  final String? mobileNumber;
  final String? email;
  final DateTime createdAt;
  final String entitlementTier;

  final String? rank;
  final String? fullName;
  final String? service;
  final String? segment;
  final int? readinessScore;
  final int readinessDimensionsCompleted;
  final int readinessDimensionsTotal;
  final bool cvUploaded;
  final bool civilianizedCvDone;
  final bool builtCvDone;
  final bool jdMatchDone;
  final bool financialPlanDone;
  final bool targetRoleStrategyDone;
  final int applicationsCount;
  final DateTime? progressUpdatedAt;

  /// True once the officer's app has synced at least one progress snapshot
  /// — i.e. they've actually opened the app past sign-up, not just verified
  /// their phone number.
  bool get hasOpenedApp => progressUpdatedAt != null;

  factory AdminOfficerSummary.fromJson(Map<String, dynamic> json) => AdminOfficerSummary(
        id: json['id'] as String,
        mobileNumber: json['mobileNumber'] as String?,
        email: json['email'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        entitlementTier: json['entitlementTier'] as String,
        rank: json['rank'] as String?,
        fullName: json['fullName'] as String?,
        service: json['service'] as String?,
        segment: json['segment'] as String?,
        readinessScore: json['readinessScore'] as int?,
        readinessDimensionsCompleted: json['readinessDimensionsCompleted'] as int? ?? 0,
        readinessDimensionsTotal: json['readinessDimensionsTotal'] as int? ?? 0,
        cvUploaded: json['cvUploaded'] as bool? ?? false,
        civilianizedCvDone: json['civilianizedCvDone'] as bool? ?? false,
        builtCvDone: json['builtCvDone'] as bool? ?? false,
        jdMatchDone: json['jdMatchDone'] as bool? ?? false,
        financialPlanDone: json['financialPlanDone'] as bool? ?? false,
        targetRoleStrategyDone: json['targetRoleStrategyDone'] as bool? ?? false,
        applicationsCount: json['applicationsCount'] as int? ?? 0,
        progressUpdatedAt: json['progressUpdatedAt'] == null
            ? null
            : DateTime.parse(json['progressUpdatedAt'] as String),
      );
}
