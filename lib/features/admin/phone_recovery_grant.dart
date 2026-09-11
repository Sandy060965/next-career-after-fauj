/// One admin-issued grant of temporary phone-OTP sign-in access for a
/// specific number — kept even after expiry/revocation, since the full
/// history of grants is also the usage signal for how often officers hit a
/// Google Sign-In problem, not just an access-control record.
class PhoneRecoveryGrant {
  const PhoneRecoveryGrant({
    required this.id,
    required this.mobileNumber,
    this.note,
    required this.grantedAt,
    required this.expiresAt,
    this.revokedAt,
  });

  final String id;
  final String mobileNumber;
  final String? note;
  final DateTime grantedAt;
  final DateTime expiresAt;
  final DateTime? revokedAt;

  bool get isActive => revokedAt == null && expiresAt.isAfter(DateTime.now());

  factory PhoneRecoveryGrant.fromJson(Map<String, dynamic> json) => PhoneRecoveryGrant(
        id: json['id'] as String,
        mobileNumber: json['mobileNumber'] as String,
        note: json['note'] as String?,
        grantedAt: DateTime.parse(json['grantedAt'] as String),
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        revokedAt: json['revokedAt'] == null ? null : DateTime.parse(json['revokedAt'] as String),
      );
}
