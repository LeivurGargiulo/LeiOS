import '../core/ids/ids.dart';
import '../core/validation/validation.dart';
import '../domain/dates.dart';
import '../domain/models.dart';
import 'crud_repository.dart';

class HabitsRepo extends CrudRepository {
  HabitsRepo(super.db, {required super.userId, super.clock});

  Stream<List<Habit>> watchHabits() =>
      watchRows('SELECT * FROM habits ORDER BY created_at, id', Habit.fromRow);

  Stream<List<HabitCompletion>> watchCompletions() =>
      watchRows('SELECT habit_id, date FROM habit_completions', HabitCompletion.fromRow);

  Future<String> create({required String name, int targetFrequency = 7}) async {
    final n = requiredText(name, 'Habit name');
    final f = rangeInt(targetFrequency, 1, 7, 'Target frequency');
    final id = newRowId();
    await db.writeTransaction((tx) => insertRow(tx, 'habits', {
          'id': id,
          'name': n,
          'target_frequency': f,
          'created_at': nowIso,
        }));
    return id;
  }

  Future<void> update(String id, {String? name, int? targetFrequency}) async {
    final values = <String, Object?>{
      if (name != null) 'name': requiredText(name, 'Habit name'),
      if (targetFrequency != null) 'target_frequency': rangeInt(targetFrequency, 1, 7, 'Target frequency'),
    };
    await db.writeTransaction((tx) => updateColumns(tx, 'habits', id, values));
  }

  /// Cascade: completions first, then the habit.
  Future<void> delete(String id) => db.writeTransaction((tx) async {
        await tx.execute('DELETE FROM habit_completions WHERE habit_id = ?', [id]);
        await tx.execute('DELETE FROM habits WHERE id = ?', [id]);
      });

  /// Toggles completion for [day]. Deterministic id ⇒ two devices never duplicate a day.
  Future<bool> toggle(String habitId, DateTime day) async {
    final iso = isoDate(day);
    final id = habitCompletionId(userId, habitId, iso);
    return db.writeTransaction((tx) async {
      final exists = await tx.getOptional('SELECT id FROM habit_completions WHERE id = ?', [id]);
      if (exists != null) {
        await tx.execute('DELETE FROM habit_completions WHERE id = ?', [id]);
        return false;
      }
      await insertRow(tx, 'habit_completions', {'id': id, 'habit_id': habitId, 'date': iso});
      return true;
    });
  }
}
