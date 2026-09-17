import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/features/skill_equivalency/skill_equivalency.dart';

const _dssc = SkillEquivalency(
  militaryTerm: 'Defence Services Staff College (DSSC), Wellington',
  civilianEquivalent: 'Strategic Management & Cross-Functional Leadership',
  description: 'Placeholder for the matcher test.',
);

void main() {
  test('matches the exact full term, case-insensitively', () {
    expect(
      cvMentionsEquivalency('I attended the DEFENCE SERVICES STAFF COLLEGE (DSSC), Wellington.', _dssc),
      isTrue,
    );
  });

  test('matches a bracketed abbreviation even without the full decorated name', () {
    expect(cvMentionsEquivalency('Graduate of dssc, 2019.', _dssc), isTrue);
  });

  test('does not match unrelated CV text', () {
    expect(cvMentionsEquivalency('Commanded a logistics battalion.', _dssc), isFalse);
  });

  test('returns false for null or empty CV text', () {
    expect(cvMentionsEquivalency(null, _dssc), isFalse);
    expect(cvMentionsEquivalency('   ', _dssc), isFalse);
  });

  test('an entry with no bracketed abbreviation only matches its full term', () {
    const noAbbreviation = SkillEquivalency(
      militaryTerm: 'Higher Command Course',
      civilianEquivalent: 'Advanced Executive Leadership (General Manager / VP level)',
      description: 'Placeholder for the matcher test.',
    );
    expect(cvMentionsEquivalency('Completed the Higher Command Course.', noAbbreviation), isTrue);
    expect(cvMentionsEquivalency('Completed HCC.', noAbbreviation), isFalse);
  });
}
