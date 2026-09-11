class AllowedEmailSummary {
  const AllowedEmailSummary({required this.email, this.note, required this.addedAt});

  final String email;
  final String? note;
  final DateTime addedAt;

  factory AllowedEmailSummary.fromJson(Map<String, dynamic> json) => AllowedEmailSummary(
        email: json['email'] as String,
        note: json['note'] as String?,
        addedAt: DateTime.parse(json['addedAt'] as String),
      );
}
