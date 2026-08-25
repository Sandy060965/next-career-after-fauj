import 'package:flutter_test/flutter_test.dart';
import 'package:next_career_after_fauj/features/vertical_fit/aptitude_question.dart';
import 'package:next_career_after_fauj/features/vertical_fit/cv_evidence.dart';

void main() {
  group('CvEvidenceResult.evidenceFor', () {
    test('finds the matching dimension for the matching vertical', () {
      const result = CvEvidenceResult(
        verticals: [
          VerticalEvidence(
            verticalName: 'Tech Product & Data Operations',
            dimensionEvidence: [
              DimensionEvidence(
                dimension: AptitudeDimension.investigative,
                found: true,
                evidence: 'Led data-driven planning for a 900-person unit.',
              ),
              DimensionEvidence(dimension: AptitudeDimension.openness, found: false),
            ],
          ),
        ],
      );

      final found = result.evidenceFor('Tech Product & Data Operations', AptitudeDimension.investigative);
      expect(found?.found, isTrue);
      expect(found?.evidence, contains('data-driven'));

      final notFound = result.evidenceFor('Tech Product & Data Operations', AptitudeDimension.openness);
      expect(notFound?.found, isFalse);
      expect(notFound?.evidence, isNull);
    });

    test('returns null for an unknown vertical or dimension', () {
      const result = CvEvidenceResult(verticals: []);
      expect(result.evidenceFor('Unknown Vertical', AptitudeDimension.investigative), isNull);
    });
  });

  group('JSON round-trip', () {
    test('CvEvidenceResult survives toJson/fromJson', () {
      const result = CvEvidenceResult(
        verticals: [
          VerticalEvidence(
            verticalName: 'Corporate Legal & In-House Counsel',
            dimensionEvidence: [
              DimensionEvidence(
                dimension: AptitudeDimension.conventional,
                found: true,
                evidence: 'Advised on disciplinary proceedings and compliance matters.',
              ),
            ],
          ),
        ],
      );

      final restored = CvEvidenceResult.fromJson(result.toJson());
      expect(restored.verticals.single.verticalName, 'Corporate Legal & In-House Counsel');
      expect(restored.verticals.single.dimensionEvidence.single.dimension, AptitudeDimension.conventional);
      expect(restored.verticals.single.dimensionEvidence.single.found, isTrue);
      expect(
        restored.verticals.single.dimensionEvidence.single.evidence,
        'Advised on disciplinary proceedings and compliance matters.',
      );
    });
  });
}
