import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';
import '../db/powersync_schema.dart';
import '../ids/ids.dart';

/// Postgres error classes that can never succeed on retry (spec §4.2):
/// 22 data exception, 23 integrity constraint (incl. FK/check), 42501 RLS / privilege.
bool isFatalPostgresCode(String? code) {
  if (code == null) return false;
  return code.startsWith('22') || code.startsWith('23') || code == '42501';
}

class SupabaseConnector extends PowerSyncBackendConnector {
  SupabaseConnector(this.db);

  final PowerSyncDatabase db;

  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    var session = _client.auth.currentSession;
    if (session == null) return null;
    final expiresAt = session.expiresAt;
    if (expiresAt != null &&
        DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000).isBefore(DateTime.now().add(const Duration(seconds: 30)))) {
      session = (await _client.auth.refreshSession()).session ?? session;
    }
    return PowerSyncCredentials(
      endpoint: Env.powersyncUrl,
      token: session.accessToken,
      userId: session.user.id,
      expiresAt: session.expiresAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000),
    );
  }

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    CrudTransaction? transaction;
    while ((transaction = await database.getNextCrudTransaction()) != null) {
      final tx = transaction!;
      CrudEntry? last;
      try {
        for (final op in tx.crud) {
          last = op;
          final table = _client.from(op.table);
          final data = _normalize(op.table, op.opData);
          switch (op.op) {
            case UpdateType.put:
              await table.upsert({...?data, 'id': op.id});
            case UpdateType.patch:
              await table.update(data ?? {}).eq('id', op.id);
            case UpdateType.delete:
              await table.delete().eq('id', op.id);
          }
        }
        await tx.complete();
      } on PostgrestException catch (e) {
        if (isFatalPostgresCode(e.code)) {
          // Never block the queue; keep a visible trace instead of losing data silently.
          await _recordError(database, last, e.message);
          await tx.complete();
        } else {
          rethrow;
        }
      }
    }
  }

  Map<String, dynamic>? _normalize(String table, Map<String, dynamic>? data) {
    final bools = booleanColumns[table];
    if (data == null || bools == null) return data;
    return {
      for (final e in data.entries)
        e.key: bools.contains(e.key) && e.value is int ? e.value == 1 : e.value,
    };
  }

  Future<void> _recordError(PowerSyncDatabase database, CrudEntry? op, String message) {
    return database.execute(
      'INSERT INTO sync_errors (id, table_name, row_id, op, message, at) VALUES (?, ?, ?, ?, ?, ?)',
      [newId(), op?.table ?? '', op?.id ?? '', op?.op.name ?? '', message, DateTime.now().toUtc().toIso8601String()],
    );
  }
}
