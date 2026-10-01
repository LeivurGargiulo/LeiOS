import '../core/validation/validation.dart';
import '../domain/dates.dart';
import '../domain/models.dart';
import '../domain/tasks.dart';
import 'crud_repository.dart';

class TasksRepo extends CrudRepository {
  TasksRepo(super.db, {required super.userId, super.clock});

  Stream<List<Task>> watchAll() =>
      watchRows('SELECT * FROM tasks ORDER BY created_at', Task.fromRow);

  Future<Task?> get(String id) async {
    final r = await db.getOptional('SELECT * FROM tasks WHERE id = ?', [id]);
    return r == null ? null : Task.fromRow(r);
  }

  Future<String> create({
    required String title,
    String notes = '',
    bool urgent = false,
    bool important = false,
    DateTime? dueDate,
    bool longTerm = false,
    TaskStatus status = TaskStatus.todo,
    String? id,
  }) async {
    final t = requiredText(title, 'Title');
    final rowId = id ?? newRowId();
    final n = nowIso;
    await db.writeTransaction((tx) => insertRow(tx, 'tasks', {
          'id': rowId,
          'title': t,
          'notes': notes,
          'urgent': boolInt(urgent),
          'important': boolInt(important),
          'status': status.name,
          'due_date': dueDate == null ? null : isoDate(dueDate),
          'long_term': boolInt(longTerm),
          'created_at': n,
          'updated_at': n,
          'completed_at': status == TaskStatus.done ? n : null,
        }));
    return rowId;
  }

  /// Updates editable fields. Pass [clearDueDate] to remove the due date.
  Future<void> update(
    String id, {
    String? title,
    String? notes,
    bool? urgent,
    bool? important,
    DateTime? dueDate,
    bool clearDueDate = false,
    bool? longTerm,
  }) async {
    final values = <String, Object?>{
      if (title != null) 'title': requiredText(title, 'Title'),
      'notes': ?notes,
      if (urgent != null) 'urgent': boolInt(urgent),
      if (important != null) 'important': boolInt(important),
      if (dueDate != null) 'due_date': isoDate(dueDate) else if (clearDueDate) 'due_date': null,
      if (longTerm != null) 'long_term': boolInt(longTerm),
      'updated_at': nowIso,
    };
    await db.writeTransaction((tx) => updateColumns(tx, 'tasks', id, values));
  }

  Future<void> setStatus(String id, TaskStatus status) async {
    await db.writeTransaction((tx) async {
      final row = await tx.getOptional('SELECT status, completed_at FROM tasks WHERE id = ?', [id]);
      if (row == null) return;
      final from = taskStatusFromDb(row['status']);
      final prev = row['completed_at'] == null ? null : parseInstant(row['completed_at'] as String);
      final completed = completedAtFor(from, status, prev, now);
      await updateColumns(tx, 'tasks', id, {
        'status': status.name,
        'completed_at': completed == null ? null : isoInstant(completed),
        'updated_at': nowIso,
      });
    });
  }

  /// Advances `todo → doing → done → todo`; returns the new status.
  Future<TaskStatus?> advance(String id) async {
    final t = await get(id);
    if (t == null) return null;
    final next = nextTaskStatus(t.status);
    await setStatus(id, next);
    return next;
  }

  Future<void> delete(String id) => db.execute('DELETE FROM tasks WHERE id = ?', [id]);

  /// Re-inserts a previously deleted task (Undo).
  Future<void> restore(Task t) => create(
        id: t.id,
        title: t.title,
        notes: t.notes,
        urgent: t.urgent,
        important: t.important,
        dueDate: t.dueDate,
        longTerm: t.longTerm,
        status: t.status,
      );
}
