import 'dart:io';

import 'package:leios/core/db/powersync_schema.dart';
import 'package:powersync/powersync.dart';

/// Temp, unconnected PowerSync database for repository tests.
Future<PowerSyncDatabase> openTestDb() async {
  final dir = Directory.systemTemp.createTempSync('leios_test_');
  final db = PowerSyncDatabase(schema: schema, path: '${dir.path}/t.db');
  await db.initialize();
  return db;
}

const testUser = '00000000-0000-0000-0000-0000000000a1';
