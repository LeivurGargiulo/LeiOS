import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/env.dart';
import '../core/db/powersync_schema.dart';
import '../core/sync/auth_service.dart';
import 'app.dart';
import 'providers.dart';

Future<PowerSyncDatabase> openDatabase({String? path}) async {
  final dbPath = path ?? p.join((await getApplicationSupportDirectory()).path, 'leios.db');
  await Directory(p.dirname(dbPath)).create(recursive: true);
  final db = PowerSyncDatabase(schema: schema, path: dbPath);
  await db.initialize();
  return db;
}

/// Starts the app. [authService] / [db] can be injected (tests, integration).
Future<void> bootstrap({AuthService? authService, PowerSyncDatabase? db, bool? syncEnabled}) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (authService == null) {
    if (!Env.isConfigured) {
      runApp(const NotConfiguredApp());
      return;
    }
    // A stored session is restored locally; this never blocks on the network.
    await Supabase.initialize(url: Env.supabaseUrl, publishableKey: Env.supabaseAnonKey);
  }

  final prefs = await SharedPreferences.getInstance();
  final database = db ?? await openDatabase();
  runApp(ProviderScope(
    overrides: [
      dbProvider.overrideWithValue(database),
      prefsProvider.overrideWithValue(prefs),
      authServiceProvider.overrideWithValue(authService ?? SupabaseAuthService()),
      if (syncEnabled != null) syncEnabledProvider.overrideWithValue(syncEnabled),
    ],
    child: const LeiOSApp(),
  ));
}
