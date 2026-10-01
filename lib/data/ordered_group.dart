import 'package:sqlite_async/sqlite_async.dart' show SqliteReadContext, SqliteWriteContext;

import '../domain/ordering.dart';

/// Generic `sort_order` management for a group of rows (spec §6), used by
/// `goal_steps` (grouped by `goal_id`) and `list_items` (grouped by `list`).
class OrderedGroup {
  const OrderedGroup({required this.table, required this.groupColumn});
  final String table;
  final String groupColumn;

  Future<List<String>> orderedIds(SqliteReadContext tx, Object group) async {
    final rows = await tx.getAll(
      'SELECT id FROM $table WHERE $groupColumn = ? ORDER BY sort_order, id',
      [group],
    );
    return [for (final r in rows) r['id'] as String];
  }

  /// `sort_order` for a new item appended to the group.
  Future<int> nextOrder(SqliteReadContext tx, Object group) async {
    final r = await tx.get('SELECT COUNT(*) AS c FROM $table WHERE $groupColumn = ?', [group]);
    return appendOrder(r['c'] as int);
  }

  Future<void> _apply(SqliteWriteContext tx, List<OrderUpdate> updates) async {
    for (final u in updates) {
      await tx.execute('UPDATE $table SET sort_order = ? WHERE id = ?', [u.sortOrder, u.id]);
    }
  }

  Future<void> move(SqliteWriteContext tx, Object group, String id, int dir) async =>
      _apply(tx, planMove(await orderedIds(tx, group), id, dir));

  Future<void> reorder(SqliteWriteContext tx, Object group, int oldIndex, int newIndex) async =>
      _apply(tx, planReorder(await orderedIds(tx, group), oldIndex, newIndex));

  /// Deletes [id] and renumbers the rest of the group contiguously.
  Future<void> deleteAndRenumber(SqliteWriteContext tx, Object group, String id) async {
    final ids = await orderedIds(tx, group);
    await tx.execute('DELETE FROM $table WHERE id = ?', [id]);
    await _apply(tx, planRenumberAfterDelete(ids, id));
  }
}
