import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/dates.dart';
import '../../domain/goals.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import '../design/tokens.dart';
import 'filter_bar.dart';
import 'format.dart';

/// Month selector `◀ March 2027 ▶` (Finances).
class MonthSelector extends StatelessWidget {
  const MonthSelector({super.key, required this.month, required this.onChanged});
  final DateTime month;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: l.previousMonth,
          icon: const Icon(Icons.chevron_left),
          onPressed: () => onChanged(DateTime(month.year, month.month - 1, 1)),
        ),
        Flexible(
          child: Semantics(
            liveRegion: true,
            child: Text(monthYear(month), style: Theme.of(context).textTheme.titleMedium, overflow: TextOverflow.ellipsis, maxLines: 1),
          ),
        ),
        IconButton(
          tooltip: l.nextMonth,
          icon: const Icon(Icons.chevron_right),
          onPressed: () => onChanged(DateTime(month.year, month.month + 1, 1)),
        ),
      ],
    );
  }
}

class _YearStepper extends StatelessWidget {
  const _YearStepper({required this.year, required this.onChanged});
  final int year;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(tooltip: L10n.of(context).previousYear, icon: const Icon(Icons.chevron_left), onPressed: () => onChanged(year - 1)),
          Text('$year', style: Theme.of(context).textTheme.titleMedium),
          IconButton(tooltip: L10n.of(context).nextYear, icon: const Icon(Icons.chevron_right), onPressed: () => onChanged(year + 1)),
        ],
      );
}

/// Goal target picker: precision (Day · Month · Quarter · Year) then the period (spec §10.4).
/// A null [date] means "no target".
class PeriodPicker extends StatelessWidget {
  const PeriodPicker({
    super.key,
    required this.date,
    required this.precision,
    required this.onChanged,
    required this.format,
  });

  final DateTime? date;
  final GoalPrecision? precision;
  final void Function(DateTime? date, GoalPrecision? precision) onChanged;
  final String Function(DateTime) format;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final p = precision;
    final d = date ?? DateTime.now();
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ChoiceChip(
              label: Text(l.none),
              selected: p == null,
              onSelected: (_) => onChanged(null, null),
            ),
            SegmentFilter<GoalPrecision>(
              values: GoalPrecision.values,
              selected: p ?? GoalPrecision.month,
              labelOf: (v) => switch (v) {
                GoalPrecision.day => l.precisionDay,
                GoalPrecision.month => l.precisionMonth,
                GoalPrecision.quarter => l.precisionQuarter,
                GoalPrecision.year => l.precisionYear,
              },
              onSelected: (v) => onChanged(periodStart(date ?? dateOnly(DateTime.now()), v), v),
            ),
          ],
        ),
        if (p != null) ...[
          const SizedBox(height: Space.md),
          switch (p) {
            GoalPrecision.day => OutlinedButton.icon(
                icon: const Icon(Icons.event),
                label: Text(format(d)),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: d,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) onChanged(dateOnly(picked), p);
                },
              ),
            GoalPrecision.month => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _YearStepper(year: d.year, onChanged: (y) => onChanged(DateTime(y, d.month, 1), p)),
                  Wrap(spacing: Space.sm, runSpacing: Space.sm, children: [
                    for (var m = 1; m <= 12; m++)
                      ChoiceChip(
                        label: Text(DateFormat.MMM().format(DateTime(2000, m))),
                        selected: d.month == m,
                        onSelected: (_) => onChanged(DateTime(d.year, m, 1), p),
                      ),
                  ]),
                ],
              ),
            GoalPrecision.quarter => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _YearStepper(year: d.year, onChanged: (y) => onChanged(DateTime(y, d.month, 1), p)),
                  Wrap(spacing: Space.sm, children: [
                    for (var q = 0; q < 4; q++)
                      ChoiceChip(
                        label: Text(l.quarterShort(q + 1)),
                        selected: quarterOf(periodStart(d, p)) == q,
                        onSelected: (_) => onChanged(DateTime(d.year, q * 3 + 1, 1), p),
                      ),
                  ]),
                ],
              ),
            GoalPrecision.year => _YearStepper(year: d.year, onChanged: (y) => onChanged(DateTime(y, 1, 1), p)),
          },
          const SizedBox(height: Space.sm),
          Text(l.targetPeriod(periodLabel(d, p, format)), style: tt.bodyMedium),
        ],
      ],
    );
  }
}
