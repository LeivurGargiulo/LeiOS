import 'package:powersync/powersync.dart';
import 'package:sqlite_async/sqlite_async.dart' show SqliteWriteContext;

import '../core/ids/ids.dart';
import '../domain/dates.dart';

typedef Clock = DateTime Function();
typedef UserIdGetter = String? Function();

/// Base for repositories: the ONLY layer that touches SQL (spec §2.3).
/// Provides `user_id` resolution, UTC timestamps and typed `watch` helpers.
abstract class CrudRepository {
  CrudRepository(this.db, {required this._userId, Clock? clock})
      : _clock = clock ?? DateTime.now;

  final PowerSyncDatabase db;
  final UserIdGetter _userId;
  final Clock _clock;

  String get userId {
    final id = _userId();
    if (id == null) throw StateError('Not signed in.');
    return id;
  }

  DateTime get now => _clock();
  String get nowIso => isoInstant(now);
  DateTime get today => dateOnly(now);

  String newRowId() => newId();

  Stream<List<T>> watchRows<T>(
    String sql,
    T Function(Map<String, Object?>) map, {
    List<Object?> parameters = const [],
  }) =>
      db.watch(sql, parameters: parameters).map((rs) => [for (final r in rs) map(r)]);

  Future<List<T>> getRows<T>(
    String sql,
    T Function(Map<String, Object?>) map, {
    List<Object?> parameters = const [],
  }) async =>
      [for (final r in await db.getAll(sql, parameters)) map(r)];

  /// Builds `UPDATE <table> SET a = ?, b = ? WHERE id = ?`.
  Future<void> updateColumns(SqliteWriteContext tx, String table, String id, Map<String, Object?> values) async {
    if (values.isEmpty) return;
    final sets = values.keys.map((k) => '$k = ?').join(', ');
    await tx.execute('UPDATE $table SET $sets WHERE id = ?', [...values.values, id]);
  }

  Future<void> insertRow(SqliteWriteContext tx, String table, Map<String, Object?> values) async {
    final cols = ['user_id', ...values.keys];
    final marks = List.filled(cols.length, '?').join(', ');
    await tx.execute('INSERT INTO $table (id, ${cols.join(', ')}) VALUES (?, $marks)', [
      values['id'] ?? newRowId(),
      userId,
      ...values.entries.map((e) => e.value),
    ]);
  }

  int boolInt(bool v) => v ? 1 : 0;
}
