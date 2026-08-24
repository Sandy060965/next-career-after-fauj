import 'dart:typed_data';

import 'civilianized_cv.dart';

typedef CvCivilianizer = Future<CivilianizedCv> Function({
  required String cvText,
  Uint8List? cvPdfBytes,
});

/// Placeholder used until the Worker's /civilianize-cv endpoint is
/// deployed. Returns fixed sample content so the results screen can be
/// built and tested independently of the backend.
Future<CivilianizedCv> mockCivilianizeCv({
  required String cvText,
  Uint8List? cvPdfBytes,
}) async {
  await Future.delayed(const Duration(milliseconds: 700));
  return const CivilianizedCv(
    civilianizedCv:
        'Operations Director with 14+ years leading large, complex organisations in '
        'high-stakes environments — crisis response, physical security, threat '
        'assessment, and large-team leadership. Led 700+ personnel across multi-site, '
        'multi-stakeholder operations, managed enterprise risk registers, and built '
        'collaborative relationships with regulatory and government authorities.',
    translationNotes: [
      'Rewrote command/unit-scale language as "led 700+ personnel" and '
          '"Operations Director" for a civilian audience.',
    ],
  );
}
