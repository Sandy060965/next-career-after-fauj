import 'dart:typed_data';

enum OfficerSegment {
  ssc('SSC', 'Short Service Commission (31–39 yrs)'),
  pmr('PMR', 'Premature Retirement (40–53 yrs)'),
  superannuation('Superannuation', 'Superannuation (54–60 yrs)');

  const OfficerSegment(this.shortLabel, this.fullLabel);

  final String shortLabel;
  final String fullLabel;
}

enum OfficerService {
  army('Army'),
  navy('Navy'),
  airForce('Air Force');

  const OfficerService(this.label);

  final String label;
}

enum ReleaseStatus {
  tentative('Tentative release date from service'),
  alreadyReleased('Already released');

  const ReleaseStatus(this.label);

  final String label;
}

/// Data captured during onboarding. Intake is limited to an officer-authored
/// CV upload — never an ACR or formal service record, and never a
/// unit-identifying field.
class OfficerProfile {
  const OfficerProfile({
    required this.rank,
    required this.fullName,
    required this.dateOfBirth,
    required this.workExperienceYears,
    required this.workExperienceMonths,
    required this.releaseStatus,
    required this.releaseDate,
    required this.service,
    required this.mobileNumber,
    required this.email,
    required this.segment,
    required this.cvFileName,
    this.cvExtractedText,
    this.cvPdfBytes,
  });

  final String rank;
  final String fullName;
  final DateTime dateOfBirth;
  final int workExperienceYears;
  final int workExperienceMonths;
  final ReleaseStatus releaseStatus;
  final DateTime releaseDate;
  final OfficerService service;
  final String mobileNumber;
  final String email;
  final OfficerSegment segment;
  final String cvFileName;

  /// Plain text extracted from the uploaded .docx CV, if that's what was
  /// uploaded and extraction succeeded. Mutually exclusive with
  /// [cvPdfBytes] — a CV is either a Word doc (extracted client-side) or a
  /// PDF (sent as-is; Claude reads PDFs natively). Null if extraction
  /// failed or hasn't happened, in which case only [cvFileName] is known.
  final String? cvExtractedText;

  /// Raw bytes of the uploaded PDF CV, if that's what was uploaded.
  final Uint8List? cvPdfBytes;
}
