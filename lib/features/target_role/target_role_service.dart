import 'dart:typed_data';

import 'target_role_strategy.dart';

typedef TargetRoleStrategist = Future<TargetRoleStrategyResult> Function({
  required String cvText,
  Uint8List? cvPdfBytes,
  required List<TargetRoleDraft> drafts,
});

/// Placeholder used until the Worker's /target-role-strategy endpoint is
/// deployed. Returns fixed sample narratives so the results screen can be
/// built and tested independently of the backend.
Future<TargetRoleStrategyResult> mockGenerateTargetRoleStrategy({
  required String cvText,
  Uint8List? cvPdfBytes,
  required List<TargetRoleDraft> drafts,
}) async {
  await Future.delayed(const Duration(milliseconds: 700));
  return TargetRoleStrategyResult(
    targets: drafts
        .map(
          (d) => TargetRoleNarrative(
            verticalName: d.verticalName,
            category: d.category,
            roleTitle: d.roleTitle,
            fitScore: d.fitScore,
            topDimensionLabels: d.topDimensionLabels,
            confidence: d.confidence,
            why: 'Sample placeholder text explaining why your background fits '
                '${d.roleTitle}.',
            strengthenTip: 'Sample placeholder tip for strengthening this target.',
          ),
        )
        .toList(),
  );
}
