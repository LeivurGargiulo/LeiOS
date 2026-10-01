import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/screen_scaffold.dart';
import '../../core/design/breakpoints.dart';
import '../../core/design/tokens.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/entity_editor.dart';
import '../../core/widgets/filter_bar.dart';
import '../../core/widgets/format.dart';
import '../../core/widgets/master_detail_scaffold.dart';
import '../../core/widgets/small_widgets.dart';
import '../../domain/goals.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import 'goal_form.dart';

enum _GoalView { list, byPeriod }

enum _GoalFilter { pending, active, completed, all }

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key, this.selectedId});
  final String? selectedId;

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  _GoalFilter _filter = _GoalFilter.all;
  int _year = DateTime.now().year;

  _GoalView get _view => ref.watch(prefProvider('goals_view')) == 'byPeriod' ? _GoalView.byPeriod : _GoalView.list;

  bool _matches(Goal g) => switch (_filter) {
        _GoalFilter.all => true,
        _GoalFilter.pending => g.status == GoalStatus.pending,
        _GoalFilter.active => g.status == GoalStatus.active,
        _GoalFilter.completed => g.status == GoalStatus.completed,
      };

  int _order(Goal a, Goal b) {
    int rank(Goal g) => switch (g.status) { GoalStatus.active => 0, GoalStatus.pending => 1, GoalStatus.completed => 2 };
    final c = rank(a).compareTo(rank(b));
    if (c != 0) return c;
    if (a.targetDate != null && b.targetDate != null) return a.targetDate!.compareTo(b.targetDate!);
    if (a.targetDate != null) return -1;
    if (b.targetDate != null) return 1;
    return a.createdAt.compareTo(b.createdAt);
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final async = ref.watch(goalsProvider);
    final goals = async.asData?.value ?? const <Goal>[];
    final steps = ref.watch(goalStepsProvider).asData?.value ?? const <GoalStep>[];
    final fmt = ref.watch(formatDateProvider);
    final selectedId = widget.selectedId;
    final view = _view;
    final shown = goals.where(_matches).toList()..sort(_order);

    Widget row(Goal g) => _GoalTile(goal: g, steps: steps.where((s) => s.goalId == g.id).toList(), fmt: fmt, selected: g.id == selectedId);

    final master = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Expanded(
            child: ChipFilterRow<_GoalFilter>(
              values: _GoalFilter.values,
              selected: _filter,
              labelOf: (f) => switch (f) { _GoalFilter.pending => 'Pending', _GoalFilter.active => 'Active', _GoalFilter.completed => 'Completed', _GoalFilter.all => 'All' },
              onSelected: (f) => setState(() => _filter = f),
            ),
          ),
          if (context.isExpanded) Padding(padding: const EdgeInsets.only(right: Space.sm), child: NewButton(onPressed: () => context.go('/goals/new'))),
        ]),
        Expanded(
          child: async.isLoading && !async.hasValue
              ? const Center(child: CircularProgressIndicator())
              : goals.isEmpty
                  ? EmptyState(icon: Icons.flag, title: l.emptyGoalsTitle, message: l.emptyGoalsMessage, actionLabel: l.emptyGoalsAction, onAction: () => openGoal(context), seed: 30)
                  : view == _GoalView.list
                      ? ListView.separated(
                          padding: const EdgeInsets.only(bottom: kListBottomPadding),
                          itemCount: shown.length,
                          separatorBuilder: (_, _) => const Divider(indent: Space.lg),
                          itemBuilder: (_, i) => row(shown[i]),
                        )
                      : _byPeriod(context, goals.where(_matches).toList(), row),
        ),
      ],
    );

    return ScreenScaffold(
      title: l.navGoals,
      actions: [
        SegmentedButton<_GoalView>(
          showSelectedIcon: false,
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
          segments: const [
            ButtonSegment(value: _GoalView.list, icon: Icon(Icons.view_list), tooltip: 'List'),
            ButtonSegment(value: _GoalView.byPeriod, icon: Icon(Icons.calendar_view_month), tooltip: 'By period'),
          ],
          selected: {view},
          onSelectionChanged: (s) => ref.read(prefProvider('goals_view').notifier).set(s.first == _GoalView.byPeriod ? 'byPeriod' : 'list'),
        ),
      ],
      fab: FabSpec(tooltip: l.emptyGoalsAction, onPressed: () => openGoal(context)),
      body: MasterDetailScaffold<Goal>(
        master: master,
        detail: selectedId == null
            ? null
            : GoalForm(key: ValueKey('goal-form-$selectedId'), goalId: selectedId == 'new' ? null : selectedId, presentation: EditorPresentation.inline, onClosed: () => context.go('/goals')),
        itemIds: [for (final g in goals) g.id],
        selectedId: selectedId,
        dataLoaded: async.hasValue,
        onSelectionCleared: () => context.go('/goals'),
        onCreate: () => context.go('/goals/new'),
        onMoveSelection: (dir) {
          if (shown.isEmpty) return;
          final i = shown.indexWhere((g) => g.id == selectedId);
          context.go('/goals/${shown[(i + dir).clamp(0, shown.length - 1)].id}');
        },
      ),
    );
  }

  Widget _byPeriod(BuildContext context, List<Goal> goals, Widget Function(Goal) row) {
    final board = yearBoard(goals, _year);
    final wide = context.isExpanded;
    Widget section(String title, List<Goal> g) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [SectionHeader(title), if (g.isEmpty) const Padding(padding: EdgeInsets.symmetric(horizontal: Space.lg), child: Text('—')) else for (final x in g) row(x)],
        );
    return ListView(
      padding: const EdgeInsets.only(bottom: kListBottomPadding),
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(tooltip: 'Previous year', icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _year--)),
          Text('$_year', style: Theme.of(context).textTheme.titleMedium),
          IconButton(tooltip: 'Next year', icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => _year++)),
        ]),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.lg),
          child: Text('Year ${board.year} — completed ${board.completed}/${board.total} (${board.percent}%)', style: Theme.of(context).textTheme.titleSmall),
        ),
        if (wide)
          Padding(
            padding: const EdgeInsets.only(top: Space.sm),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [for (var q = 0; q < 4; q++) Expanded(child: section('Q${q + 1}', board.quarters[q]))]),
          )
        else
          for (var q = 0; q < 4; q++) section('Q${q + 1}', board.quarters[q]),
        section('Whole year', board.wholeYear),
        section('No target date', board.noTarget),
      ],
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({required this.goal, required this.steps, required this.fmt, required this.selected});
  final Goal goal;
  final List<GoalStep> steps;
  final String Function(DateTime) fmt;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = goalProgress(goal, steps, DateTime.now());
    final chips = <Widget>[
      if (goal.targetDate != null && goal.precision != null) Chip(label: Text(periodLabel(goal.targetDate!, goal.precision!, fmt)), visualDensity: VisualDensity.compact),
      Chip(label: Text(goalStatusLabel(goal.status)), visualDensity: VisualDensity.compact),
    ];
    return ListTile(
      selected: selected,
      selectedTileColor: cs.secondaryContainer,
      title: Text(goal.title),
      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: Space.xs),
        LabeledProgress(percent: p, semanticsLabel: '${goal.title} progress'),
        const SizedBox(height: Space.xs),
        Wrap(spacing: Space.sm, children: chips),
      ]),
      onTap: () => context.isExpanded ? context.go('/goals/${goal.id}') : openGoal(context, id: goal.id),
    );
  }
}
