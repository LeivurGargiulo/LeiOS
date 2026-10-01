import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/design/motion.dart';
import '../../core/design/tokens.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/format.dart';
import '../../core/widgets/small_widgets.dart';
import '../../core/widgets/swipe_action_tile.dart';
import '../../domain/dates.dart';
import '../../domain/models.dart';
import '../../domain/tasks.dart';
import '../../l10n/app_localizations.dart';

int statusIndex(TaskStatus s) => switch (s) { TaskStatus.todo => 0, TaskStatus.doing => 1, TaskStatus.done => 2 };

String statusLabel(L10n l, TaskStatus s) => switch (s) { TaskStatus.todo => l.statusTodo, TaskStatus.doing => l.statusDoing, TaskStatus.done => l.statusDone };

/// A task row used by Tasks, Today and Calendar: animated status circle, title, metadata chips.
class TaskTile extends ConsumerWidget {
  const TaskTile({super.key, required this.task, required this.onTap, this.selected = false, this.swipe = true, this.dense = false});

  final Task task;
  final VoidCallback onTap;
  final bool selected;
  final bool swipe;
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final repo = ref.read(tasksRepoProvider);
    final fmt = ref.watch(formatDateProvider);
    final today = dateOnly(DateTime.now());
    final done = task.status == TaskStatus.done;
    final overdue = !done && task.dueDate != null && task.dueDate!.isBefore(today);
    final messenger = ScaffoldMessenger.of(context);
    final l = L10n.of(context);

    Future<void> delete() async {
      final t = task;
      await repo.delete(t.id);
      showUndoSnackOn(messenger, l.entityDeleted(l.quickAddTask), undoLabel: l.undo, onUndo: () => repo.restore(t));
    }

    final chips = <Widget>[
      if (task.dueDate != null)
        _MetaChip(
          icon: overdue ? Icons.warning_amber_rounded : Icons.event,
          label: dueLabel(task.dueDate!, today, fmt),
          color: overdue ? cs.error : cs.onSurfaceVariant,
        ),
      if (task.urgent) _IconMeta(Icons.priority_high, l.urgent),
      if (task.important) _IconMeta(Icons.star_outline, l.important),
      if (task.longTerm) _IconMeta(Icons.flag_outlined, l.longTerm),
    ];

    final tile = ListTile(
      selected: selected,
      selectedTileColor: cs.secondaryContainer,
      contentPadding: const EdgeInsets.only(left: Space.xs, right: Space.xs),
      minVerticalPadding: dense ? 0 : null,
      leading: StatusCircle(
        state: statusIndex(task.status),
        semanticLabel: l.taskTapToAdvance(statusLabel(l, task.status)),
        onTap: () => repo.advance(task.id),
      ),
      title: AnimatedDefaultTextStyle(
        duration: motionDuration(context),
        style: (tt.bodyLarge ?? const TextStyle()).copyWith(
          decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
          color: done ? cs.onSurfaceVariant : cs.onSurface,
        ),
        child: Text(task.title),
      ),
      subtitle: chips.isEmpty ? null : Padding(padding: const EdgeInsets.only(top: Space.xs), child: Wrap(spacing: Space.sm, runSpacing: Space.xs, children: chips)),
      onTap: onTap,
    );

    if (!swipe) return tile;
    return SwipeActionTile(
      key: ValueKey('task-${task.id}'),
      onSwipeRight: () => repo.advance(task.id),
      rightIcon: done ? Icons.undo : (task.status == TaskStatus.doing ? Icons.check : Icons.arrow_forward),
      onSwipeLeft: delete,
      menuItems: [
        TileMenuItem(label: done ? l.taskMarkTodo : l.taskAdvance, icon: Icons.arrow_forward, onTap: () => repo.advance(task.id)),
        TileMenuItem(label: l.delete, icon: Icons.delete_outline, destructive: true, onTap: delete),
      ],
      child: tile,
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 2),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color))),
        ],
      );
}

class _IconMeta extends StatelessWidget {
  const _IconMeta(this.icon, this.semantic);
  final IconData icon;
  final String semantic;

  @override
  Widget build(BuildContext context) => Semantics(
        label: semantic,
        child: Icon(icon, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
}
