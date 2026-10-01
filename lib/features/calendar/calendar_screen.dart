import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/screen_scaffold.dart';
import '../../core/design/breakpoints.dart';
import '../../core/design/motion.dart';
import '../../core/design/tokens.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/entity_editor.dart';
import '../../core/widgets/format.dart';
import '../../core/widgets/master_detail_scaffold.dart';
import '../../core/widgets/small_widgets.dart';
import '../../core/widgets/tabbed_screen.dart';
import '../../domain/dates.dart';
import '../../domain/events.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import '../tasks/task_form.dart';
import '../tasks/task_tile.dart';
import 'event_form.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key, this.date, this.eventId});

  /// `YYYY-MM-DD` from the route.
  final String? date;
  final String? eventId;

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _selected = widget.date != null ? parseIsoDate(widget.date!) : dateOnly(DateTime.now());
  late DateTime _month = DateTime(_selected.year, _selected.month, 1);
  bool _reverse = false;

  @override
  void didUpdateWidget(CalendarScreen old) {
    super.didUpdateWidget(old);
    if (widget.date != null && widget.date != old.date) {
      final d = parseIsoDate(widget.date!);
      _selected = d;
      _month = DateTime(d.year, d.month, 1);
    }
  }

  void _shiftMonth(int delta) => setState(() {
        _reverse = delta < 0;
        _month = DateTime(_month.year, _month.month + delta, 1);
      });

  void _selectDay(DateTime d) {
    if (context.isExpanded) {
      context.go('/calendar/${isoDate(d)}');
    } else {
      setState(() {
        _selected = d;
        if (d.month != _month.month || d.year != _month.year) _month = DateTime(d.year, d.month, 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return ScreenScaffold(
      title: l.navCalendar,
      fab: FabSpec(tooltip: l.emptyDayAction, onPressed: () => openEvent(context, day: _selected)),
      body: TabbedScreen(
        prefKey: 'calendar',
        tabs: [
          TabSpec(label: 'Month', builder: (_) => _monthTab(context)),
          TabSpec(label: 'Agenda', builder: (_) => const _Agenda()),
        ],
      ),
    );
  }

  Widget _monthTab(BuildContext context) {
    final events = ref.watch(eventsProvider).asData?.value ?? const <Event>[];
    final tasks = ref.watch(tasksProvider).asData?.value ?? const <Task>[];
    final eventId = widget.eventId;
    final expanded = context.isExpanded;

    final grid = _MonthGrid(
      month: _month,
      selected: _selected,
      events: events,
      tasks: tasks,
      reverse: _reverse,
      onShift: _shiftMonth,
      onSelect: _selectDay,
      onToday: () {
        final t = dateOnly(DateTime.now());
        _selectDay(t);
        setState(() => _month = DateTime(t.year, t.month, 1));
      },
      trailing: expanded ? NewButton(onPressed: () => context.go('/calendar/${isoDate(_selected)}/new'), label: 'New event') : null,
    );

    final dayPanel = _DayPanel(day: _selected, events: events, tasks: tasks, shrink: !expanded);

    if (!expanded) {
      return ListView(padding: const EdgeInsets.only(bottom: kListBottomPadding), children: [grid, const Divider(), dayPanel]);
    }

    return MasterDetailScaffold<Event>(
      master: SingleChildScrollView(child: grid),
      detail: eventId != null
          ? EventForm(
              key: ValueKey('event-form-$eventId-${isoDate(_selected)}'),
              eventId: eventId == 'new' ? null : eventId,
              initialDate: _selected,
              presentation: EditorPresentation.inline,
              onClosed: () => context.go('/calendar/${isoDate(_selected)}'),
            )
          : dayPanel,
      itemIds: [for (final e in events) e.id],
      selectedId: eventId,
      dataLoaded: true,
      onSelectionCleared: () => context.go('/calendar/${isoDate(_selected)}'),
      onCreate: () => context.go('/calendar/${isoDate(_selected)}/new'),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selected,
    required this.events,
    required this.tasks,
    required this.reverse,
    required this.onShift,
    required this.onSelect,
    required this.onToday,
    this.trailing,
  });

  final DateTime month;
  final DateTime selected;
  final List<Event> events;
  final List<Task> tasks;
  final bool reverse;
  final ValueChanged<int> onShift;
  final ValueChanged<DateTime> onSelect;
  final VoidCallback onToday;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final days = monthGrid(month.year, month.month);
    final today = dateOnly(DateTime.now());
    final pendingDue = {
      for (final t in tasks)
        if (t.status != TaskStatus.done && t.dueDate != null) dateOnly(t.dueDate!),
    };
    return GestureDetector(
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v < -300) onShift(1);
        if (v > 300) onShift(-1);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.sm),
            child: Row(children: [
              IconButton(tooltip: 'Previous month', icon: const Icon(Icons.chevron_left), onPressed: () => onShift(-1)),
              Expanded(
                child: Center(child: Semantics(liveRegion: true, child: Text(monthYear(month), style: tt.titleMedium, overflow: TextOverflow.ellipsis, maxLines: 1))),
              ),
              IconButton(tooltip: 'Next month', icon: const Icon(Icons.chevron_right), onPressed: () => onShift(1)),
              TextButton(onPressed: onToday, child: const Text('Today')),
            ]),
          ),
          if (trailing != null) Padding(padding: const EdgeInsets.only(right: Space.md), child: Align(alignment: Alignment.centerRight, child: trailing)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.sm),
            child: Row(children: [
              for (final d in const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'])
                Expanded(child: Center(child: Text(d, style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)))),
            ]),
          ),
          PageTransitionSwitcher(
            duration: motionDuration(context, Dur.medium),
            reverse: reverse,
            transitionBuilder: (child, a, b) => SharedAxisTransition(
              animation: a,
              secondaryAnimation: b,
              transitionType: SharedAxisTransitionType.horizontal,
              fillColor: Colors.transparent,
              child: child,
            ),
            child: Padding(
              key: ValueKey('${month.year}-${month.month}'),
              padding: const EdgeInsets.symmetric(horizontal: Space.sm),
              child: Column(children: [
                for (var w = 0; w < 6; w++)
                  Row(children: [
                    for (var i = 0; i < 7; i++)
                      Expanded(
                        child: _DayCell(
                          day: days[w * 7 + i],
                          inMonth: days[w * 7 + i].month == month.month,
                          isToday: sameDay(days[w * 7 + i], today),
                          isSelected: sameDay(days[w * 7 + i], selected),
                          eventCount: eventsOn(events, days[w * 7 + i]).length,
                          hasTasks: pendingDue.contains(days[w * 7 + i]),
                          onTap: () => onSelect(days[w * 7 + i]),
                        ),
                      ),
                  ]),
              ]),
            ),
          ),
          const SizedBox(height: Space.sm),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.inMonth,
    required this.isToday,
    required this.isSelected,
    required this.eventCount,
    required this.hasTasks,
    required this.onTap,
  });
  final DateTime day;
  final bool inMonth;
  final bool isToday;
  final bool isSelected;
  final int eventCount;
  final bool hasTasks;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final textColor = isToday ? cs.onPrimary : (inMonth ? cs.onSurface : cs.onSurfaceVariant.withValues(alpha: 0.5));
    final label = '${DateFormat('EEEE d').format(day)}${eventCount > 0 ? ', $eventCount events' : ''}${hasTasks ? ', tasks due' : ''}';
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(color: isSelected ? cs.secondaryContainer : null, borderRadius: BorderRadius.circular(12)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: isToday ? BoxDecoration(color: cs.primary, shape: BoxShape.circle) : null,
                child: Text('${day.day}', style: moneyStyle(tt.labelLarge?.copyWith(color: textColor))),
              ),
              SizedBox(
                height: 8,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (var i = 0; i < (eventCount > 3 ? 3 : eventCount); i++)
                    Container(width: 4, height: 4, margin: const EdgeInsets.symmetric(horizontal: 1), decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle)),
                  if (eventCount > 3) Text('+${eventCount - 3}', style: tt.labelSmall?.copyWith(fontSize: 8)),
                  if (hasTasks)
                    Container(width: 6, height: 6, margin: const EdgeInsets.only(left: 2), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: cs.tertiary, width: 1.5))),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayPanel extends ConsumerWidget {
  const _DayPanel({required this.day, required this.events, required this.tasks, this.shrink = false});

  /// Non-scrolling column (used inside another scroll view).
  final bool shrink;
  final DateTime day;
  final List<Event> events;
  final List<Task> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context);
    final fmt = ref.watch(formatDateProvider);
    final dayEvents = eventsOn(events, day);
    final dayTasks = tasks.where((t) => t.status != TaskStatus.done && t.dueDate != null && sameDay(t.dueDate!, day)).toList();
    if (dayEvents.isEmpty && dayTasks.isEmpty) {
      return EmptyState(icon: Icons.event_available, title: l.emptyDayTitle, message: l.emptyDayMessage, actionLabel: l.emptyDayAction, onAction: () => openEvent(context, day: day), seed: 40);
    }
    final children = [
      SectionHeader(longDate(day)),
      for (final e in dayEvents) EventTile(event: e, day: day, onTap: () => openEvent(context, id: e.id, day: day)),
      if (dayTasks.isNotEmpty) ...[
        const SectionHeader('Tasks due'),
        for (final t in dayTasks) TaskTile(task: t, onTap: () => openTask(context, id: t.id)),
      ],
      const SizedBox(height: Space.sm),
      Padding(padding: const EdgeInsets.symmetric(horizontal: Space.lg), child: Text(fmt(day), style: Theme.of(context).textTheme.labelSmall)),
    ];
    if (shrink) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
    return ListView(padding: const EdgeInsets.only(bottom: kListBottomPadding), children: children);
  }
}

class EventTile extends StatelessWidget {
  const EventTile({super.key, required this.event, required this.day, required this.onTap});
  final Event event;
  final DateTime day;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final time = event.allDay
        ? 'All day'
        : event.endMinutes == null
            ? formatTimeOfDayMinutes(context, event.startMinutes!)
            : '${formatTimeOfDayMinutes(context, event.startMinutes!)} – ${formatTimeOfDayMinutes(context, event.endMinutes!)}';
    return ListTile(
      leading: Container(width: 4, height: 40, decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(2))),
      title: Text(event.title),
      subtitle: Text(time),
      trailing: event.recurring ? const Icon(Icons.repeat, size: 18, semanticLabel: 'Repeats weekly') : null,
      onTap: onTap,
    );
  }
}

class _Agenda extends ConsumerWidget {
  const _Agenda();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context);
    final events = ref.watch(eventsProvider).asData?.value ?? const <Event>[];
    final tasks = ref.watch(tasksProvider).asData?.value ?? const <Task>[];
    final cs = Theme.of(context).colorScheme;
    final today = dateOnly(DateTime.now());
    final slivers = <Widget>[];
    for (var i = 0; i < 30; i++) {
      final d = addDays(today, i);
      final dayEvents = eventsOn(events, d);
      final dayTasks = tasks.where((t) => t.status != TaskStatus.done && t.dueDate != null && sameDay(t.dueDate!, d)).toList();
      if (dayEvents.isEmpty && dayTasks.isEmpty) continue;
      slivers.add(SliverMainAxisGroup(slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _DayHeader(label: longDate(d), highlight: i == 0, color: cs),
        ),
        SliverList.list(children: [
          for (final e in dayEvents) EventTile(event: e, day: d, onTap: () => openEvent(context, id: e.id, day: d)),
          for (final t in dayTasks) TaskTile(task: t, onTap: () => openTask(context, id: t.id)),
        ]),
      ]));
    }
    if (slivers.isEmpty) {
      return EmptyState(icon: Icons.event_available, title: l.emptyDayTitle, message: l.emptyDayMessage, actionLabel: l.emptyDayAction, onAction: () => openEvent(context), seed: 41);
    }
    return CustomScrollView(slivers: [...slivers, const SliverToBoxAdapter(child: SizedBox(height: kListBottomPadding))]);
  }
}

class _DayHeader extends SliverPersistentHeaderDelegate {
  _DayHeader({required this.label, required this.highlight, required this.color});
  final String label;
  final bool highlight;
  final ColorScheme color;

  @override
  double get minExtent => 40;
  @override
  double get maxExtent => 40;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: color.surface,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: Space.lg),
      child: Semantics(
        header: true,
        child: Text(
          highlight ? 'Today · $label' : label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: highlight ? color.primary : color.onSurfaceVariant),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_DayHeader old) => old.label != label || old.highlight != highlight;
}
