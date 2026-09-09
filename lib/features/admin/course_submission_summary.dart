class CourseSubmissionSummary {
  const CourseSubmissionSummary({
    required this.id,
    this.mobileNumber,
    required this.courseName,
    this.courseDescription,
    this.civilianEquivalent,
    this.civilianDescription,
    required this.verified,
    this.sourceNote,
    required this.status,
    required this.submittedAt,
    this.reviewedAt,
  });

  final String id;
  final String? mobileNumber;
  final String courseName;
  final String? courseDescription;
  final String? civilianEquivalent;
  final String? civilianDescription;
  final bool verified;
  final String? sourceNote;
  final String status;
  final DateTime submittedAt;
  final DateTime? reviewedAt;

  bool get isPending => status == 'pending';

  factory CourseSubmissionSummary.fromJson(Map<String, dynamic> json) => CourseSubmissionSummary(
        id: json['id'] as String,
        mobileNumber: json['mobileNumber'] as String?,
        courseName: json['courseName'] as String,
        courseDescription: json['courseDescription'] as String?,
        civilianEquivalent: json['civilianEquivalent'] as String?,
        civilianDescription: json['civilianDescription'] as String?,
        verified: json['verified'] as bool? ?? false,
        sourceNote: json['sourceNote'] as String?,
        status: json['status'] as String,
        submittedAt: DateTime.parse(json['submittedAt'] as String),
        reviewedAt:
            json['reviewedAt'] == null ? null : DateTime.parse(json['reviewedAt'] as String),
      );
}
