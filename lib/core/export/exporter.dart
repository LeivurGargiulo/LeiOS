import 'dart:convert';
import 'dart:io';

import 'package:powersync/powersync.dart';

import '../db/powersync_schema.dart';

const exportSchemaVersion = 3;

/// Builds the plain JSON export (12 tables + metadata). Booleans are emitted as booleans.
String buildExportJson(Map<String, List<Map<String, Object?>>> tables, {DateTime? now}) {
  final out = <String, Object?>{};
  for (final name in syncedTables) {
    final bools = booleanColumns[name] ?? const <String>{};
    out[name] = [
      for (final row in tables[name] ?? const <Map<String, Object?>>[])
        {for (final e in row.entries) e.key: bools.contains(e.key) && e.value is int ? e.value == 1 : e.value},
    ];
  }
  out['exported_at'] = (now ?? DateTime.now()).toUtc().toIso8601String();
  out['schema_version'] = exportSchemaVersion;
  return const JsonEncoder.withIndent('  ').convert(out);
}

Future<String> exportDatabase(PowerSyncDatabase db, {DateTime? now}) async {
  final tables = <String, List<Map<String, Object?>>>{};
  for (final t in syncedTables) {
    tables[t] = [for (final r in await db.getAll('SELECT * FROM $t')) Map<String, Object?>.from(r)];
  }
  return buildExportJson(tables, now: now);
}

String exportFileName(DateTime now) {
  String two(int n) => n.toString().padLeft(2, '0');
  final u = now.toUtc();
  return 'leios-export-${u.year}${two(u.month)}${two(u.day)}-${two(u.hour)}${two(u.minute)}${two(u.second)}.json';
}

/// Atomic write: temp file in the same directory, then rename.
Future<File> writeAtomic(File target, String content) async {
  final tmp = File('${target.path}.tmp');
  await tmp.writeAsString(content, flush: true);
  return tmp.rename(target.path);
}
