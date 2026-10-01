import '../core/validation/validation.dart';
import '../domain/models.dart';
import 'crud_repository.dart';
import 'ordered_group.dart';

class ListItemsRepo extends CrudRepository {
  ListItemsRepo(super.db, {required super.userId, super.clock});

  static const _group = OrderedGroup(table: 'list_items', groupColumn: 'list');

  Stream<List<ListItem>> watch(ListKind list) => watchRows(
        'SELECT * FROM list_items WHERE list = ? ORDER BY sort_order, id',
        ListItem.fromRow,
        parameters: [list.name],
      );

  Future<String> create(
    ListKind list, {
    required String title,
    String category = '',
    String notes = '',
    String url = '',
    int? price,
    bool done = false,
    String? id,
  }) async {
    final t = requiredText(title, 'Title');
    final p = priceFor(list, price);
    final rowId = id ?? newRowId();
    await db.writeTransaction((tx) async {
      final order = await _group.nextOrder(tx, list.name);
      await insertRow(tx, 'list_items', {
        'id': rowId,
        'list': list.name,
        'title': t,
        'category': category.trim(),
        'notes': notes,
        'url': url.trim(),
        'price': p,
        'done': boolInt(done),
        'sort_order': order,
        'created_at': nowIso,
      });
    });
    return rowId;
  }

  Future<void> update(
    String id, {
    String? title,
    String? category,
    String? notes,
    String? url,
    bool setPrice = false,
    int? price,
    bool? done,
  }) async {
    await db.writeTransaction((tx) async {
      final values = <String, Object?>{
        if (title != null) 'title': requiredText(title, 'Title'),
        if (category != null) 'category': category.trim(),
        'notes': ?notes,
        if (url != null) 'url': url.trim(),
        if (done != null) 'done': boolInt(done),
      };
      if (setPrice) {
        final row = await tx.getOptional('SELECT list FROM list_items WHERE id = ?', [id]);
        if (row == null) return;
        values['price'] = priceFor(listKindFromDb(row['list']), price);
      }
      await updateColumns(tx, 'list_items', id, values);
    });
  }

  Future<void> move(ListKind list, String id, int dir) =>
      db.writeTransaction((tx) => _group.move(tx, list.name, id, dir));

  Future<void> reorder(ListKind list, int oldIndex, int newIndex) =>
      db.writeTransaction((tx) => _group.reorder(tx, list.name, oldIndex, newIndex));

  Future<void> delete(ListKind list, String id) =>
      db.writeTransaction((tx) => _group.deleteAndRenumber(tx, list.name, id));
}
