import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:leios/core/export/exporter.dart';
import 'package:leios/core/ids/ids.dart';
import 'package:leios/core/sync/auth_service.dart';
import 'package:leios/core/sync/supabase_connector.dart';
import 'package:leios/core/widgets/sync_status_chip.dart';

void main() {
  test('Postgres error classes 22, 23 and 42501 are non-recoverable; others retry', () {
    for (final c in ['22001', '22P02', '23503', '23505', '23514', '42501']) {
      expect(isFatalPostgresCode(c), isTrue, reason: c);
    }
    for (final c in [null, '08006', '40001', '57014', 'PGRST301', '42P01']) {
      expect(isFatalPostgresCode(c), isFalse, reason: '$c');
    }
  });

  group('deterministic ids', () {
    test('same natural key → same id; different user or key → different id', () {
      const u1 = '00000000-0000-0000-0000-0000000000a1';
      const u2 = '00000000-0000-0000-0000-0000000000b2';
      expect(feelingId(u1, '2027-03-10'), feelingId(u1, '2027-03-10'));
      expect(feelingId(u1, '2027-03-10'), isNot(feelingId(u1, '2027-03-11')));
      expect(feelingId(u1, '2027-03-10'), isNot(feelingId(u2, '2027-03-10')));
      expect(habitCompletionId(u1, 'h', '2027-03-10'), habitCompletionId(u1, 'h', '2027-03-10'));
      expect(habitCompletionId(u1, 'h', '2027-03-10'), isNot(habitCompletionId(u1, 'h2', '2027-03-10')));
      expect(feelingId(u1, 'd'), isNot(habitCompletionId(u1, 'd', 'd')));
      expect(settingsId(u1), u1);
      expect(newId(), isNot(newId()));
    });
  });

  group('export', () {
    test('contains the 12 tables, metadata, and real booleans', () {
      final json = jsonDecode(buildExportJson({
        'tasks': [
          {'id': 't', 'urgent': 1, 'important': 0, 'long_term': 0, 'title': 'x'}
        ],
        'goal_steps': [
          {'id': 's', 'done': 1}
        ],
      }, now: DateTime.utc(2027, 3, 10, 12))) as Map<String, dynamic>;
      expect(json['schema_version'], 3);
      expect(json['exported_at'], '2027-03-10T12:00:00.000Z');
      for (final t in ['tasks', 'habits', 'habit_completions', 'feelings', 'goals', 'goal_steps', 'events', 'notes', 'list_items', 'savings_funds', 'transactions', 'settings']) {
        expect(json.containsKey(t), isTrue, reason: t);
      }
      expect(json.containsKey('sync_errors'), isFalse);
      expect((json['tasks'] as List).single['urgent'], true);
      expect((json['tasks'] as List).single['important'], false);
      expect((json['goal_steps'] as List).single['done'], true);
      expect(json['habits'], isEmpty);
    });

    test('file name carries a UTC timestamp', () {
      expect(exportFileName(DateTime.utc(2027, 3, 10, 9, 5, 7)), 'leios-export-20270310-090507.json');
    });

    test('writeAtomic leaves no temp file behind', () async {
      final dir = Directory.systemTemp.createTempSync('leios_export_');
      final f = await writeAtomic(File('${dir.path}/out.json'), '{"a":1}');
      expect(await f.readAsString(), '{"a":1}');
      expect(File('${dir.path}/out.json.tmp').existsSync(), isFalse);
    });
  });

  test('sync chip state precedence: error > offline > syncing > synced', () {
    expect(syncStateOf(connected: true, busy: true, hasError: true), SyncState.error);
    expect(syncStateOf(connected: false, busy: true, hasError: false), SyncState.offline);
    expect(syncStateOf(connected: true, busy: true, hasError: false), SyncState.syncing);
    expect(syncStateOf(connected: true, busy: false, hasError: false), SyncState.synced);
  });

  test('AuthUser has value equality (token refresh must not look like a new user)', () {
    expect(const AuthUser(id: 'a', email: 'x@y.z'), const AuthUser(id: 'a', email: 'x@y.z'));
    expect(const AuthUser(id: 'a', email: 'x@y.z'), isNot(const AuthUser(id: 'b', email: 'x@y.z')));
  });

  test('friendly auth errors', () {
    expect(friendlyAuthError(Exception('Invalid login credentials')), contains('Incorrect email or password'));
    expect(friendlyAuthError(Exception('Email not confirmed')), contains('confirm your email'));
    expect(friendlyAuthError(Exception('SocketException: Failed host lookup')), contains('offline'));
    expect(friendlyAuthError(Exception('User already registered')), contains('already exists'));
  });
}
