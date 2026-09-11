import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routing/app_routes.dart';
import '../../core/routing/guided_sequence.dart';
import '../../core/services/profile_repository.dart';
import '../../core/widgets/home_button.dart';
import '../career_handbook/career_handbook_detail_screen.dart';
import '../cv_upload/cv_upload_sheet.dart';
import '../career_paths/career_paths_screen.dart';
import '../career_paths/career_vertical.dart';
import '../career_paths/corps_affinity.dart';
import '../career_paths/corps_vertical_fit_matrix.dart';
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
  late final List<VerticalFit> _fullRanking;
  late final List<VerticalFit> _top3;

  /// Strong-fit-per-matrix verticals that narrowly missed the top 3 (ranked
  /// 4-6) — surfaced separately rather than folded into the ranking itself,
  /// since [rankVerticalFit] stays purely aptitude-driven.
  late final List<VerticalFit> _nearMisses;

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
    _fullRanking = rankVerticalFit(_dimensionScores, universe: _universe);
    _top3 = _fullRanking.take(3).toList();
    _nearMisses = (_constrained || widget.corpsOrArm == null)
        ? const []
        : _fullRanking.skip(3).take(3).where((f) => _tierFor(f.vertical.name) == CorpsVerticalFitTier.strong).toList();

    final cached = context.read<ProfileRepository>().lastCvEvidenceResult;
    final cachedNames = cached?.verticals.map((v) => v.verticalName).toSet();
    final top3Names = _top3.map((f) => f.vertical.name).toSet();
    if (cached != null && setEquals(cachedNames, top3Names)) {
      _evidence = cached;
    }
  }

  /// Null when constrained (badges are suppressed there — the whole
  /// universe is already Corps/Arm-scoped) or the officer skipped Corps/Arm
  /// at onboarding.
  CorpsVerticalFitTier? _tierFor(String verticalName) {
    if (_constrained || widget.corpsOrArm == null) return null;
    return corpsVerticalFitTier(widget.corpsOrArm!, verticalName);
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
    final repo = context.watch<ProfileRepository>();
    final profile = repo.profile;
    final hasCv = repo.preferredCivilianCvText != null ||
        (profile?.cvExtractedText?.isNotEmpty ?? false) ||
        profile?.cvPdfBytes != null;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Your Career Vertical Fit'), actions: const [HomeButton()]),
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
              corpsTier: _tierFor(_top3[i].vertical.name),
              evidence: _evidence,
              isDismissed: _dismissedDisconnects.contains(_top3[i].vertical.name),
              onRetake: _retake,
              onDismiss: () =>
                  setState(() => _dismissedDisconnects.add(_top3[i].vertical.name)),
            ),
          if (_nearMisses.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Also worth a look, given your background', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final fit in _nearMisses)
              Card(
                key: ValueKey('nearMiss_${fit.vertical.name}'),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(fit.vertical.name),
                  subtitle: Text('${fit.fitScore}/100 by aptitude — a Strong fit for ${widget.corpsOrArm}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => CareerHandbookDetailScreen(vertical: fit.vertical)),
                  ),
                ),
              ),
          ],
          const SizedBox(height: 8),
          if (hasCv) ...[
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
          ] else
            _buildNoCvNotice(context, colorScheme),
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
          const SizedBox(height: 12),
          const NextStepButton(completedStepKey: 'verticalFit'),
        ],
      ),
    );
  }

  Widget _buildNoCvNotice(BuildContext context, ColorScheme colorScheme) {
    return Container(
      key: const Key('verticalFitResultNoCvNotice'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 20, color: colorScheme.onTertiaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Grounding these results in real evidence from your background needs a CV '
                  "on file — add one to see how they hold up against what you've actually done.",
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: colorScheme.onTertiaryContainer),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('verticalFitResultAddCvButton'),
                  onPressed: () => showCvUploadSheet(context),
                  child: const Text('Add CV'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  key: const Key('verticalFitResultBuildCvButton'),
                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.cvBuilder),
                  child: const Text('Build CV'),
                ),
              ),
            ],
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

/// A qualitative read on the 0-100 fit score, shown alongside the number so
/// it's interpretable at a glance. "Current" is deliberate throughout —
/// this describes the officer's present profile, not a ceiling on what
/// they could become with the right preparation.
String _fitBandLabel(int score) {
  if (score >= 80) return 'Strong current fit';
  if (score >= 65) return 'Good potential';
  if (score >= 50) return 'Development area';
  return 'Limited current fit';
}

class _VerticalFitCard extends StatelessWidget {
  const _VerticalFitCard({
    required this.rank,
    required this.fit,
    required this.dimensionScores,
    required this.onRetake,
    required this.onDismiss,
    this.corpsTier,
    this.evidence,
    this.isDismissed = false,
  });

  final int rank;
  final VerticalFit fit;
  final Map<AptitudeDimension, int> dimensionScores;
  final VoidCallback onRetake;
  final VoidCallback onDismiss;

  /// This vertical's Strong/Possible/Limited fit for the officer's
  /// Corps/Arm, from `corps_vertical_fit_matrix.dart` — a corroborating
  /// badge only, never a factor in [fit.fitScore] itself. Null when Corps/
  /// Arm badges don't apply here (constrained officer, or none given).
  final CorpsVerticalFitTier? corpsTier;

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
    final corpsCorroborates =
        corpsTier == CorpsVerticalFitTier.strong || corpsTier == CorpsVerticalFitTier.possible;
    final confidence =
        fit.confidence(dimensionScores, cvEvidence: evidence, corpsAffinity: corpsCorroborates);
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${fit.fitScore}/100', style: Theme.of(context).textTheme.titleSmall),
                    Text(
                      _fitBandLabel(fit.fitScore),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
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
                if (corpsCorroborates)
                  Chip(
                    key: ValueKey('corpsAffinity_${fit.vertical.name}'),
                    label: Text('${corpsTier!.label} for your Corps/Arm'),
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
