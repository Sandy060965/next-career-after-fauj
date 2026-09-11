import 'dart:typed_data';

// Deliberately no age ranges in these labels — retirement age isn't uniform
// across services or even across ranks within a service (e.g. Army Colonel
// retires at 54 vs Navy/Air Force Colonel-equivalent at 57), so a single
// number here would be wrong for a large share of officers. Each label
// instead describes what actually distinguishes the category, which holds
// regardless of the officer's specific due age.
enum OfficerSegment {
  ssc(
    'SSC',
    'Short Service Commission — an initial short-tenure commission, released by 14 years of '
        'service at the latest.',
  ),
  pmr(
    'PMR',
    "Premature Retirement — you're retiring voluntarily, ahead of your due retirement age as "
        'per your rank and service.',
  ),
  superannuation(
    'Superannuation',
    "Superannuation — you're retiring on reaching the due/mandatory retirement age as per your "
        'rank and service.',
  );

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
    this.corpsOrArm,
    this.photoFileName,
    this.photoBytes,
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

  /// Optional — a real, unclassified organisational affiliation (e.g.
  /// "Corps of Signals"), not an ACR/service-record field. Null means the
  /// officer skipped it; Vertical Fit and Career Paths fall back to the
  /// general vertical universe with no Corps/Arm-based signal.
  final String? corpsOrArm;

  /// Optional headshot for CV templates that show one — never collected
  /// during onboarding, only offered from the CV templates gallery, and
  /// entirely skippable. Same split as [cvFileName]/[cvPdfBytes]: the name
  /// travels in the JSON profile blob, the bytes are persisted separately.
  final String? photoFileName;
  final Uint8List? photoBytes;

  /// Returns a copy with just the CV fields replaced — for attaching or
  /// replacing a CV after onboarding without re-collecting every other
  /// already-saved field (rank, name, DOB, etc.).
  OfficerProfile withUpdatedCv({
    required String cvFileName,
    String? cvExtractedText,
    Uint8List? cvPdfBytes,
  }) {
    return OfficerProfile(
      rank: rank,
      fullName: fullName,
      dateOfBirth: dateOfBirth,
      workExperienceYears: workExperienceYears,
      workExperienceMonths: workExperienceMonths,
      releaseStatus: releaseStatus,
      releaseDate: releaseDate,
      service: service,
      mobileNumber: mobileNumber,
      email: email,
      segment: segment,
      cvFileName: cvFileName,
      cvExtractedText: cvExtractedText,
      cvPdfBytes: cvPdfBytes,
      corpsOrArm: corpsOrArm,
      photoFileName: photoFileName,
      photoBytes: photoBytes,
    );
  }

  /// Returns a copy with just the photo fields replaced — pass both null to
  /// remove a previously-added photo.
  OfficerProfile withUpdatedPhoto({String? photoFileName, Uint8List? photoBytes}) {
    return OfficerProfile(
      rank: rank,
      fullName: fullName,
      dateOfBirth: dateOfBirth,
      workExperienceYears: workExperienceYears,
      workExperienceMonths: workExperienceMonths,
      releaseStatus: releaseStatus,
      releaseDate: releaseDate,
      service: service,
      mobileNumber: mobileNumber,
      email: email,
      segment: segment,
      cvFileName: cvFileName,
      cvExtractedText: cvExtractedText,
      cvPdfBytes: cvPdfBytes,
      corpsOrArm: corpsOrArm,
      photoFileName: photoFileName,
      photoBytes: photoBytes,
    );
  }

  /// Excludes [cvPdfBytes]/[photoBytes] deliberately — both are persisted
  /// separately as files rather than inlined into a JSON blob.
  Map<String, dynamic> toJson() => {
        'rank': rank,
        'fullName': fullName,
        'dateOfBirth': dateOfBirth.toIso8601String(),
        'workExperienceYears': workExperienceYears,
        'workExperienceMonths': workExperienceMonths,
        'releaseStatus': releaseStatus.name,
        'releaseDate': releaseDate.toIso8601String(),
        'service': service.name,
        'mobileNumber': mobileNumber,
        'email': email,
        'segment': segment.name,
        'cvFileName': cvFileName,
        'cvExtractedText': cvExtractedText,
        'corpsOrArm': corpsOrArm,
        'photoFileName': photoFileName,
      };

  factory OfficerProfile.fromJson(
    Map<String, dynamic> json, {
    Uint8List? cvPdfBytes,
    Uint8List? photoBytes,
  }) {
    return OfficerProfile(
      rank: json['rank'] as String,
      fullName: json['fullName'] as String,
      dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
      workExperienceYears: json['workExperienceYears'] as int,
      workExperienceMonths: json['workExperienceMonths'] as int,
      releaseStatus: ReleaseStatus.values.byName(json['releaseStatus'] as String),
      releaseDate: DateTime.parse(json['releaseDate'] as String),
      service: OfficerService.values.byName(json['service'] as String),
      mobileNumber: json['mobileNumber'] as String,
      email: json['email'] as String,
      segment: OfficerSegment.values.byName(json['segment'] as String),
      cvFileName: json['cvFileName'] as String,
      cvExtractedText: json['cvExtractedText'] as String?,
      cvPdfBytes: cvPdfBytes,
      corpsOrArm: json['corpsOrArm'] as String?,
      // Added after OfficerProfile was already shipping — absent in an
      // older cached profile, which should still parse rather than throw.
      photoFileName: json['photoFileName'] as String?,
      photoBytes: photoBytes,
    );
  }
}
