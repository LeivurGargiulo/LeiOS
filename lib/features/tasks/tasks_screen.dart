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
import '../../core/widgets/master_detail_scaffold.dart';
import '../../core/widgets/small_widgets.dart';
import '../../domain/dates.dart';
import '../../domain/models.dart';
import '../../domain/tasks.dart';
import '../../l10n/app_localizations.dart';
import 'task_form.dart';
import 'task_tile.dart';

enum TaskView { status, date, matrix }

String _viewLabel(TaskView v) => switch (v) { TaskView.status => 'By status', TaskView.date => 'By date', TaskView.matrix => 'Matrix' };
String _scopeLabel(TaskScope s) => switch (s) { TaskScope.regular => 'Regular', TaskScope.longTerm => 'Long-term', TaskScope.all => 'All' };

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key, this.selectedId});
  final String? selectedId;

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  bool _doneOpen = false;

  TaskView get _view => TaskView.values.firstWhere(
        (v) => v.name == ref.watch(prefProvider('tasks_view')),
        orElse: () => TaskView.status,
      );
  TaskScope get _scope => TaskScope.values.firstWhere(
        (v) => v.name == ref.watch(prefProvider('tasks_scope')),
        orElse: () => TaskScope.regular,
      );

  void _select(String id) => context.go('/tasks/$id');

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final tasksAsync = ref.watch(tasksProvider);
    final tasks = tasksAsync.asData?.value ?? const <Task>[];
    final scoped = tasks.where((t) => inScope(t, _scope)).toList();
    final selectedId = widget.selectedId;

    final master = _TasksMaster(
      view: _view,
      scope: _scope,
      tasks: scoped,
      loading: tasksAsync.isLoading && !tasksAsync.hasValue,
      selectedId: selectedId,
      doneOpen: _doneOpen,
      onToggleDone: () => setState(() => _doneOpen = !_doneOpen),
      onTap: (t) => context.isExpanded ? _select(t.id) : openTask(context, id: t.id),
      onScope: (s) => ref.read(prefProvider('tasks_scope').notifier).set(s.name),
      onCreate: () => openTask(context),
    );

    Widget? detail;
    if (selectedId != null) {
      detail = TaskForm(
        key: ValueKey('task-form-$selectedId'),
        taskId: selectedId == 'new' ? null : selectedId,
        presentation: EditorPresentation.inline,
        onClosed: () => context.go('/tasks'),
      );
    }

    return ScreenScaffold(
      title: 'Tasks',
      actions: [
        PopupMenuButton<TaskView>(
          tooltip: 'Change view',
          icon: const Icon(Icons.view_agenda_outlined),
          initialValue: _view,
          onSelected: (v) => ref.read(prefProvider('tasks_view').notifier).set(v.name),
          itemBuilder: (_) => [
            for (final v in TaskView.values)
              CheckedPopupMenuItem(value: v, checked: v == _view, child: Text(_viewLabel(v))),
          ],
        ),
      ],
      fab: FabSpec(tooltip: l.emptyTasksAction, onPressed: () => openTask(context)),
      body: MasterDetailScaffold<Task>(
        master: master,
        detail: detail,
        itemIds: [for (final t in tasks) t.id],
        selectedId: selectedId,
        dataLoaded: tasksAsync.hasValue,
        onSelectionCleared: () => context.go('/tasks'),
        onCreate: () => context.go('/tasks/new'),
        onMoveSelection: (dir) {
          final visible = scoped.where((t) => t.status != TaskStatus.done || _view == TaskView.status).toList();
          if (visible.isEmpty) return;
          final i = visible.indexWhere((t) => t.id == selectedId);
          final n = (i + dir).clamp(0, visible.length - 1);
          _select(visible[i < 0 ? 0 : n].id);
        },
      ),
    );
  }
}

class _TasksMaster extends StatelessWidget {
  const _TasksMaster({
    required this.view,
    required this.scope,
    required this.tasks,
    required this.loading,
    required this.selectedId,
    required this.doneOpen,
    required this.onToggleDone,
    required this.onTap,
    required this.onScope,
    required this.onCreate,
  });

  final TaskView view;
  final TaskScope scope;
  final List<Task> tasks;
  final bool loading;
  final String? selectedId;
  final bool doneOpen;
  final VoidCallback onToggleDone;
  final void Function(Task) onTap;
  final ValueChanged<TaskScope> onScope;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final today = dateOnly(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.lg, Space.sm, Space.lg, Space.sm),
          child: Row(
            children: [
              Expanded(child: SegmentFilter<TaskScope>(values: TaskScope.values, selected: scope, labelOf: _scopeLabel, onSelected: onScope)),
              if (context.isExpanded) ...[const SizedBox(width: Space.sm), NewButton(onPressed: onCreate)],
            ],
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : tasks.isEmpty
                  ? EmptyState(
                      icon: Icons.task_alt,
                      title: l.emptyTasksTitle,
                      message: l.emptyTasksMessage,
                      actionLabel: l.emptyTasksAction,
                      onAction: onCreate,
                      seed: 1,
                    )
                  : switch (view) {
                      TaskView.status => _statusView(context),
                      TaskView.date => _dateView(context, today, l),
                      TaskView.matrix => _matrixView(context, l),
                    },
        ),
      ],
    );
  }

  Widget _tile(Task t) => TaskTile(task: t, selected: t.id == selectedId, onTap: () => onTap(t));

  Widget _statusView(BuildContext context) {
    final todo = tasks.where((t) => t.status == TaskStatus.todo).toList();
    final doing = tasks.where((t) => t.status == TaskStatus.doing).toList();
    final done = tasks.where((t) => t.status == TaskStatus.done).toList();
    return ListView(
      padding: const EdgeInsets.only(bottom: kListBottomPadding),
      children: [
        _section(context, 'To do', todo),
        _section(context, 'Doing', doing),
        SectionHeader(
          'Done (${done.length})',
          trailing: IconButton(
            tooltip: doneOpen ? 'Collapse done tasks' : 'Expand done tasks',
            icon: AnimatedRotation(turns: doneOpen ? 0.5 : 0, duration: Dur.short, child: const Icon(Icons.expand_more)),
            onPressed: onToggleDone,
          ),
        ),
        AnimatedSize(
          duration: Dur.medium,
          curve: Ease.inPlace,
          alignment: Alignment.topCenter,
          child: doneOpen ? Column(children: [for (final t in done) _tile(t)]) : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  Widget _section(BuildContext context, String title, List<Task> list, {Color? color}) {
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [SectionHeader('$title (${list.length})', color: color), for (final t in list) _tile(t)],
    );
  }

  Widget _dateView(BuildContext context, DateTime today, L10n l) {
    final cs = Theme.of(context).colorScheme;
    final b = bucketTasks(tasks, today);
    if (b.values.every((l) => l.isEmpty)) {
      return EmptyState(icon: Icons.filter_list_off, title: l.emptyTasksFilteredTitle, message: l.emptyTasksFilteredMessage, seed: 2);
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: kListBottomPadding),
      children: [
        _section(context, 'Overdue', b[TaskBucket.overdue]!, color: cs.error),
        _section(context, 'Today', b[TaskBucket.today]!),
        _section(context, 'Next 7 days', b[TaskBucket.next7]!),
        _section(context, 'Later', b[TaskBucket.later]!),
        _section(context, 'No date', b[TaskBucket.noDate]!),
      ],
    );
  }

  Widget _matrixView(BuildContext context, L10n l) {
    final q = eisenhower(tasks);
    Widget quadrant(String title, bool u, bool i) {
      final list = q[(u, i)]!;
      return Card.filled(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 160),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.md, Space.md, Space.md, Space.xs),
                child: Text('$title (${list.length})', style: Theme.of(context).textTheme.titleSmall),
              ),
              Expanded(
                child: list.isEmpty
                    ? Center(child: Text('—', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)))
                    : ListView(children: [for (final t in list) TaskTile(task: t, selected: t.id == selectedId, onTap: () => onTap(t), swipe: false, dense: true)]),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(builder: (context, c) {
      final cards = [
        quadrant('Urgent & important', true, true),
        quadrant('Important, not urgent', false, true),
        quadrant('Urgent, not important', true, false),
        quadrant('Neither', false, false),
      ];
      return GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: Space.md,
        crossAxisSpacing: Space.md,
        padding: EdgeInsets.fromLTRB(Space.md, Space.xs, Space.md, c.maxWidth < 600 ? kListBottomPadding : Space.md),
        childAspectRatio: c.maxWidth < 420 ? 0.62 : 1.0,
        children: cards,
      );
    });
  }
}
