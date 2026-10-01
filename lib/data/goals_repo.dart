import '../core/validation/validation.dart';
import '../domain/dates.dart';
import '../domain/models.dart';
import '../domain/tasks.dart';
import 'crud_repository.dart';
import 'ordered_group.dart';

class GoalsRepo extends CrudRepository {
  GoalsRepo(super.db, {required super.userId, super.clock});

  static const _steps = OrderedGroup(table: 'goal_steps', groupColumn: 'goal_id');

  Stream<List<Goal>> watchGoals() =>
      watchRows('SELECT * FROM goals ORDER BY created_at', Goal.fromRow);

  Stream<List<GoalStep>> watchSteps() =>
      watchRows('SELECT * FROM goal_steps ORDER BY goal_id, sort_order', GoalStep.fromRow);

  Future<String> create({
    required String title,
    String description = '',
    DateTime? targetDate,
    GoalPrecision? precision,
    GoalStatus status = GoalStatus.pending,
    String? id,
  }) async {
    final t = requiredText(title, 'Title');
    final target = normalizeGoalTarget(targetDate, precision);
    final rowId = id ?? newRowId();
    await db.writeTransaction((tx) => insertRow(tx, 'goals', {
          'id': rowId,
          'title': t,
          'description': description,
          'target_date': target.date == null ? null : isoDate(target.date!),
          'target_precision': target.precision?.name,
          'status': status.name,
          'created_at': nowIso,
        }));
    return rowId;
  }

  /// [targetDate]/[precision] are replaced together when [setTarget] is true (null clears).
  Future<void> update(
    String id, {
    String? title,
    String? description,
    bool setTarget = false,
    DateTime? targetDate,
    GoalPrecision? precision,
    GoalStatus? status,
  }) async {
    final values = <String, Object?>{
      if (title != null) 'title': requiredText(title, 'Title'),
      'description': ?description,
      if (status != null) 'status': status.name,
    };
    if (setTarget) {
      final target = normalizeGoalTarget(targetDate, precision);
      values['target_date'] = target.date == null ? null : isoDate(target.date!);
      values['target_precision'] = target.precision?.name;
    }
    await db.writeTransaction((tx) => updateColumns(tx, 'goals', id, values));
  }

  Future<GoalStatus?> advance(String id) async {
    final row = await db.getOptional('SELECT status FROM goals WHERE id = ?', [id]);
    if (row == null) return null;
    final next = nextGoalStatusName(row['status'] as String?);
    await db.execute('UPDATE goals SET status = ? WHERE id = ?', [next, id]);
    return goalStatusFromDb(next);
  }

  /// Cascade: steps first, then the goal.
  Future<void> delete(String id) => db.writeTransaction((tx) async {
        await tx.execute('DELETE FROM goal_steps WHERE goal_id = ?', [id]);
        await tx.execute('DELETE FROM goals WHERE id = ?', [id]);
      });

  Future<String> addStep(String goalId, String title) async {
    final t = requiredText(title, 'Step title');
    final id = newRowId();
    await db.writeTransaction((tx) async {
      final order = await _steps.nextOrder(tx, goalId);
      await insertRow(tx, 'goal_steps', {
        'id': id,
        'goal_id': goalId,
        'title': t,
        'done': 0,
        'sort_order': order,
        'created_at': nowIso,
      });
    });
    return id;
  }

  Future<void> updateStep(String id, {String? title, bool? done}) async {
    await db.writeTransaction((tx) => updateColumns(tx, 'goal_steps', id, {
          if (title != null) 'title': requiredText(title, 'Step title'),
          if (done != null) 'done': boolInt(done),
        }));
  }

  Future<void> moveStep(String goalId, String stepId, int dir) =>
      db.writeTransaction((tx) => _steps.move(tx, goalId, stepId, dir));

  Future<void> reorderSteps(String goalId, int oldIndex, int newIndex) =>
      db.writeTransaction((tx) => _steps.reorder(tx, goalId, oldIndex, newIndex));

  Future<void> deleteStep(String goalId, String stepId) =>
      db.writeTransaction((tx) => _steps.deleteAndRenumber(tx, goalId, stepId));
}
