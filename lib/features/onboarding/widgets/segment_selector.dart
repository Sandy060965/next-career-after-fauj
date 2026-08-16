import 'package:flutter/material.dart';

import '../../../core/models/officer_profile.dart';

class SegmentSelector extends StatelessWidget {
  const SegmentSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final OfficerSegment? selected;
  final ValueChanged<OfficerSegment> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: OfficerSegment.values.map((segment) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _SegmentCard(
            key: ValueKey('segment_${segment.name}'),
            segment: segment,
            isSelected: segment == selected,
            onTap: () => onChanged(segment),
          ),
        );
      }).toList(),
    );
  }
}

class _SegmentCard extends StatelessWidget {
  const _SegmentCard({
    required super.key,
    required this.segment,
    required this.isSelected,
    required this.onTap,
  });

  final OfficerSegment segment;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? colorScheme.primaryContainer.withValues(alpha: 0.4) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              segment.shortLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? colorScheme.primary : null,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              segment.fullLabel,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
