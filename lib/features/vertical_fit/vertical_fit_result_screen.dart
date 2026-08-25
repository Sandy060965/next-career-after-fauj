import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/profile_repository.dart';
import '../career_paths/career_paths_screen.dart';
import '../career_paths/career_vertical.dart';
import '../career_paths/corps_affinity.dart';
import 'aptitude_question.dart';
import 'cv_evidence.dart';
import 'cv_evidence_service.dart';
import 'vertical_fit.dart';
import 'vertical_fit_quiz_screen.dart';

class VerticalFitResultScreen extends StatefulWidget {
  const VerticalFitResultScreen({
    super.key,
    required this.assessment,
    this.corpsOrArm,
    this.groundCvEvidence = mockGroundCvEvidence,
  });

  final VerticalFitAssessment assessment;

  /// The officer's Corps/Arm, if given at onboarding — determines whether
  /// ranking uses the general 20 verticals (with soft affinity badges) or a
  /// fully constrained domain universe (medicine, legal practice). See
  /// `corps_affinity.dart`.
  final String? corpsOrArm;

  /// Overridable for testing; defaults to sample data until the Worker's
  /// /cv-evidence endpoint is wired in. Opt-in — never called automatically.
  final CvEvidenceGrounder groundCvEvidence;

  @override
  State<VerticalFitResultScreen> createState() => _VerticalFitResultScreenState();
}

class _VerticalFitResultScreenState extends State<VerticalFitResultScreen> {
  late final Map<AptitudeDimension, int> _dimensionScores;
  late final List<CareerVertical> _universe;
  late final bool _constrained;
  late final List<VerticalFit> _top3;
  late final List<String> _softAffinity;

  bool _isGroundingEvidence = false;
  String? _evidenceError;
  CvEvidenceResult? _evidence;
  final Set<String> _dismissedDisconnects = {};

  @override
  void initState() {
    super.initState();
    _dimensionScores = widget.assessment.dimensionScores;
    _universe = effectiveVerticalUniverse(widget.corpsOrArm);
    _constrained = isDomainConstrained(widget.corpsOrArm);
    _top3 = rankVerticalFit(_dimensionScores, universe: _universe).take(3).toList();
    _softAffinity = _constrained ? const [] : (kCorpsSoftAffinity[widget.corpsOrArm] ?? const []);

    final cached = context.read<ProfileRepository>().lastCvEvidenceResult;
    final cachedNames = cached?.verticals.map((v) => v.verticalName).toSet();
    final top3Names = _top3.map((f) => f.vertical.name).toSet();
    if (cached != null && setEquals(cachedNames, top3Names)) {
      _evidence = cached;
    }
  }

  Future<void> _groundInCv() async {
    setState(() {
      _isGroundingEvidence = true;
      _evidenceError = null;
    });
    final profile = context.read<ProfileRepository>().profile;
    final requests = _top3
        .map(
          (fit) => VerticalEvidenceRequest(
            verticalName: fit.vertical.name,
            dimensions: fit.topContributingDimensions(_dimensionScores),
          ),
        )
        .toList();
    try {
      final result = await widget.groundCvEvidence(
        cvText: profile?.cvExtractedText ?? profile?.cvFileName ?? '',
        cvPdfBytes: profile?.cvPdfBytes,
        requests: requests,
      );
      if (!mounted) return;
      context.read<ProfileRepository>().saveCvEvidenceResult(result);
      setState(() {
        _evidence = result;
        _dismissedDisconnects.clear();
        _isGroundingEvidence = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _evidenceError = '$e';
        _isGroundingEvidence = false;
      });
    }
  }

  void _retake() {
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => const VerticalFitQuizScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Career Vertical Fit')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (_constrained) ...[
            Container(
              key: const Key('domainConstrainedNotice'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Your results are scoped to ${widget.corpsOrArm}-relevant career paths, not the '
                'general corporate verticals — your own professional domain carries the most '
                'weight here.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text('Your profile', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final group in DimensionGroup.values) ...[
            Text(group.label, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            for (final dimension in AptitudeDimension.values.where((d) => d.group == group))
              _DimensionBar(dimension: dimension, score: _dimensionScores[dimension] ?? 0),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 20),
          Text('Your top 3 verticals', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (var i = 0; i < _top3.length; i++)
            _VerticalFitCard(
              rank: i + 1,
              fit: _top3[i],
              dimensionScores: _dimensionScores,
              corpsAffinity: _softAffinity.contains(_top3[i].vertical.name),
              evidence: _evidence,
              isDismissed: _dismissedDisconnects.contains(_top3[i].vertical.name),
              onRetake: _retake,
              onDismiss: () =>
                  setState(() => _dismissedDisconnects.add(_top3[i].vertical.name)),
            ),
          const SizedBox(height: 8),
          if (_evidenceError != null) ...[
            Text(_evidenceError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              key: Key(_evidence == null ? 'groundInCvButton' : 'regenerateCvEvidenceButton'),
              onPressed: _isGroundingEvidence ? null : _groundInCv,
              child: _isGroundingEvidence
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_evidence == null ? 'Ground my results in my CV' : 'Regenerate CV evidence'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              key: const Key('exploreCareerPathsButton'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CareerPathsScreen(
                    recommendedVerticals: _top3.map((f) => f.vertical.name).toSet(),
                  ),
                ),
              ),
              child: const Text('Explore these in Career Paths'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DimensionBar extends StatelessWidget {
  const _DimensionBar({required this.dimension, required this.score});

  final AptitudeDimension dimension;
  final int score;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(dimension.label, style: Theme.of(context).textTheme.bodyMedium)),
              Text('$score', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              key: ValueKey('dimensionBar_${dimension.name}'),
              value: score / 100,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalFitCard extends StatelessWidget {
  const _VerticalFitCard({
    required this.rank,
    required this.fit,
    required this.dimensionScores,
    required this.onRetake,
    required this.onDismiss,
    this.corpsAffinity = false,
    this.evidence,
    this.isDismissed = false,
  });

  final int rank;
  final VerticalFit fit;
  final Map<AptitudeDimension, int> dimensionScores;
  final VoidCallback onRetake;
  final VoidCallback onDismiss;

  /// True when this vertical also matches the officer's Corps/Arm — a
  /// corroborating badge only, never a factor in [fit.fitScore] itself.
  final bool corpsAffinity;

  /// CV-evidence grounding result, if the officer opted in — null means
  /// they haven't (yet), in which case confidence falls back to
  /// self-rating-only, exactly as before this feature existed.
  final CvEvidenceResult? evidence;

  /// True once the officer has dismissed this card's disconnect notice for
  /// this viewing — session-local only, never persisted, so the notice
  /// returns on a later visit if the disconnect is still real.
  final bool isDismissed;

  @override
  Widget build(BuildContext context) {
    final topDimensions = fit.topContributingDimensions(dimensionScores);
    final why = topDimensions.isEmpty
        ? 'Broadly aligned with your overall profile.'
        : 'Driven mainly by your strengths in '
            '${topDimensions.map((d) => '${d.label} (${dimensionScores[d]}/100)').join(' and ')}.';
    final confidence = fit.confidence(dimensionScores, cvEvidence: evidence, corpsAffinity: corpsAffinity);
    final colorScheme = Theme.of(context).colorScheme;
    final confidenceColor = switch (confidence) {
      FitConfidence.high => colorScheme.primaryContainer,
      FitConfidence.medium => colorScheme.tertiaryContainer,
      FitConfidence.low => colorScheme.surfaceContainerHighest,
      FitConfidence.disconnected => colorScheme.errorContainer,
    };

    return Card(
      key: ValueKey('verticalFit_${fit.vertical.name}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 14, child: Text('$rank')),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(fit.vertical.name, style: Theme.of(context).textTheme.titleMedium),
                ),
                Text('${fit.fitScore}/100', style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                Chip(
                  key: ValueKey('confidence_${fit.vertical.name}'),
                  label: Text(confidence.label),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: confidenceColor,
                ),
                if (corpsAffinity)
                  Chip(
                    key: ValueKey('corpsAffinity_${fit.vertical.name}'),
                    label: const Text('Matches your Corps/Arm background'),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: colorScheme.secondaryContainer,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(why, style: Theme.of(context).textTheme.bodySmall),
            if (evidence != null) ...[
              const SizedBox(height: 12),
              Text('From your CV', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              for (final dim in topDimensions)
                _EvidenceLine(
                  key: ValueKey('evidence_${fit.vertical.name}_${dim.name}'),
                  dimension: dim,
                  evidence: evidence!.evidenceFor(fit.vertical.name, dim),
                ),
            ],
            if (confidence == FitConfidence.disconnected && !isDismissed) ...[
              const SizedBox(height: 12),
              Container(
                key: ValueKey('disconnectNotice_${fit.vertical.name}'),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Your self-rating and CV don't fully agree here — want to revisit your "
                      'answers?',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            key: ValueKey('keepRatingButton_${fit.vertical.name}'),
                            onPressed: onDismiss,
                            child: const Text('Keep my rating as-is'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            key: ValueKey('retakeAssessmentButton_${fit.vertical.name}'),
                            onPressed: onRetake,
                            child: const Text('Retake the assessment'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EvidenceLine extends StatelessWidget {
  const _EvidenceLine({super.key, required this.dimension, required this.evidence});

  final AptitudeDimension dimension;
  final DimensionEvidence? evidence;

  @override
  Widget build(BuildContext context) {
    final found = evidence?.found ?? false;
    final text = found
        ? '${dimension.label}: ${evidence!.evidence}'
        : '${dimension.label}: No CV evidence found for this yet.';
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: found
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : Theme.of(context).colorScheme.error,
            ),
      ),
    );
  }
}
