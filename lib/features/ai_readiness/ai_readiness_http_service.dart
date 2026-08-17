import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'ai_competency.dart';
import 'ai_readiness.dart';

const _workerUrl = 'https://next-career-after-fauj-fitment.sandy060965.workers.dev/ai-readiness';
const _appSharedKey = String.fromEnvironment('APP_SHARED_KEY');
const _maxAttempts = 3;
const _retryDelay = Duration(seconds: 2);
const _retryableStatusCodes = {502, 503, 504, 522, 523, 524};

class AiReadinessException implements Exception {
  AiReadinessException(this.message);

  final String message;

  @override
  String toString() => message;
}

AiCompetency? _findCompetency(String id) {
  for (final competency in kAiCompetencies) {
    if (competency.id == id) return competency;
  }
  return null;
}

GapSeverity _parseSeverity(String value) => switch (value) {
      'high' => GapSeverity.high,
      'medium' => GapSeverity.medium,
      _ => GapSeverity.low,
    };

RoadmapPhase _parsePhase(String value) => switch (value) {
      'day60' => RoadmapPhase.day60,
      'day90' => RoadmapPhase.day90,
      _ => RoadmapPhase.day30,
    };

Future<AiReadinessResult> httpAnalyzeAiReadiness({
  required AiSelfAssessment assessment,
  required String cvFileName,
  String? cvExtractedText,
  Uint8List? cvPdfBytes,
  DateTime? releaseDate,
}) async {
  final body = <String, dynamic>{
    'readinessScore': assessment.readinessScore,
    'dimensionScores': assessment.dimensionScores.map(
      (dimension, score) => MapEntry(dimension.name, score),
    ),
    if (releaseDate != null) 'releaseDate': releaseDate.toIso8601String(),
  };
  if (cvPdfBytes != null) {
    body['cvPdfBase64'] = base64Encode(cvPdfBytes);
  } else {
    body['cvText'] = cvExtractedText ?? cvFileName;
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
    throw AiReadinessException('Could not reach the AI readiness service: $lastError');
  }
  if (response.statusCode != 200) {
    throw AiReadinessException(
      'AI readiness analysis failed (${response.statusCode}): ${response.body}',
    );
  }

  final json = jsonDecode(response.body) as Map<String, dynamic>;

  final skillGaps = <SkillGap>[];
  for (final raw in (json['skill_gaps'] as List? ?? const [])) {
    final map = raw as Map<String, dynamic>;
    final competency = _findCompetency(map['competency_id'] as String);
    if (competency == null) continue;
    skillGaps.add(
      SkillGap(
        competency: competency,
        severity: _parseSeverity(map['severity'] as String),
        reason: map['reason'] as String,
      ),
    );
  }

  final roadmap = <RoadmapItem>[
    for (final raw in (json['roadmap'] as List? ?? const []))
      RoadmapItem(
        phase: _parsePhase((raw as Map<String, dynamic>)['phase'] as String),
        title: raw['title'] as String,
        description: raw['description'] as String,
        courseId: raw['course_id'] as String?,
      ),
  ];

  return AiReadinessResult(
    readinessScore: (json['readiness_score'] as num?)?.toInt() ?? assessment.readinessScore,
    scoreRationale: json['score_rationale'] as String,
    dimensionScores: assessment.dimensionScores,
    skillGaps: skillGaps,
    cvAiBridge: json['cv_ai_bridge'] as String,
    roadmap: roadmap,
  );
}
