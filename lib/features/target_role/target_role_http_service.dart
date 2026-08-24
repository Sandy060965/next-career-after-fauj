import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'target_role_strategy.dart';

const _workerUrl = 'https://next-career-after-fauj-fitment.sandy060965.workers.dev/target-role-strategy';
const _appSharedKey = String.fromEnvironment('APP_SHARED_KEY');
const _maxAttempts = 3;
const _retryDelay = Duration(seconds: 2);
const _retryableStatusCodes = {502, 503, 504, 522, 523, 524};

class TargetRoleStrategyException implements Exception {
  TargetRoleStrategyException(this.message);

  final String message;

  @override
  String toString() => message;
}

Future<TargetRoleStrategyResult> httpGenerateTargetRoleStrategy({
  required String cvText,
  Uint8List? cvPdfBytes,
  required List<TargetRoleDraft> drafts,
}) async {
  final body = <String, dynamic>{
    'targets': drafts
        .map(
          (d) => {
            'vertical': d.verticalName,
            'roleTitle': d.roleTitle,
            'fitScore': d.fitScore,
            'topDimensions': d.topDimensionLabels,
          },
        )
        .toList(),
  };
  if (cvPdfBytes != null) {
    body['cvPdfBase64'] = base64Encode(cvPdfBytes);
  } else {
    body['cvText'] = cvText;
  }
  final encodedBody = jsonEncode(body);

  http.Response? response;
  Object? lastError;
  for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
    try {
      response = await http.post(
        Uri.parse(_workerUrl),
        headers: const {
          'content-type': 'application/json',
          'x-app-key': _appSharedKey,
        },
        body: encodedBody,
      );
    } catch (e) {
      lastError = e;
      response = null;
    }

    final shouldRetry = response == null || _retryableStatusCodes.contains(response.statusCode);
    if (!shouldRetry || attempt == _maxAttempts) break;
    await Future.delayed(_retryDelay);
  }

  if (response == null) {
    throw TargetRoleStrategyException('Could not reach the target role service: $lastError');
  }
  if (response.statusCode != 200) {
    throw TargetRoleStrategyException(
      'Generating your target role strategy failed (${response.statusCode}): ${response.body}',
    );
  }

  final json = jsonDecode(response.body) as Map<String, dynamic>;
  final rawTargets = (json['targets'] as List? ?? const []);
  // Match by vertical name rather than trusting response order — the model
  // is asked to echo the vertical, but never trust that blindly.
  final rawByVertical = <String, Map<String, dynamic>>{
    for (final r in rawTargets)
      if (r is Map && r['vertical'] is String) r['vertical'] as String: r as Map<String, dynamic>,
  };

  final targets = drafts.map((draft) {
    final raw = rawByVertical[draft.verticalName];
    return TargetRoleNarrative(
      verticalName: draft.verticalName,
      category: draft.category,
      roleTitle: draft.roleTitle,
      fitScore: draft.fitScore,
      topDimensionLabels: draft.topDimensionLabels,
      why: raw?['why'] as String? ?? 'Could not generate an explanation for this target.',
      strengthenTip: raw?['strengthen_tip'] as String? ?? '',
    );
  }).toList();

  return TargetRoleStrategyResult(targets: targets);
}
