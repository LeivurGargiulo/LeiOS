import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../core/design/breakpoints.dart';
import '../../core/design/tokens.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/format.dart';
import '../../core/widgets/small_widgets.dart';
import '../../core/widgets/swipe_action_tile.dart';
import '../../domain/dates.dart';
import '../../domain/models.dart';
import '../../domain/mood.dart';
import '../../domain/streak.dart';
import '../../domain/tags.dart';
import '../../l10n/app_localizations.dart';
import 'habits_ui.dart';
import 'mood_ui.dart';
import 'today_screen.dart';

class ReviewTab extends ConsumerWidget {
  const ReviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feelings = ref.watch(feelingsProvider).asData?.value ?? const <Feeling>[];
    return CardColumns(
      children: [
        const _WeekCard(),
        _InsightsCard(feelings: feelings),
        _TrendCard(feelings: feelings),
        _HistoryCard(feelings: feelings),
      ],
    );
  }
}

// ---------------- Week grid ----------------

class _WeekCard extends ConsumerStatefulWidget {
  const _WeekCard();
  @override
  ConsumerState<_WeekCard> createState() => _WeekCardState();
}

class _WeekCardState extends ConsumerState<_WeekCard> {
  int _offset = 0;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final habits = ref.watch(habitsProvider).asData?.value ?? const <Habit>[];
    final completions = ref.watch(completionsProvider).asData?.value ?? const <HabitCompletion>[];
    final today = dateOnly(DateTime.now());
    final start = addDays(weekStart(today), _offset * 7);
    final days = [for (var i = 0; i < 7; i++) addDays(start, i)];
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final compact = context.isCompact;
    final label = '${DateFormat('d MMM').format(days.first)} – ${DateFormat('d MMM').format(days.last)}';

    return TonalCard(
      title: l.weekTitle,
      action: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(tooltip: l.weekPrevious, icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _offset--)),
        Text(_offset == 0 ? l.weekThis : label, style: tt.labelLarge),
        IconButton(tooltip: l.weekNext, icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => _offset++)),
      ]),
      child: habits.isEmpty
          ? Padding(padding: const EdgeInsets.all(Space.md), child: Text(l.weekEmpty))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    if (!compact) const Expanded(flex: 3, child: SizedBox()),
                    Expanded(
                      flex: compact ? 1 : 5,
                      child: Row(
                        children: [
                          for (final d in days)
                            Expanded(
                              child: Column(children: [
                                Text(DateFormat('E').format(d).substring(0, 1), style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                                Text('${d.day}', style: moneyStyle(tt.labelSmall)),
                              ]),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Space.sm),
                for (final h in habits) _weekRow(context, h, completions, days, today, compact),
              ],
            ),
    );
  }

  Widget _weekRow(BuildContext context, Habit h, List<HabitCompletion> all, List<DateTime> days, DateTime today, bool compact) {
    final tt = Theme.of(context).textTheme;
    final dates = datesFor(h.id, all);
    final info = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StreakChip(streak: streak(dates, today)),
        const SizedBox(width: Space.sm),
        Text('${weeklyCount(dates, today)}/${h.targetFrequency}', style: moneyStyle(tt.labelLarge)),
      ],
    );
    final cells = Row(children: [for (final d in days) Expanded(child: _Cell(habit: h, day: d, today: today, done: dates.contains(d)))]);
    if (compact) {
      return Padding(
        padding: const EdgeInsets.only(bottom: Space.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [Expanded(child: Text(h.name, style: tt.bodyLarge)), info]),
            cells,
          ],
        ),
      );
    }
    return Row(children: [
      Expanded(flex: 3, child: Text(h.name, style: tt.bodyLarge, overflow: TextOverflow.ellipsis)),
      Expanded(flex: 5, child: cells),
      const SizedBox(width: Space.sm),
      info,
    ]);
  }
}

class _Cell extends ConsumerWidget {
  const _Cell({required this.habit, required this.day, required this.today, required this.done});
  final Habit habit;
  final DateTime day;
  final DateTime today;
  final bool done;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context);
    final cs = Theme.of(context).colorScheme;
    final future = day.isAfter(today);
    final dayName = DateFormat('EEEE d').format(day);
    return Semantics(
      button: !future,
      enabled: !future,
      checked: done,
      label: done ? l.habitDayCompleted(dayName, habit.name) : l.habitDayNotCompleted(dayName, habit.name),
      excludeSemantics: true,
      child: InkResponse(
        onTap: future ? null : () => ref.read(habitsRepoProvider).toggle(habit.id, day),
        radius: 24,
        child: Center(
          child: SizedBox(
            height: 44,
            child: Center(
              child: AnimatedContainer(
                duration: Dur.short,
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? cs.primary : Colors.transparent,
                  border: Border.all(color: future ? cs.outlineVariant : (done ? cs.primary : cs.outline), width: 2),
                ),
                child: done
                    ? Icon(Icons.check, size: 18, color: cs.onPrimary)
                    : Icon(Icons.circle, size: 5, color: future ? cs.outlineVariant : cs.outline),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- Insights ----------------

class _InsightsCard extends StatelessWidget {
  const _InsightsCard({required this.feelings});
  final List<Feeling> feelings;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final today = dateOnly(DateTime.now());
    final avg = moodAverage(feelings);
    final bw = bestWorstWeekday(feelings);
    final tags = topTags(feelings.map((f) => f.tags));
    final s = streak({for (final f in feelings) dateOnly(f.date)}, today);
    final tiles = [
      StatTile(label: l.statAverage, value: avg == null ? '-' : avg.toStringAsFixed(1)),
      StatTile(label: l.statCurrentStreak, value: '$s', icon: Icons.local_fire_department, color: Theme.of(context).colorScheme.tertiary),
      StatTile(label: l.statTotalEntries, value: '${feelings.length}'),
      StatTile(label: l.statBestWeekday, value: bw.best ?? '-'),
      StatTile(label: l.statWorstWeekday, value: bw.worst ?? '-'),
    ];
    return TonalCard(
      title: l.moodInsights,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(builder: (context, c) {
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: Space.sm,
              crossAxisSpacing: Space.sm,
              childAspectRatio: c.maxWidth < 360 ? 1.7 : 2.2,
              children: tiles,
            );
          }),
          if (tags.isNotEmpty) ...[
            SectionHeader(l.topTags, padding: const EdgeInsets.only(top: Space.md, bottom: Space.xs)),
            Wrap(spacing: Space.sm, runSpacing: Space.xs, children: [for (final t in tags) Chip(label: Text('${t.label} · ${t.count}'))]),
          ],
        ],
      ),
    );
  }
}

// ---------------- Trend ----------------

class _TrendCard extends StatefulWidget {
  const _TrendCard({required this.feelings});
  final List<Feeling> feelings;
  @override
  State<_TrendCard> createState() => _TrendCardState();
}

class _TrendCardState extends State<_TrendCard> {
  bool _table = false;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final cs = Theme.of(context).colorScheme;
    final trend = moodTrend(widget.feelings, dateOnly(DateTime.now()));
    return TonalCard(
      title: l.moodTrend,
      action: TextButton(onPressed: () => setState(() => _table = !_table), child: Text(_table ? l.showChart : l.showTable)),
      child: widget.feelings.isEmpty
          ? EmptyState(icon: Icons.mood, title: l.emptyMoodTitle, message: l.emptyMoodMessage, seed: 5, compact: true)
          : _table
              ? Column(children: [
                  for (final p in trend.reversed.where((p) => p.rating != null))
                    ListTile(dense: true, title: Text(DateFormat('EEE d MMM').format(p.day)), trailing: Text('${p.rating}', style: moneyStyle(null))),
                ])
              : Semantics(
                  label: l.moodTrendSemantics,
                  child: SizedBox(
                    height: 180,
                    child: LineChart(
                      LineChartData(
                        minY: 1,
                        maxY: 5,
                        minX: 0,
                        maxX: 29,
                        gridData: FlGridData(
                          drawVerticalLine: false,
                          horizontalInterval: 1,
                          getDrawingHorizontalLine: (_) => FlLine(color: cs.outlineVariant, strokeWidth: 1),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(),
                          rightTitles: const AxisTitles(),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: true, interval: 1, reservedSize: 24, getTitlesWidget: (v, m) => Text('${v.toInt()}', style: Theme.of(context).textTheme.labelSmall)),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 7,
                              getTitlesWidget: (v, m) {
                                final i = v.toInt();
                                if (i < 0 || i > 29) return const SizedBox.shrink();
                                return Text(DateFormat('d MMM').format(trend[i].day), style: Theme.of(context).textTheme.labelSmall);
                              },
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: [for (var i = 0; i < trend.length; i++) trend[i].rating == null ? FlSpot.nullSpot : FlSpot(i.toDouble(), trend[i].rating!.toDouble())],
                            color: cs.primary,
                            barWidth: 3,
                            isCurved: false,
                            dotData: FlDotData(getDotPainter: (s, p, b, i) => FlDotCirclePainter(radius: 4, color: cs.primary, strokeWidth: 0)),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (spots) => [
                              for (final s in spots)
                                LineTooltipItem(
                                  '${DateFormat('d MMM').format(trend[s.x.toInt()].day)}: ${s.y.toInt()}',
                                  TextStyle(color: cs.onInverseSurface),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}

// ---------------- History ----------------

class _HistoryCard extends ConsumerWidget {
  const _HistoryCard({required this.feelings});
  final List<Feeling> feelings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = ref.watch(formatDateProvider);
    final repo = ref.read(feelingsRepoProvider);
    final l = L10n.of(context);
    final messenger = ScaffoldMessenger.of(context);
    return TonalCard(
      title: l.moodHistory,
      child: feelings.isEmpty
          ? EmptyState(icon: Icons.mood, title: l.emptyMoodTitle, message: l.emptyMoodMessage, seed: 6, compact: true)
          : Column(
              children: [
                for (final f in feelings)
                  SwipeActionTile(
                    key: ValueKey('feel-${f.id}'),
                    onSwipeLeft: () async {
                      await repo.delete(f.id);
                      showUndoSnackOn(messenger, l.entityDeleted(l.entityEntry), undoLabel: l.undo, onUndo: () => repo.restore(f));
                    },
                    menuItems: [
                      TileMenuItem(label: l.edit, icon: Icons.edit_outlined, onTap: () => showMoodSheet(context, date: f.date)),
                      TileMenuItem(
                        label: l.delete,
                        icon: Icons.delete_outline,
                        destructive: true,
                        onTap: () async {
                          await repo.delete(f.id);
                          showUndoSnackOn(messenger, l.entityDeleted(l.entityEntry), undoLabel: l.undo, onUndo: () => repo.restore(f));
                        },
                      ),
                    ],
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Semantics(label: l.moodRatingOf(f.rating), child: Icon(moodIcon(f.rating))),
                      title: Text(fmt(f.date)),
                      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        if (f.notes.isNotEmpty) Text(f.notes, maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (f.tags.isNotEmpty) Wrap(spacing: Space.xs, children: [for (final t in splitTags(f.tags)) Chip(label: Text(t), visualDensity: VisualDensity.compact)]),
                      ]),
                      onTap: () => showMoodSheet(context, date: f.date),
                    ),
                  ),
              ],
            ),
    );
  }
}
