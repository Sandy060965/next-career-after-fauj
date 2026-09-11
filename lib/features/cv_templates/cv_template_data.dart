import 'dart:typed_data';

import '../../core/services/profile_repository.dart';
import '../cv_builder/cv_builder_intake.dart';

/// Everything a template needs to render a populated CV — assembled from
/// the officer's own [OfficerProfile] and [CvBuilderIntake], never from the
/// AI-flattened [BuiltCv] text (which can't be reliably sliced back into
/// sections). A missing/empty field just means that section is omitted
/// when rendering — never fabricated.
class CvTemplateData {
  const CvTemplateData({
    required this.fullName,
    required this.rank,
    required this.serviceLabel,
    this.corpsOrArm,
    this.mobileNumber = '',
    this.email = '',
    this.photoBytes,
    this.summary = '',
    this.skills = const [],
    this.workExperience = const [],
    this.education = const [],
    this.certifications = const [],
    this.courses = const [],
    this.honoursAwards = const [],
  });

  final String fullName;
  final String rank;
  final String serviceLabel;
  final String? corpsOrArm;
  final String mobileNumber;
  final String email;
  final Uint8List? photoBytes;
  final String summary;
  final List<String> skills;
  final List<WorkExperienceEntry> workExperience;
  final List<EducationEntry> education;
  final List<CertificationEntry> certifications;
  final List<CourseEntry> courses;
  final List<AwardEntry> honoursAwards;

  /// "Col A K Sharma, Veteran" — the header line every template leads with.
  /// "Veteran" (not "Retired") since Short Service Commission officers are
  /// never formally "retired" but are still veterans.
  String get titleLine {
    final nameLine = [rank, fullName].where((s) => s.trim().isNotEmpty).join(' ');
    return nameLine.isEmpty ? '' : '$nameLine, Veteran';
  }

  /// Two capitals for a photo-less avatar placeholder, e.g. "AS" for
  /// "A K Sharma" — first letter of the first and last word.
  String get initials {
    final words = fullName.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return (words.first.substring(0, 1) + words.last.substring(0, 1)).toUpperCase();
  }

  factory CvTemplateData.fromRepository(ProfileRepository repo) {
    final profile = repo.profile;
    final intake = repo.lastCvBuilderIntake;
    final skillsList = (intake?.skills ?? '')
        .split(RegExp(r'[,\n]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return CvTemplateData(
      fullName: profile?.fullName ?? '',
      rank: profile?.rank ?? '',
      serviceLabel: profile?.service.label ?? '',
      corpsOrArm: profile?.corpsOrArm,
      mobileNumber: profile?.mobileNumber ?? '',
      email: profile?.email ?? '',
      photoBytes: profile?.photoBytes,
      summary: intake?.summary ?? '',
      skills: skillsList,
      workExperience: intake?.workExperience ?? const [],
      education: intake?.education ?? const [],
      certifications: intake?.certifications ?? const [],
      courses: intake?.courses ?? const [],
      honoursAwards: intake?.honoursAwards ?? const [],
    );
  }
}
