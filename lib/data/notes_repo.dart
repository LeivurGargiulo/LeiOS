import '../core/validation/validation.dart';
import '../domain/models.dart';
import 'crud_repository.dart';

class NotesRepo extends CrudRepository {
  NotesRepo(super.db, {required super.userId, super.clock});

  Stream<List<Note>> watchAll() =>
      watchRows('SELECT * FROM notes ORDER BY updated_at DESC', Note.fromRow);

  Future<Note?> get(String id) async {
    final r = await db.getOptional('SELECT * FROM notes WHERE id = ?', [id]);
    return r == null ? null : Note.fromRow(r);
  }

  Future<String> create({required String title, String content = '', String tags = '', String? id}) async {
    final t = requiredText(title, 'Title');
    final rowId = id ?? newRowId();
    final n = nowIso;
    await db.writeTransaction((tx) => insertRow(tx, 'notes', {
          'id': rowId,
          'title': t,
          'content': content,
          'tags': normalizedTags(tags),
          'created_at': n,
          'updated_at': n,
        }));
    return rowId;
  }

  Future<void> update(String id, {String? title, String? content, String? tags}) async {
    await db.writeTransaction((tx) => updateColumns(tx, 'notes', id, {
          if (title != null) 'title': requiredText(title, 'Title'),
          'content': ?content,
          if (tags != null) 'tags': normalizedTags(tags),
          'updated_at': nowIso,
        }));
  }

  Future<void> delete(String id) => db.execute('DELETE FROM notes WHERE id = ?', [id]);

  Future<void> restore(Note n) => create(id: n.id, title: n.title, content: n.content, tags: n.tags);
}
