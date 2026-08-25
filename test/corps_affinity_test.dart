import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/features/career_paths/career_vertical.dart';
import 'package:next_career_after_fauj/features/career_paths/corps_affinity.dart';

void main() {
  group('effectiveVerticalUniverse', () {
    test('returns the general 20 verticals when no Corps/Arm is given', () {
      expect(effectiveVerticalUniverse(null), kCareerVerticals);
    });

    test('returns the general 20 verticals for a Corps/Arm with no constraint', () {
      expect(effectiveVerticalUniverse('Corps of Signals'), kCareerVerticals);
    });

    test('replaces the universe entirely for AMC, across all three services', () {
      for (final corps in ['Army Medical Corps (AMC)', 'Medical Branch (Navy)', 'Medical Branch (Air Force)']) {
        final universe = effectiveVerticalUniverse(corps);
        expect(universe, kMedicalCareerVerticals);
        expect(universe.length, 9);
        expect(universe.any((v) => kCareerVerticals.contains(v)), isFalse);
      }
    });

    test('JAG gets its own legal verticals plus 4 specific general ones, across all three services', () {
      for (final corps in [
        "Judge Advocate General's Department (JAG)",
        "Judge Advocate General's Branch (Navy)",
        "Judge Advocate General's Branch (Air Force)",
      ]) {
        final universe = effectiveVerticalUniverse(corps);
        expect(universe.length, 9); // 5 legal + 4 general
        for (final v in kLegalCareerVerticals) {
          expect(universe, contains(v));
        }
        for (final name in [
          'Corporate Governance',
          'Corporate Affairs, ESG & Public Policy',
          'Corporate Investigations',
          'Defence PSUs, Offsets & GovTech',
        ]) {
          expect(universe.any((v) => v.name == name), isTrue, reason: '$corps should include $name');
        }
        // Should not silently include unrelated general verticals.
        expect(universe.any((v) => v.name == 'Operations & Process Excellence'), isFalse);
      }
    });
  });

  group('isDomainConstrained', () {
    test('false for null and for unconstrained Corps/Arm', () {
      expect(isDomainConstrained(null), isFalse);
      expect(isDomainConstrained('Infantry'), isFalse);
    });

    test('true for AMC and JAG entries', () {
      expect(isDomainConstrained('Army Medical Corps (AMC)'), isTrue);
      expect(isDomainConstrained("Judge Advocate General's Department (JAG)"), isTrue);
    });
  });

  group('kAllBrowsableVerticals', () {
    test('includes every general, medical, and legal vertical with no duplicates', () {
      final names = kAllBrowsableVerticals.map((v) => v.name).toList();
      expect(names.toSet().length, names.length);
      expect(kAllBrowsableVerticals.length, kCareerVerticals.length + 9 + 5);
    });
  });

  group('kCorpsSoftAffinity', () {
    test('only references real general vertical names', () {
      final generalNames = kCareerVerticals.map((v) => v.name).toSet();
      for (final entry in kCorpsSoftAffinity.entries) {
        for (final verticalName in entry.value) {
          expect(generalNames, contains(verticalName), reason: '${entry.key} -> $verticalName');
        }
      }
    });

    test('never lists a domain-constrained Corps/Arm', () {
      for (final corps in kCorpsSoftAffinity.keys) {
        expect(kCorpsConstrainedUniverse.containsKey(corps), isFalse);
      }
    });
  });
}
