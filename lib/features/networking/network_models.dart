enum NetworkChannel { inTransition, transitioned }

extension NetworkChannelLabel on NetworkChannel {
  String get label => switch (this) {
        NetworkChannel.inTransition => 'Officer in transition',
        NetworkChannel.transitioned => 'Already transitioned',
      };

  String get wireValue => switch (this) {
        NetworkChannel.inTransition => 'inTransition',
        NetworkChannel.transitioned => 'transitioned',
      };

  static NetworkChannel fromWire(String value) =>
      value == 'transitioned' ? NetworkChannel.transitioned : NetworkChannel.inTransition;
}

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

const kWeekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// One fixed weekly (or fortnightly/monthly) 30-minute call slot — always
/// exactly 30 minutes; only the day, time, and how often it recurs vary.
class CallSlot {
  const CallSlot({required this.dayOfWeek, required this.startTime});

  final String dayOfWeek;

  /// 24-hour "HH:mm", e.g. "19:00".
  final String startTime;

  Map<String, dynamic> toJson() => {'dayOfWeek': dayOfWeek, 'startTime': startTime};

  factory CallSlot.fromJson(Map<String, dynamic> json) => CallSlot(
        dayOfWeek: json['dayOfWeek'] as String,
        startTime: json['startTime'] as String,
      );
}

/// The officer's own directory listing, if they've opted in. Every field
/// here was explicitly provided by the officer at opt-in — nothing
/// inferred or synced automatically from their profile.
class NetworkContact {
  const NetworkContact({
    required this.officerId,
    required this.channel,
    required this.displayName,
    required this.callFrequency,
    required this.callSlots,
    required this.offersReferrals,
    this.email,
    this.vertical,
    this.city,
    this.currentCompany,
    this.slotAvailability,
  });

  final String officerId;
  final NetworkChannel channel;
  final String displayName;

  /// Only ever populated when this is the officer's OWN listing (from
  /// /network/my-listing) — never present on another officer's listing
  /// from /network/browse, which is the entire point of routing contact
  /// through accepted requests instead of a raw directory.
  final String? email;

  final String? vertical;
  final String? city;
  final String? currentCompany;
  final CallFrequency callFrequency;
  final List<CallSlot> callSlots;
  final bool offersReferrals;

  /// One bool per [callSlots] entry — true if free for the current period.
  /// Only populated on browse results, not on the officer's own listing.
  final List<bool>? slotAvailability;

  factory NetworkContact.fromJson(Map<String, dynamic> json) => NetworkContact(
        officerId: json['officerId'] as String,
        channel: NetworkChannelLabel.fromWire(json['channel'] as String),
        displayName: json['displayName'] as String,
        email: json['email'] as String?,
        vertical: json['vertical'] as String?,
        city: json['city'] as String?,
        currentCompany: json['currentCompany'] as String?,
        callFrequency: CallFrequencyLabel.fromWire(json['callFrequency'] as String),
        callSlots: (json['callSlots'] as List)
            .map((e) => CallSlot.fromJson(e as Map<String, dynamic>))
            .toList(),
        offersReferrals: json['offersReferrals'] as bool,
        slotAvailability: (json['slotAvailability'] as List?)?.map((e) => e as bool).toList(),
      );
}

enum AskType { call, referral }

extension AskTypeLabel on AskType {
  String get label => switch (this) {
        AskType.call => 'Call',
        AskType.referral => 'Referral',
      };

  String get wireValue => name;

  static AskType fromWire(String value) =>
      value == 'referral' ? AskType.referral : AskType.call;
}

enum ConnectionRequestStatus { pending, accepted, declined, expired }

extension ConnectionRequestStatusLabel on ConnectionRequestStatus {
  String get label => switch (this) {
        ConnectionRequestStatus.pending => 'Pending',
        ConnectionRequestStatus.accepted => 'Accepted',
        ConnectionRequestStatus.declined => 'Declined',
        ConnectionRequestStatus.expired => 'Expired',
      };

  static ConnectionRequestStatus fromWire(String value) => ConnectionRequestStatus.values
      .firstWhere((s) => s.name == value, orElse: () => ConnectionRequestStatus.pending);
}

/// An incoming request a volunteer needs to accept or decline.
class IncomingRequest {
  const IncomingRequest({
    required this.id,
    required this.requesterDisplayName,
    required this.askType,
    required this.createdAt,
    this.requesterNote,
    this.slotIndex,
  });

  final String id;
  final String requesterDisplayName;
  final String? requesterNote;
  final AskType askType;
  final int? slotIndex;
  final DateTime createdAt;

  factory IncomingRequest.fromJson(Map<String, dynamic> json) => IncomingRequest(
        id: json['id'] as String,
        requesterDisplayName: json['requesterDisplayName'] as String,
        requesterNote: json['requesterNote'] as String?,
        askType: AskTypeLabel.fromWire(json['askType'] as String),
        slotIndex: json['slotIndex'] as int?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

/// An outgoing request the officer themselves sent — [volunteerEmail] is
/// only ever non-null once the volunteer has accepted.
class OutgoingRequest {
  const OutgoingRequest({
    required this.id,
    required this.volunteerDisplayName,
    required this.askType,
    required this.status,
    required this.createdAt,
    this.volunteerEmail,
  });

  final String id;
  final String volunteerDisplayName;
  final String? volunteerEmail;
  final AskType askType;
  final ConnectionRequestStatus status;
  final DateTime createdAt;

  factory OutgoingRequest.fromJson(Map<String, dynamic> json) => OutgoingRequest(
        id: json['id'] as String,
        volunteerDisplayName: json['volunteerDisplayName'] as String,
        volunteerEmail: json['volunteerEmail'] as String?,
        askType: AskTypeLabel.fromWire(json['askType'] as String),
        status: ConnectionRequestStatusLabel.fromWire(json['status'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
