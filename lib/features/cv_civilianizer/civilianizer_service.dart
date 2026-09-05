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
    translations: [
      CvTranslation(
        before: 'Commanding Officer of an 800-personnel infantry unit.',
        after: 'Operations Director leading an 800-person organisation across multiple sites.',
        skillTags: ['Operations Leadership', 'Organisational Management'],
      ),
      CvTranslation(
        before: 'Responsible for unit discipline, welfare, and operational readiness.',
        after:
            'Accountable for team performance, wellbeing programmes, and readiness of '
            'critical operations at all times.',
        skillTags: ['People Management', 'Business Continuity'],
      ),
      CvTranslation(
        before: 'Liaised with district administration and police during internal security duties.',
        after:
            'Built and managed collaborative working relationships with regulatory and '
            'government authorities on sensitive, high-visibility matters.',
        skillTags: ['Stakeholder Management', 'Government Relations'],
      ),
    ],
  );
}
