/// One successful phone-OTP login, for the admin dashboard to spot an
/// officer's account being used from unexpectedly many different devices
/// or locations — a possible sign their credentials were shared, not proof
/// of it. Never independently verified beyond what Cloudflare reports for
/// that request.
class LoginEvent {
  const LoginEvent({
    required this.officerId,
    required this.mobileNumber,
    this.userAgent,
    this.country,
    this.city,
    required this.loggedInAt,
  });

  final String officerId;
  final String mobileNumber;
  final String? userAgent;
  final String? country;
  final String? city;
  final DateTime loggedInAt;

  /// A short, human-readable device label parsed from the user-agent —
  /// good enough to eyeball "does this look different from usual," not a
  /// precise device fingerprint.
  String get deviceLabel {
    final ua = userAgent;
    if (ua == null || ua.isEmpty) return 'Unknown device';

    final String os;
    if (ua.contains('iPhone') || ua.contains('iPad')) {
      os = 'iOS';
    } else if (ua.contains('Android')) {
      os = 'Android';
    } else if (ua.contains('Mac OS X')) {
      os = 'Mac';
    } else if (ua.contains('Windows')) {
      os = 'Windows';
    } else if (ua.contains('Linux')) {
      os = 'Linux';
    } else {
      os = 'Unknown OS';
    }

    final String browser;
    if (ua.contains('CriOS') || ua.contains('Chrome')) {
      browser = 'Chrome';
    } else if (ua.contains('EdgiOS') || ua.contains('Edg/')) {
      browser = 'Edge';
    } else if (ua.contains('Firefox')) {
      browser = 'Firefox';
    } else if (ua.contains('Safari')) {
      browser = 'Safari';
    } else {
      browser = 'Unknown browser';
    }
    return '$browser on $os';
  }

  String get locationLabel {
    if (city != null && city!.isNotEmpty && country != null && country!.isNotEmpty) {
      return '$city, $country';
    }
    return country ?? 'Unknown location';
  }

  factory LoginEvent.fromJson(Map<String, dynamic> json) => LoginEvent(
        officerId: json['officerId'] as String,
        mobileNumber: json['mobileNumber'] as String,
        userAgent: json['userAgent'] as String?,
        country: json['country'] as String?,
        city: json['city'] as String?,
        loggedInAt: DateTime.parse(json['loggedInAt'] as String),
      );
}
