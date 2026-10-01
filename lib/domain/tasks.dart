import 'dates.dart';
import 'models.dart';

enum TaskBucket { overdue, today, next7, later, noDate }

TaskStatus nextTaskStatus(TaskStatus s) => switch (s) {
      TaskStatus.todo => TaskStatus.doing,
      TaskStatus.doing => TaskStatus.done,
      TaskStatus.done => TaskStatus.todo,
    };

GoalStatus nextGoalStatus(GoalStatus s) => switch (s) {
      GoalStatus.pending => GoalStatus.active,
      GoalStatus.active => GoalStatus.completed,
      GoalStatus.completed => GoalStatus.pending,
    };

/// Next value from a raw DB string; an unknown value cycles to the first.
String nextTaskStatusName(String? raw) {
  final i = TaskStatus.values.indexWhere((e) => e.name == raw);
  return i < 0 ? TaskStatus.values.first.name : TaskStatus.values[(i + 1) % 3].name;
}

String nextGoalStatusName(String? raw) {
  final i = GoalStatus.values.indexWhere((e) => e.name == raw);
  return i < 0 ? GoalStatus.values.first.name : GoalStatus.values[(i + 1) % 3].name;
}

String goalAdvanceLabel(GoalStatus s) => switch (s) {
      GoalStatus.pending => 'Activate',
      GoalStatus.active => 'Complete',
      GoalStatus.completed => 'Reopen',
    };

/// §7.2: entering `done` stamps [now]; leaving it clears; staying keeps [previous].
DateTime? completedAtFor(TaskStatus from, TaskStatus to, DateTime? previous, DateTime now) {
  if (to == TaskStatus.done) return from == TaskStatus.done ? previous : now;
  return null;
}

TaskBucket bucketFor(DateTime? due, DateTime today) {
  if (due == null) return TaskBucket.noDate;
  final d = dateOnly(due);
  final t = dateOnly(today);
  if (d.isBefore(t)) return TaskBucket.overdue;
  if (d == t) return TaskBucket.today;
  if (!d.isAfter(addDays(t, 7))) return TaskBucket.next7;
  return TaskBucket.later;
}

enum TaskScope { regular, longTerm, all }

bool inScope(Task t, TaskScope s) => switch (s) {
      TaskScope.regular => !t.longTerm,
      TaskScope.longTerm => t.longTerm,
      TaskScope.all => true,
    };

Map<TaskBucket, List<Task>> bucketTasks(Iterable<Task> tasks, DateTime today) {
  final out = {for (final b in TaskBucket.values) b: <Task>[]};
  for (final t in tasks.where((t) => t.status != TaskStatus.done)) {
    out[bucketFor(t.dueDate, today)]!.add(t);
  }
  for (final l in out.values) {
    l.sort((a, b) {
      if (a.dueDate != null && b.dueDate != null) {
        final c = a.dueDate!.compareTo(b.dueDate!);
        if (c != 0) return c;
      }
      return a.createdAt.compareTo(b.createdAt);
    });
  }
  return out;
}

/// Eisenhower quadrants keyed by (urgent, important).
Map<(bool, bool), List<Task>> eisenhower(Iterable<Task> tasks) {
  final out = {
    for (final u in [true, false])
      for (final i in [true, false]) (u, i): <Task>[],
  };
  for (final t in tasks.where((t) => t.status != TaskStatus.done)) {
    out[(t.urgent, t.important)]!.add(t);
  }
  return out;
}

String dueLabel(DateTime due, DateTime today, String Function(DateTime) format) {
  final d = dateOnly(due);
  final t = dateOnly(today);
  final diff = d.difference(t).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Tomorrow';
  if (diff > 1 && diff <= 6) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[d.weekday - 1];
  }
  return format(d);
}

String greetingFor(int hour) => hour < 12 ? 'Good morning' : (hour < 19 ? 'Good afternoon' : 'Good evening');
