enum ApplicationStatus { saved, applied, interviewing, offered, rejected, withdrawn }

extension ApplicationStatusLabel on ApplicationStatus {
  String get label => switch (this) {
        ApplicationStatus.saved => 'Saved',
        ApplicationStatus.applied => 'Applied',
        ApplicationStatus.interviewing => 'Interviewing',
        ApplicationStatus.offered => 'Offered',
        ApplicationStatus.rejected => 'Rejected',
        ApplicationStatus.withdrawn => 'Withdrawn',
      };
}

/// A single application the officer is tracking through their own job
/// search — entered and updated entirely by the officer, never generated.
/// [source] is a free-text note (e.g. "Job Matches", "LinkedIn", a
/// referral's name) rather than a fixed enum, since how an officer found a
/// role varies too much to constrain to a fixed list.
class JobApplication {
  const JobApplication({
    required this.id,
    required this.companyName,
    required this.roleTitle,
    required this.status,
    required this.createdAt,
    this.source,
    this.appliedDate,
    this.nextActionDate,
    this.nextActionNote,
    this.notes,
  });

  final String id;
  final String companyName;
  final String roleTitle;
  final ApplicationStatus status;
  final DateTime createdAt;
  final String? source;
  final DateTime? appliedDate;
  final DateTime? nextActionDate;
  final String? nextActionNote;
  final String? notes;

  JobApplication copyWith({
    String? companyName,
    String? roleTitle,
    ApplicationStatus? status,
    String? source,
    DateTime? appliedDate,
    bool clearAppliedDate = false,
    DateTime? nextActionDate,
    bool clearNextActionDate = false,
    String? nextActionNote,
    bool clearNextActionNote = false,
    String? notes,
    bool clearNotes = false,
  }) {
    return JobApplication(
      id: id,
      companyName: companyName ?? this.companyName,
      roleTitle: roleTitle ?? this.roleTitle,
      status: status ?? this.status,
      createdAt: createdAt,
      source: source ?? this.source,
      appliedDate: clearAppliedDate ? null : (appliedDate ?? this.appliedDate),
      nextActionDate: clearNextActionDate ? null : (nextActionDate ?? this.nextActionDate),
      nextActionNote: clearNextActionNote ? null : (nextActionNote ?? this.nextActionNote),
      notes: clearNotes ? null : (notes ?? this.notes),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'companyName': companyName,
        'roleTitle': roleTitle,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'source': source,
        'appliedDate': appliedDate?.toIso8601String(),
        'nextActionDate': nextActionDate?.toIso8601String(),
        'nextActionNote': nextActionNote,
        'notes': notes,
      };

  factory JobApplication.fromJson(Map<String, dynamic> json) => JobApplication(
        id: json['id'] as String,
        companyName: json['companyName'] as String,
        roleTitle: json['roleTitle'] as String,
        status: ApplicationStatus.values.byName(json['status'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        source: json['source'] as String?,
        appliedDate:
            json['appliedDate'] == null ? null : DateTime.parse(json['appliedDate'] as String),
        nextActionDate: json['nextActionDate'] == null
            ? null
            : DateTime.parse(json['nextActionDate'] as String),
        nextActionNote: json['nextActionNote'] as String?,
        notes: json['notes'] as String?,
      );
}
