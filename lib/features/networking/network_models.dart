enum CallFrequency { weekly, fortnightly, monthly }

extension CallFrequencyLabel on CallFrequency {
  String get label => switch (this) {
        CallFrequency.weekly => 'Every week',
        CallFrequency.fortnightly => 'Every fortnight',
        CallFrequency.monthly => 'Every month',
      };

  String get wireValue => name;

  static CallFrequency fromWire(String value) =>
      CallFrequency.values.firstWhere((f) => f.name == value, orElse: () => CallFrequency.weekly);
}

/// The 30/60-minute options for how long each mentoring session might run.
const List<int> kSessionMinuteOptions = [30, 60];

/// A pledge to mentor other officers once the pledging officer has joined
/// their civilian job — pure data capture, no in-app browsing or request
/// flow. Every field here was explicitly provided by the officer
/// themselves — nothing inferred or synced automatically from their
/// profile. There is deliberately no eligibility gate (e.g. a minimum
/// tenure) because officers typically lose access to this app once they
/// join their new employer, so the pledge has to be captured in advance.
class MentorPledge {
  const MentorPledge({
    required this.officerId,
    required this.displayName,
    required this.email,
    required this.callFrequency,
    required this.sessionMinutes,
    this.vertical,
    this.city,
    this.currentCompany,
    this.joiningDate,
  });

  final String officerId;
  final String displayName;
  final String email;
  final String? vertical;
  final String? city;

  /// The company the officer has joined or accepted an offer from, if known
  /// at the time of the pledge.
  final String? currentCompany;

  /// Tentative or confirmed date the officer joins/joined their civilian
  /// role — optional, since many officers pledge before they have one.
  final DateTime? joiningDate;

  final CallFrequency callFrequency;

  /// 30 or 60 — see [kSessionMinuteOptions].
  final int sessionMinutes;

  factory MentorPledge.fromJson(Map<String, dynamic> json) => MentorPledge(
        officerId: json['officerId'] as String,
        displayName: json['displayName'] as String,
        email: json['email'] as String,
        vertical: json['vertical'] as String?,
        city: json['city'] as String?,
        currentCompany: json['currentCompany'] as String?,
        joiningDate:
            json['joiningDate'] == null ? null : DateTime.parse(json['joiningDate'] as String),
        callFrequency: CallFrequencyLabel.fromWire(json['callFrequency'] as String),
        sessionMinutes: json['sessionMinutes'] as int,
      );
}
