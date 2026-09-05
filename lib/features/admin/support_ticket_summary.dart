class SupportTicketSummary {
  const SupportTicketSummary({
    required this.id,
    this.officerId,
    this.mobileNumber,
    required this.message,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
  });

  final String id;
  final String? officerId;
  final String? mobileNumber;
  final String message;
  final String status;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  bool get isResolved => status == 'resolved';

  factory SupportTicketSummary.fromJson(Map<String, dynamic> json) => SupportTicketSummary(
        id: json['id'] as String,
        officerId: json['officerId'] as String?,
        mobileNumber: json['mobileNumber'] as String?,
        message: json['message'] as String,
        status: json['status'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        resolvedAt: json['resolvedAt'] == null ? null : DateTime.parse(json['resolvedAt'] as String),
      );
}
