import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/officer_profile.dart';
import '../../core/services/profile_repository.dart';
import '../../core/widgets/home_button.dart';
import '../career_handbook/career_handbook_detail_screen.dart';
import '../career_paths/career_vertical.dart';
import '../career_paths/corps_affinity.dart';
import '../career_paths/corps_vertical_fit_matrix.dart';
import '../onboarding/corps_options.dart';

/// A ready-reckoner: pick a Corps/Arm/Branch to see which of the 34
/// verticals it fits best, or flip it around and pick a vertical to see
/// which Corps/Arm/Branches fit it best. Read alongside the Career Vertical
/// Handbook — this narrows down what's worth reading in depth, it doesn't
/// replace reading it.
class CorpsMatrixScreen extends StatefulWidget {
  const CorpsMatrixScreen({super.key});

  @override
  State<CorpsMatrixScreen> createState() => _CorpsMatrixScreenState();
}

class _CorpsMatrixScreenState extends State<CorpsMatrixScreen> {
  bool _byVertical = false;
  String? _selectedCorps;
  CareerVertical? _selectedVertical;

  @override
  void initState() {
    super.initState();
    _selectedCorps = context.read<ProfileRepository>().profile?.corpsOrArm;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Corps/Arm/Branch Fit Matrix'),
        actions: [
          IconButton(
            key: const Key('toggleMatrixDirectionButton'),
            icon: const Icon(Icons.swap_horiz),
            tooltip: _byVertical ? 'Browse by Corps/Arm/Branch' : 'Browse by vertical',
            onPressed: () => setState(() => _byVertical = !_byVertical),
          ),
          const HomeButton(),
        ],
      ),
      body: _byVertical ? _buildByVertical(context) : _buildByCorps(context),
    );
  }

  Widget _buildByCorps(BuildContext context) {
    if (_selectedCorps == null) {
      return _CorpsPicker(onSelected: (c) => setState(() => _selectedCorps = c));
    }
    return _TierResults(
      key: ValueKey('corpsResults_$_selectedCorps'),
      headerLabel: _selectedCorps!,
      onChange: () => setState(() => _selectedCorps = null),
      entries: kAllBrowsableVerticals
          .map((v) => MapEntry(v.name, corpsVerticalFitTier(_selectedCorps!, v.name)))
          .toList(),
      onTapEntry: (verticalName) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CareerHandbookDetailScreen(
            vertical: kAllBrowsableVerticals.firstWhere((v) => v.name == verticalName),
          ),
        ),
      ),
    );
  }

  Widget _buildByVertical(BuildContext context) {
    if (_selectedVertical == null) {
      return _VerticalPicker(onSelected: (v) => setState(() => _selectedVertical = v));
    }
    final vertical = _selectedVertical!;
    final rows = kCorpsByService.values.expand((list) => list).toSet();
    return _TierResults(
      key: ValueKey('verticalResults_${vertical.name}'),
      headerLabel: vertical.name,
      onChange: () => setState(() => _selectedVertical = null),
      entries: rows.map((corps) => MapEntry(corps, corpsVerticalFitTier(corps, vertical.name))).toList(),
      onTapEntry: null,
    );
  }
}

class _CorpsPicker extends StatelessWidget {
  const _CorpsPicker({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 12, 24, 4),
          child: Text('Pick your Corps/Arm/Branch to see how it fits each of the 34 verticals.'),
        ),
        for (final service in OfficerService.values) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
            child: Text(service.label, style: Theme.of(context).textTheme.titleSmall),
          ),
          for (final corps in kCorpsByService[service]!)
            ListTile(
              key: Key('pickCorps_$corps'),
              title: Text(corps),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onSelected(corps),
            ),
        ],
      ],
    );
  }
}

class _VerticalPicker extends StatelessWidget {
  const _VerticalPicker({required this.onSelected});

  final ValueChanged<CareerVertical> onSelected;

  @override
  Widget build(BuildContext context) {
    final byCategory = <String, List<CareerVertical>>{};
    for (final v in kAllBrowsableVerticals) {
      byCategory.putIfAbsent(v.category, () => []).add(v);
    }
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 12, 24, 4),
          child: Text('Pick a vertical to see which Corps/Arm/Branches fit it best.'),
        ),
        for (final category in byCategory.keys) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
            child: Text(category, style: Theme.of(context).textTheme.titleSmall),
          ),
          for (final vertical in byCategory[category]!)
            ListTile(
              key: Key('pickVertical_${vertical.name}'),
              title: Text(vertical.name),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onSelected(vertical),
            ),
        ],
      ],
    );
  }
}

/// Shared results layout for both directions — a header with a "Change"
/// action, then every entry grouped under Strong/Possible/Limited fit.
/// Restricted entries (the medical/JAG hard gate) are omitted entirely
/// rather than shown as a wall of "Restricted" — they're not useful noise
/// in a ready-reckoner meant to narrow down what's worth exploring.
class _TierResults extends StatelessWidget {
  const _TierResults({
    super.key,
    required this.headerLabel,
    required this.onChange,
    required this.entries,
    required this.onTapEntry,
  });

  final String headerLabel;
  final VoidCallback onChange;
  final List<MapEntry<String, CorpsVerticalFitTier>> entries;
  final ValueChanged<String>? onTapEntry;

  @override
  Widget build(BuildContext context) {
    final tiers = [CorpsVerticalFitTier.strong, CorpsVerticalFitTier.possible, CorpsVerticalFitTier.limited];
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
          child: Row(
            children: [
              Expanded(child: Text(headerLabel, style: Theme.of(context).textTheme.titleMedium)),
              TextButton(
                key: const Key('changeMatrixSelectionButton'),
                onPressed: onChange,
                child: const Text('Change'),
              ),
            ],
          ),
        ),
        for (final tier in tiers) ...[
          if (entries.any((e) => e.value == tier)) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
              child: Text(tier.label, style: Theme.of(context).textTheme.titleSmall),
            ),
            for (final entry in entries.where((e) => e.value == tier))
              ListTile(
                key: Key('matrixEntry_${entry.key}'),
                title: Text(entry.key),
                trailing: onTapEntry == null ? null : const Icon(Icons.chevron_right),
                onTap: onTapEntry == null ? null : () => onTapEntry!(entry.key),
              ),
          ],
        ],
      ],
    );
  }
}
