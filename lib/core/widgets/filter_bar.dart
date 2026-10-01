import 'package:flutter/material.dart';

import '../design/tokens.dart';

/// Single-choice chip row (filters). Values are owned by the caller.
class ChipFilterRow<T> extends StatelessWidget {
  const ChipFilterRow({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.xs),
  });

  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          for (final v in values)
            Padding(
              padding: const EdgeInsets.only(right: Space.sm),
              child: FilterChip(
                label: Text(labelOf(v)),
                selected: v == selected,
                onSelected: (_) => onSelected(v),
              ),
            ),
        ],
      ),
    );
  }
}

/// `SegmentedButton` filter for small, mutually exclusive option sets.
class SegmentFilter<T> extends StatelessWidget {
  const SegmentFilter({super.key, required this.values, required this.selected, required this.labelOf, required this.onSelected});
  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<T>(
      showSelectedIcon: false,
      segments: [for (final v in values) ButtonSegment(value: v, label: Text(labelOf(v)))],
      selected: {selected},
      onSelectionChanged: (s) => onSelected(s.first),
    );
  }
}
