import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routing/app_routes.dart';
import '../../core/services/profile_repository.dart';
import '../career_paths/corps_affinity.dart';
import '../vertical_fit/vertical_fit.dart';
import 'target_role_service.dart';
import 'target_role_strategy.dart';

class TargetRoleStrategyScreen extends StatefulWidget {
  const TargetRoleStrategyScreen({super.key, this.generateStrategy = mockGenerateTargetRoleStrategy});

  /// Overridable for testing; defaults to sample data until the Worker's
  /// /target-role-strategy endpoint is wired in.
  final TargetRoleStrategist generateStrategy;

  @override
  State<TargetRoleStrategyScreen> createState() => _TargetRoleStrategyScreenState();
}

class _TargetRoleStrategyScreenState extends State<TargetRoleStrategyScreen> {
  bool _isLoading = true;
  String? _error;
  TargetRoleStrategyResult? _result;
  List<TargetRoleDraft>? _drafts;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final repo = context.read<ProfileRepository>();
    final assessment = repo.lastVerticalFitAssessment;
    final profile = repo.profile;
    if (assessment == null || profile == null) {
      setState(() => _isLoading = false);
      return;
    }

    final drafts = buildTargetRoleDrafts(
      dimensionScores: assessment.dimensionScores,
      workExperienceYears: profile.workExperienceYears,
      universe: effectiveVerticalUniverse(profile.corpsOrArm),
    );
    _drafts = drafts;

    final cached = repo.lastTargetRoleStrategy;
    final draftNames = drafts.map((d) => d.verticalName).toSet();
    final cachedNames = cached?.targets.map((t) => t.verticalName).toSet();
    if (cached != null && setEquals(cachedNames, draftNames)) {
      setState(() {
        _result = cached;
        _isLoading = false;
      });
    } else {
      _generate();
    }
  }

  Future<void> _generate() async {
    final drafts = _drafts;
    if (drafts == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });
    final profile = context.read<ProfileRepository>().profile;
    try {
      final result = await widget.generateStrategy(
        cvText: profile?.cvExtractedText ?? profile?.cvFileName ?? '',
        cvPdfBytes: profile?.cvPdfBytes,
        drafts: drafts,
      );
      if (!mounted) return;
      context.read<ProfileRepository>().saveTargetRoleStrategy(result);
      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAssessment = context.watch<ProfileRepository>().lastVerticalFitAssessment != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Target Role Strategy'),
        actions: [
          if (hasAssessment)
            IconButton(
              key: const Key('regenerateTargetRoleButton'),
              icon: const Icon(Icons.refresh),
              tooltip: 'Regenerate',
              onPressed: _isLoading ? null : _generate,
            ),
        ],
      ),
      body: !hasAssessment
          ? _buildNoAssessmentCard(context)
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(_error!, textAlign: TextAlign.center),
                      ),
                    )
                  : _result == null
                      ? const SizedBox.shrink()
                      : _buildResult(context, _result!),
    );
  }

  Widget _buildNoAssessmentCard(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Take the Career Vertical Fit quiz first — your target role strategy is '
              'built directly from those answers.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              key: const Key('goToVerticalFitButton'),
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.verticalFit),
              child: const Text('Take Vertical Fit Quiz'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(BuildContext context, TargetRoleStrategyResult result) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Your top 3 verticals, ranked by fit — role titles from your years of '
          'experience, explanations grounded in your own CV.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 20),
        for (var i = 0; i < result.targets.length; i++) ...[
          _TargetCard(target: result.targets[i], isPrimary: i == 0),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _TargetCard extends StatelessWidget {
  const _TargetCard({required this.target, required this.isPrimary});

  final TargetRoleNarrative target;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey('targetCard_${target.verticalName}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Chip(
                    label: Text(
                      isPrimary ? 'Primary' : 'Secondary',
                      overflow: TextOverflow.ellipsis,
                    ),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: isPrimary
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
                const Spacer(),
                Text('Fit: ${target.fitScore}/100', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            Text(target.roleTitle, style: Theme.of(context).textTheme.titleLarge),
            Text(target.verticalName, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Chip(
              key: ValueKey('confidence_${target.verticalName}'),
              label: Text(target.confidence.label),
              visualDensity: VisualDensity.compact,
              backgroundColor: switch (target.confidence) {
                FitConfidence.high => Theme.of(context).colorScheme.primaryContainer,
                FitConfidence.medium => Theme.of(context).colorScheme.tertiaryContainer,
                FitConfidence.low => Theme.of(context).colorScheme.surfaceContainerHighest,
              },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final dim in target.topDimensionLabels)
                  Chip(label: Text(dim), visualDensity: VisualDensity.compact),
              ],
            ),
            const SizedBox(height: 12),
            Text(target.why),
            if (target.strengthenTip.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('To strengthen this case', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(target.strengthenTip),
            ],
          ],
        ),
      ),
    );
  }
}
