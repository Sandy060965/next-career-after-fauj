import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routing/app_routes.dart';
import '../../core/services/profile_repository.dart';
import 'compensation_estimate.dart';
import 'compensation_service.dart';

class CompensationScreen extends StatefulWidget {
  const CompensationScreen({super.key, this.estimateCompensation = mockEstimateCompensation});

  /// Overridable for testing; defaults to sample data until the Cloudflare
  /// Worker backend is wired in.
  final CompensationAnalyzer estimateCompensation;

  @override
  State<CompensationScreen> createState() => _CompensationScreenState();
}

class _CompensationScreenState extends State<CompensationScreen> {
  bool _isLoading = false;
  String? _error;
  CompensationEstimate? _estimate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final repository = context.read<ProfileRepository>();
    final jdText = repository.lastJdText;
    final jdPdfBytes = repository.lastJdPdfBytes;
    if (jdText == null && jdPdfBytes == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final estimate = await widget.estimateCompensation(
        jdText: jdText ?? '',
        jdPdfBytes: jdPdfBytes,
        cvText: repository.profile?.cvExtractedText,
      );
      if (!mounted) return;
      setState(() {
        _estimate = estimate;
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
    final repo = context.watch<ProfileRepository>();
    final hasJdText = repo.lastJdText != null || repo.lastJdPdfBytes != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Compensation Guidance')),
      body: !hasJdText
          ? _buildNoJdCard(context)
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(_error!, textAlign: TextAlign.center),
                      ),
                    )
                  : _estimate == null
                      ? const SizedBox.shrink()
                      : _buildResult(context, _estimate!),
    );
  }

  Widget _buildNoJdCard(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Run JD Match against a job description first — compensation guidance is '
              'estimated for that specific role.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              key: const Key('goToJdMatchButton'),
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.jdMatch),
              child: const Text('Run JD Match'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(BuildContext context, CompensationEstimate estimate) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(estimate.jobTitle, style: Theme.of(context).textTheme.headlineSmall),
        Text('${estimate.location}, India', style: Theme.of(context).textTheme.bodyMedium),
        if (estimate.locationIsEstimate) ...[
          const SizedBox(height: 8),
          Container(
            key: const Key('locationEstimateNotice'),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: Theme.of(context).colorScheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    estimate.requestedLocation != null
                        ? "We don't have reliable market data for ${estimate.requestedLocation} — "
                            'showing ${estimate.location} as the nearest reference point instead.'
                        : "We don't have reliable market data for this JD's location — showing "
                            '${estimate.location} as a reference point instead.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        if (estimate.hasMarketData)
          Card(
            key: const Key('marketDataCard'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Estimated market range', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Text(
                    '₹${_formatAmount(estimate.minSalary)} – ₹${_formatAmount(estimate.maxSalary)} '
                    '/ ${(estimate.period ?? 'year').toLowerCase()}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (estimate.medianSalary != null)
                    Text(
                      'Median: ₹${_formatAmount(estimate.medianSalary)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Real market data'
                    '${estimate.publisher != null ? ' via ${estimate.publisher}' : ''}'
                    '${estimate.confidence != null ? ' · confidence: ${estimate.confidence!.toLowerCase()}' : ''}.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          )
        else
          Card(
            key: const Key('noMarketDataCard'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No Indian-market salary data was found for this specific role and location.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        const SizedBox(height: 20),
        Text('Negotiation guidance', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(estimate.negotiationGuidance, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  String _formatAmount(num? amount) {
    if (amount == null) return '—';
    return amount.round().toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
        );
  }
}
