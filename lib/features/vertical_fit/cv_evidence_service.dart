import 'dart:typed_data';

import 'aptitude_question.dart';
import 'cv_evidence.dart';

typedef CvEvidenceGrounder = Future<CvEvidenceResult> Function({
  required String cvText,
  Uint8List? cvPdfBytes,
  required List<VerticalEvidenceRequest> requests,
});

/// Placeholder used until the Worker's /cv-evidence endpoint is deployed.
/// Returns fixed sample evidence so the results screen can be built and
/// tested independently of the backend.
Future<CvEvidenceResult> mockGroundCvEvidence({
  required String cvText,
  Uint8List? cvPdfBytes,
  required List<VerticalEvidenceRequest> requests,
}) async {
  await Future.delayed(const Duration(milliseconds: 700));
  return CvEvidenceResult(
    verticals: requests
        .map(
          (r) => VerticalEvidence(
            verticalName: r.verticalName,
            dimensionEvidence: r.dimensions
                .map(
                  (d) => DimensionEvidence(
                    dimension: d,
                    found: true,
                    evidence: 'Sample placeholder evidence for ${d.label}.',
                  ),
                )
                .toList(),
          ),
        )
        .toList(),
  );
}
