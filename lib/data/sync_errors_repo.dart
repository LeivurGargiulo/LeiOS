import 'package:powersync/powersync.dart';

class SyncErrorRow {
  const SyncErrorRow({required this.id, required this.table, required this.rowId, required this.op, required this.message, required this.at});
  final String id;
  final String table;
  final String rowId;
  final String op;
  final String message;
  final String at;
}

class SyncErrorsRepo {
  SyncErrorsRepo(this.db);
  final PowerSyncDatabase db;

  Stream<List<SyncErrorRow>> watch() => db.watch('SELECT * FROM sync_errors ORDER BY at DESC').map((rs) => [
        for (final r in rs)
          SyncErrorRow(
            id: r['id'] as String,
            table: r['table_name'] as String? ?? '',
            rowId: r['row_id'] as String? ?? '',
            op: r['op'] as String? ?? '',
            message: r['message'] as String? ?? '',
            at: r['at'] as String? ?? '',
          ),
      ]);

  Future<void> clear() => db.execute('DELETE FROM sync_errors');

  Stream<int> watchPendingCount() => db
      .watch('SELECT COUNT(*) AS c FROM ps_crud')
      .map((rs) => rs.isEmpty ? 0 : (rs.first['c'] as int));
}
