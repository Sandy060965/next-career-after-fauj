import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/features/career_paths/career_vertical.dart';
import 'package:next_career_after_fauj/features/career_paths/corps_affinity.dart';
import 'package:next_career_after_fauj/features/career_paths/corps_vertical_fit_matrix.dart';
import 'package:next_career_after_fauj/features/onboarding/corps_options.dart';

void main() {
  group('corpsVerticalFitTier — medical/legal hard gate', () {
    test('a medical vertical is Strong only for the real medical corps', () {
      const vertical = 'Clinical Practice & Hospital Administration';
      for (final corps in kMedicalCorps) {
        expect(corpsVerticalFitTier(corps, vertical), CorpsVerticalFitTier.strong);
      }
      expect(corpsVerticalFitTier('Infantry', vertical), CorpsVerticalFitTier.restricted);
      expect(corpsVerticalFitTier('Corps of Signals', vertical), CorpsVerticalFitTier.restricted);
    });

    test('a legal vertical is Strong only for the real JAG entries', () {
      const vertical = 'Corporate Legal & In-House Counsel';
      for (final corps in kJagCorps) {
        expect(corpsVerticalFitTier(corps, vertical), CorpsVerticalFitTier.strong);
      }
      expect(corpsVerticalFitTier('Infantry', vertical), CorpsVerticalFitTier.restricted);
    });

    test('never returns restricted for a general vertical', () {
      for (final corps in [...kMedicalCorps, ...kJagCorps, 'Infantry', 'Corps of Signals']) {
        for (final vertical in kCareerVerticals) {
          expect(
            corpsVerticalFitTier(corps, vertical.name),
            isNot(CorpsVerticalFitTier.restricted),
            reason: '$corps -> ${vertical.name}',
          );
        }
      }
    });
  });

  test('falls back to limited for a corps/vertical pair the table has no data for', () {
    expect(
      corpsVerticalFitTier('Nonexistent Test Corps', 'Operations & Process Excellence'),
      CorpsVerticalFitTier.limited,
    );
  });

  group('kGeneralVerticalFitByCorps data integrity', () {
    test('every key is a real Corps/Arm/Branch name', () {
      final realCorps = kCorpsByService.values.expand((list) => list).toSet();
      for (final corps in kGeneralVerticalFitByCorps.keys) {
        expect(realCorps, contains(corps), reason: corps);
      }
    });

    test('every rated vertical is a real general vertical name', () {
      final generalNames = kCareerVerticals.map((v) => v.name).toSet();
      for (final entry in kGeneralVerticalFitByCorps.entries) {
        for (final verticalName in entry.value.keys) {
          expect(generalNames, contains(verticalName), reason: '${entry.key} -> $verticalName');
        }
      }
    });

    test('never rates a general vertical as restricted (that tier is reserved for the hard gate)', () {
      for (final entry in kGeneralVerticalFitByCorps.entries) {
        for (final tierEntry in entry.value.entries) {
          expect(
            tierEntry.value,
            isNot(CorpsVerticalFitTier.restricted),
            reason: '${entry.key} -> ${tierEntry.key}',
          );
        }
      }
    });
  });
}
