import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/guide_section.dart';
import '../../core/routing/app_routes.dart';
import '../../core/services/profile_repository.dart';
import '../../core/widgets/analysis_loading_indicator.dart';
import '../../core/widgets/home_button.dart';
import 'compensation_estimate.dart';
import 'compensation_guidance_sections.dart';
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
      if (estimate.hasMarketData) repository.saveCompensationEstimate(estimate);
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
      appBar: AppBar(
        title: const Text('Compensation Guidance'),
        actions: const [HomeButton()],
      ),
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
              const Center(
                child: AnalysisLoadingIndicator(
                  messages: [
                    'Reading the job description...',
                    'Finding comparable India-market compensation data...',
                    'Working out where your military package stands against it...',
                  ],
                ),
              )
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
/// actually compare — deliberately has no rupee figures of its own beyond
/// clearly-labelled illustrative examples. Every real number the officer
/// needs comes from the Financial & Cost-of-Living Calculator below, where
/// they enter their own figures. Content lives in
/// compensation_guidance_sections.dart, one collapsible section at a time
/// so this doesn't turn into an unreadable single scroll.
class _CompensationEducationSection extends StatelessWidget {
  const _CompensationEducationSection();

  @override
  Widget build(BuildContext context) {
    final bodyStyle = Theme.of(context).textTheme.bodyMedium;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reading a corporate offer', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Text(
          'A practical guide to deconstructing any corporate offer, understanding what its '
          'components actually mean, and comparing it fairly against your military compensation — '
          'tap a topic to expand it.',
          style: bodyStyle,
        ),
        const SizedBox(height: 16),
        for (final section in kCompensationGuidanceSections)
          _GuidanceSectionTile(key: ValueKey(section.title), section: section),
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

class _GuidanceSectionTile extends StatelessWidget {
  const _GuidanceSectionTile({super.key, required this.section});

  final GuideSection section;

  @override
  Widget build(BuildContext context) {
    final bodyStyle = Theme.of(context).textTheme.bodyMedium;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        key: ValueKey('compensationSection_${section.title}'),
        title: Text(section.title, style: Theme.of(context).textTheme.titleSmall),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final paragraph in section.paragraphs) ...[
            Text(paragraph, style: bodyStyle),
            const SizedBox(height: 12),
          ],
          if (section.referenceTable != null) ...[
            _GuidanceTable(table: section.referenceTable!),
            const SizedBox(height: 8),
          ],
          if (section.checklistItems.isNotEmpty) ...[
            for (final item in section.checklistItems)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline, size: 18, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item, style: bodyStyle)),
                  ],
                ),
              ),
            const SizedBox(height: 4),
          ],
          if (section.closingNote != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                section.closingNote!,
                style: bodyStyle?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }
}

class _GuidanceTable extends StatelessWidget {
  const _GuidanceTable({required this.table});

  final GuideReferenceTable table;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(colorScheme.surfaceContainerHighest),
        columns: [
          for (final header in table.columnHeaders)
            DataColumn(label: Text(header, style: Theme.of(context).textTheme.labelLarge)),
        ],
        rows: [
          for (final row in table.rows)
            DataRow(cells: [for (final cell in row) DataCell(SizedBox(width: 200, child: Text(cell)))]),
        ],
      ),
    );
  }
}
