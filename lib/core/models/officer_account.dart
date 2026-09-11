enum EntitlementTier { free, pass, annual }

extension EntitlementTierLabel on EntitlementTier {
  String get label => switch (this) {
        EntitlementTier.free => 'Free',
        EntitlementTier.pass => 'Transition Pass',
        EntitlementTier.annual => 'Annual',
      };
}

EntitlementTier _tierFromWire(String value) => switch (value) {
      'pass' => EntitlementTier.pass,
      'annual' => EntitlementTier.annual,
      _ => EntitlementTier.free,
    };

/// The officer's server-side account — identity and entitlement, kept
/// separate from [OfficerProfile] (which is the officer's own career data).
/// Never fabricated client-side: entitlement always comes from the backend.
///
/// Exactly one of [mobileNumber]/[email] is guaranteed non-null — which one
/// depends on how this officer signed in (phone-OTP vs. Google Sign-In), not
/// on which account is "real"; both are equally valid identities server-side.
class OfficerAccount {
  const OfficerAccount({
    required this.id,
    this.mobileNumber,
    this.email,
    required this.entitlementTier,
    required this.entitlementExpiresAt,
  });

  final String id;
  final String? mobileNumber;
  final String? email;
  final EntitlementTier entitlementTier;
  final DateTime? entitlementExpiresAt;

  factory OfficerAccount.fromJson(Map<String, dynamic> json) => OfficerAccount(
        id: json['id'] as String,
        mobileNumber: json['mobileNumber'] as String?,
        email: json['email'] as String?,
        entitlementTier: _tierFromWire(json['entitlementTier'] as String),
        entitlementExpiresAt: json['entitlementExpiresAt'] == null
            ? null
            : DateTime.parse(json['entitlementExpiresAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'mobileNumber': mobileNumber,
        'email': email,
        'entitlementTier': entitlementTier.name,
        'entitlementExpiresAt': entitlementExpiresAt?.toIso8601String(),
      };
}
