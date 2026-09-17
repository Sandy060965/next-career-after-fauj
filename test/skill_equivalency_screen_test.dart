import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/core/models/officer_profile.dart';
import 'package:next_career_after_fauj/core/services/profile_repository.dart';
import 'package:next_career_after_fauj/core/theme/app_theme.dart';
import 'package:next_career_after_fauj/features/skill_equivalency/skill_equivalency.dart';
import 'package:next_career_after_fauj/features/skill_equivalency/skill_equivalency_screen.dart';
import 'package:provider/provider.dart';

Widget _wrap(ProfileRepository repository) {
  return ChangeNotifierProvider<ProfileRepository>.value(
    value: repository,
    child: MaterialApp(theme: AppTheme.light, home: const SkillEquivalencyScreen()),
  );
}

final _profileWithCv = OfficerProfile(
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
  cvExtractedText: 'Completed the Higher Command Course in 2021.',
);

void main() {
  testWidgets('shows curated entries by default, none expanded', (tester) async {
    await tester.pumpWidget(_wrap(ProfileRepository()));
    await tester.pumpAndSettle();

    // With 64 entries in a plain ListView, only what's within the initial
    // viewport is actually built — checking the first few (always visible
    // without scrolling) rather than every entry.
    for (final entry in kSkillEquivalencies.take(3)) {
      expect(find.text(entry.militaryTerm), findsOneWidget);
    }
    expect(find.text(kSkillEquivalencies.first.description), findsNothing);
  });

  testWidgets('searching narrows the list to matching entries', (tester) async {
    await tester.pumpWidget(_wrap(ProfileRepository()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('skillEquivalencySearchField')), 'higher command');
    await tester.pumpAndSettle();

    expect(find.text('Higher Command Course'), findsOneWidget);
    expect(find.text('National Defence College (NDC), New Delhi'), findsNothing);
  });

  testWidgets('a search with no matches shows a clear empty state', (tester) async {
    await tester.pumpWidget(_wrap(ProfileRepository()));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('skillEquivalencySearchField')),
      'something that does not exist anywhere',
    );
    await tester.pumpAndSettle();

    expect(find.text('No matches for that search.'), findsOneWidget);
  });

  testWidgets('tapping an entry expands it to show the full description', (tester) async {
    await tester.pumpWidget(_wrap(ProfileRepository()));
    await tester.pumpAndSettle();

    final entry = kSkillEquivalencies.firstWhere((e) => e.militaryTerm == 'Higher Command Course');
    await tester.tap(find.text('Higher Command Course'));
    await tester.pumpAndSettle();

    expect(find.text(entry.description), findsOneWidget);
  });

  testWidgets('a course already mentioned in the officer\'s CV is flagged', (tester) async {
    final repo = ProfileRepository()..saveProfile(_profileWithCv);
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('cvMatchBadge_Higher Command Course')), findsOneWidget);
    // A course never mentioned in the CV text gets no badge.
    expect(
      find.byKey(const Key('cvMatchBadge_National Defence College (NDC), New Delhi')),
      findsNothing,
    );
  });

  testWidgets('with no CV uploaded, nothing is flagged', (tester) async {
    await tester.pumpWidget(_wrap(ProfileRepository()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('cvMatchBadge_Higher Command Course')), findsNothing);
  });
}
