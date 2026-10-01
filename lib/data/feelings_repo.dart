import '../core/ids/ids.dart';
import '../core/validation/validation.dart';
import '../domain/dates.dart';
import '../domain/models.dart';
import 'crud_repository.dart';

class FeelingsRepo extends CrudRepository {
  FeelingsRepo(super.db, {required super.userId, super.clock});

  Stream<List<Feeling>> watchAll() =>
      watchRows('SELECT * FROM feelings ORDER BY date DESC', Feeling.fromRow);

  /// Upserts the entry for [day]. When [notes]/[tags] are null an existing entry keeps its own.
  Future<String> upsert(DateTime day, int rating, {String? notes, String? tags}) async {
    final r = rangeInt(rating, 1, 5, 'Rating');
    final iso = isoDate(day);
    final id = feelingId(userId, iso);
    await db.writeTransaction((tx) async {
      final existing = await tx.getOptional('SELECT id FROM feelings WHERE id = ?', [id]);
      if (existing == null) {
        await insertRow(tx, 'feelings', {
          'id': id,
          'date': iso,
          'rating': r,
          'notes': notes ?? '',
          'tags': normalizedTags(tags ?? ''),
        });
      } else {
        await updateColumns(tx, 'feelings', id, {
          'rating': r,
          'notes': ?notes,
          if (tags != null) 'tags': normalizedTags(tags),
        });
      }
    });
    return id;
  }

  Future<void> delete(String id) => db.execute('DELETE FROM feelings WHERE id = ?', [id]);

  Future<void> restore(Feeling f) => upsert(f.date, f.rating, notes: f.notes, tags: f.tags);
}
