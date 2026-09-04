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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _CompensationEducationSection(),
            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 20),
            if (!hasJdText)
              _buildNoJdCard(context)
            else if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, textAlign: TextAlign.center),
              )
            else if (_estimate != null)
              _buildResult(context, _estimate!),
          ],
        ),
      ),
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
              'Run JD Match against a job description for role-specific market-salary guidance.',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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

/// Plain-language orientation on how service and corporate compensation
/// actually compare — deliberately has no rupee figures or formulas of its
/// own. Anything numeric belongs in the Financial & Cost-of-Living
/// Calculator, where the officer enters their own real figures; this
/// section only explains what to look for and why, so it never goes
/// stale.
class _CompensationEducationSection extends StatelessWidget {
  const _CompensationEducationSection();

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium;
    final bodyStyle = Theme.of(context).textTheme.bodyMedium;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reading a corporate offer', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Text(
          "A corporate CTC letter and your service pay slip aren't measuring the same thing. "
          'Before comparing headline numbers, account for three things a CTC figure hides.',
          style: bodyStyle,
        ),
        const SizedBox(height: 20),
        const _EducationCard(
          title: 'What you have now that never shows as cash',
          body: "Subsidised or free accommodation, ECHS medical cover, CSD purchases, children's "
              "school fee concessions — none of this appears in your pay slip's monthly figure, but "
              "losing it is a real cost. Use the calculator below to put a number on what you'd have "
              'to spend to replace it.',
        ),
        const SizedBox(height: 12),
        const _EducationCard(
          title: "What's deferred, not current",
          body: 'Pension and retirement gratuity are real and valuable, but they are not part of your '
              "current spending power, and a corporate offer doesn't need to replace them — they "
              "continue regardless of what you do next. Don't let a recruiter's bigger headline "
              'number distract from comparing like with like: current economic value against current '
              'economic value.',
        ),
        const SizedBox(height: 12),
        const _EducationCard(
          title: 'What the move itself will cost you',
          body: 'A posting in a metro usually means market-rate rent, private schooling, and private '
              'health cover — costs service life may have shielded you from. A bigger salary in a '
              'costlier city can be a pay cut in real terms once you net these out.',
        ),
        const SizedBox(height: 24),
        Text('Negotiating the offer', style: titleStyle),
        const SizedBox(height: 8),
        Text(
          '• Ask for the CTC breakup in writing — fixed, variable, and benefits as separate lines, '
          'not one headline number. Variable pay is a target, not a promise.\n'
          '• Negotiate the fixed component first. If it falls short of your break-even number, a '
          "larger bonus or ESOP grant doesn't close that gap — treat it as upside on top, not a fix.\n"
          '• Ask for what service life gave you by default and a corporate offer usually has to be '
          'asked for: a relocation or joining allowance, and a health cover that matches your '
          "family's current access.\n"
          '• Know your own floor before the call. Run your numbers in the calculator below and use '
          "the break-even figure as your minimum, not the recruiter's opening offer.",
          style: bodyStyle,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            key: const Key('goToFinancialPlannerButton'),
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.financialPlanner),
            child: const Text('Run your own numbers in the calculator'),
          ),
        ),
      ],
    );
  }
}

class _EducationCard extends StatelessWidget {
  const _EducationCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(body, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
