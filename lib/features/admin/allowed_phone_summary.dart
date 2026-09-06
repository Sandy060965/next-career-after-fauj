class AllowedPhoneSummary {
  const AllowedPhoneSummary({required this.mobileNumber, this.note, required this.addedAt});

  final String mobileNumber;
  final String? note;
  final DateTime addedAt;

  factory AllowedPhoneSummary.fromJson(Map<String, dynamic> json) => AllowedPhoneSummary(
        mobileNumber: json['mobileNumber'] as String,
        note: json['note'] as String?,
        addedAt: DateTime.parse(json['addedAt'] as String),
      );
}
