import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/models/officer_profile.dart';
import 'package:next_career_after_fauj/core/services/profile_repository.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/job_matches/india_cities.dart';
import 'package:next_career_after_fauj/features/job_matches/job_match.dart';
import 'package:next_career_after_fauj/features/job_matches/job_matches_screen.dart';
import 'package:provider/provider.dart';

Future<List<JobMatch>> _stubAnalyzer({
  required String cvText,
  CityTier? cityTier,
  Uint8List? cvPdfBytes,
}) async {
  return const [
    JobMatch(
      title: 'Head of Security',
      company: 'Tata Steel',
      portal: JobPortal.naukri,
      applyUrl: 'https://www.naukri.com/example-job',
      fitReason: 'Strong match on security leadership.',
      location: 'Mumbai',
      ctcRange: '₹28-35 LPA',
      isTopCompany: true,
    ),
    JobMatch(
      title: 'Security Manager',
      company: 'Regional Corp',
      portal: JobPortal.indeed,
      applyUrl: 'https://in.indeed.com/example-job',
      fitReason: 'Good fit for operations background.',
      location: 'Pune',
    ),
  ];
}

Widget _appUnderTest({required OfficerProfile profile}) {
  final repository = ProfileRepository()..saveProfile(profile);
  return ChangeNotifierProvider<ProfileRepository>.value(
    value: repository,
    child: MaterialApp(
      theme: AppTheme.light,
      home: const JobMatchesScreen(analyzeJobMatches: _stubAnalyzer),
    ),
  );
}

OfficerProfile _testProfile() => OfficerProfile(
      rank: 'Lt Col',
      fullName: 'Lt Col A Verma',
      dateOfBirth: DateTime(1978, 5, 10),
      workExperienceYears: 18,
      workExperienceMonths: 2,
      releaseStatus: ReleaseStatus.tentative,
      releaseDate: DateTime(2027, 6, 30),
      service: OfficerService.army,
      mobileNumber: '9876543210',
      email: 'a.verma@example.com',
      segment: OfficerSegment.pmr,
      cvFileName: 'resume.pdf',
      cvExtractedText: 'Sample CV text',
    );

void main() {
  testWidgets('lists job matches with fit reason, CTC, and top-company badge',
      (tester) async {
    await tester.pumpWidget(_appUnderTest(profile: _testProfile()));
    await tester.pumpAndSettle();

    expect(find.text('Head of Security'), findsOneWidget);
    expect(find.text('Tata Steel'), findsOneWidget);
    expect(find.text('Strong match on security leadership.'), findsOneWidget);
    expect(find.text('CTC: ₹28-35 LPA'), findsOneWidget);
    expect(find.byKey(const Key('topCompanyBadge')), findsOneWidget);

    expect(find.text('Security Manager'), findsOneWidget);
    expect(find.text('CTC: Not disclosed'), findsOneWidget);
  });

  testWidgets('city tier filter is present with All/Tier 1/Tier 2 options', (tester) async {
    await tester.pumpWidget(_appUnderTest(profile: _testProfile()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('cityTierFilter')), findsOneWidget);
    expect(find.text('All cities'), findsOneWidget);
    expect(find.text('Tier 1'), findsOneWidget);
    expect(find.text('Tier 2'), findsOneWidget);
  });
}
