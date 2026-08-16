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
    required this.service,
    required this.mobileNumber,
    required this.email,
    required this.segment,
    required this.cvFileName,
  });

  final String rank;
  final String fullName;
  final DateTime dateOfBirth;
  final int workExperienceYears;
  final int workExperienceMonths;
  final OfficerService service;
  final String mobileNumber;
  final String email;
  final OfficerSegment segment;
  final String cvFileName;
}
