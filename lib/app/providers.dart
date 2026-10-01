import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:powersync/powersync.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/sync/auth_service.dart';
import '../core/sync/supabase_connector.dart';
import '../data/events_repo.dart';
import '../data/feelings_repo.dart';
import '../data/finance_repo.dart';
import '../data/goals_repo.dart';
import '../data/habits_repo.dart';
import '../data/list_items_repo.dart';
import '../data/notes_repo.dart';
import '../data/settings_repo.dart';
import '../data/sync_errors_repo.dart';
import '../data/tasks_repo.dart';
import '../domain/models.dart';

// ---- Infrastructure (overridden in main()) ----

final dbProvider = Provider<PowerSyncDatabase>((ref) => throw UnimplementedError('dbProvider must be overridden'));
final prefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError('prefsProvider must be overridden'));
final authServiceProvider = Provider<AuthService>((ref) => throw UnimplementedError('authServiceProvider must be overridden'));

/// Whether to connect to PowerSync Cloud (false in tests / mock login).
final syncEnabledProvider = Provider<bool>((ref) => true);

// ---- Auth ----

class AuthNotifier extends Notifier<AuthUser?> {
  StreamSubscription<AuthUser?>? _sub;

  @override
  AuthUser? build() {
    final svc = ref.watch(authServiceProvider);
    _sub = svc.changes.listen((u) => state = u);
    ref.onDispose(() => _sub?.cancel());
    return svc.currentUser;
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthUser?>(AuthNotifier.new);

/// Connects PowerSync while signed in. Reads are always local, so the app works offline.
final syncControllerProvider = Provider<void>((ref) {
  final user = ref.watch(authProvider);
  final enabled = ref.watch(syncEnabledProvider);
  final db = ref.watch(dbProvider);
  if (user != null && enabled) {
    unawaited(db.connect(connector: SupabaseConnector(db)));
  }
});

// ---- Repositories ----

String? _uid(Ref ref) => ref.read(authProvider)?.id;

final tasksRepoProvider = Provider((ref) => TasksRepo(ref.watch(dbProvider), userId: () => _uid(ref)));
final habitsRepoProvider = Provider((ref) => HabitsRepo(ref.watch(dbProvider), userId: () => _uid(ref)));
final feelingsRepoProvider = Provider((ref) => FeelingsRepo(ref.watch(dbProvider), userId: () => _uid(ref)));
final goalsRepoProvider = Provider((ref) => GoalsRepo(ref.watch(dbProvider), userId: () => _uid(ref)));
final eventsRepoProvider = Provider((ref) => EventsRepo(ref.watch(dbProvider), userId: () => _uid(ref)));
final notesRepoProvider = Provider((ref) => NotesRepo(ref.watch(dbProvider), userId: () => _uid(ref)));
final listItemsRepoProvider = Provider((ref) => ListItemsRepo(ref.watch(dbProvider), userId: () => _uid(ref)));
final financeRepoProvider = Provider((ref) => FinanceRepo(ref.watch(dbProvider), userId: () => _uid(ref)));
final settingsRepoProvider = Provider((ref) => SettingsRepo(ref.watch(dbProvider), userId: () => _uid(ref)));
final syncErrorsRepoProvider = Provider((ref) => SyncErrorsRepo(ref.watch(dbProvider)));

// ---- Reactive data ----

final tasksProvider = StreamProvider<List<Task>>((ref) => ref.watch(tasksRepoProvider).watchAll());
final habitsProvider = StreamProvider<List<Habit>>((ref) => ref.watch(habitsRepoProvider).watchHabits());
final completionsProvider =
    StreamProvider<List<HabitCompletion>>((ref) => ref.watch(habitsRepoProvider).watchCompletions());
final feelingsProvider = StreamProvider<List<Feeling>>((ref) => ref.watch(feelingsRepoProvider).watchAll());
final goalsProvider = StreamProvider<List<Goal>>((ref) => ref.watch(goalsRepoProvider).watchGoals());
final goalStepsProvider = StreamProvider<List<GoalStep>>((ref) => ref.watch(goalsRepoProvider).watchSteps());
final eventsProvider = StreamProvider<List<Event>>((ref) => ref.watch(eventsRepoProvider).watchAll());
final notesProvider = StreamProvider<List<Note>>((ref) => ref.watch(notesRepoProvider).watchAll());
final listItemsProvider = StreamProvider.family<List<ListItem>, ListKind>(
    (ref, kind) => ref.watch(listItemsRepoProvider).watch(kind));
final transactionsProvider = StreamProvider<List<Tx>>((ref) => ref.watch(financeRepoProvider).watchTransactions());
final fundsProvider = StreamProvider<List<SavingsFund>>((ref) => ref.watch(financeRepoProvider).watchFunds());
final settingsProvider = StreamProvider<AppSettings>((ref) => ref.watch(settingsRepoProvider).watch());
final syncErrorsProvider = StreamProvider<List<SyncErrorRow>>((ref) => ref.watch(syncErrorsRepoProvider).watch());
final pendingOpsProvider = StreamProvider<int>((ref) => ref.watch(syncErrorsRepoProvider).watchPendingCount());

final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final db = ref.watch(dbProvider);
  return db.statusStream;
});

/// The user's date pattern with a safe default while settings load.
final dateFormatProvider = Provider<String>(
    (ref) => ref.watch(settingsProvider).maybeWhen(data: (s) => s.dateFormat, orElse: () => 'yyyy-MM-dd'));

final displayNameProvider = Provider<String>(
    (ref) => ref.watch(settingsProvider).maybeWhen(data: (s) => s.displayName, orElse: () => ''));

// ---- Local preferences ----

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';
  @override
  ThemeMode build() {
    final v = ref.watch(prefsProvider).getString(_key);
    return ThemeMode.values.firstWhere((m) => m.name == v, orElse: () => ThemeMode.system);
  }

  Future<void> set(ThemeMode m) async {
    state = m;
    await ref.read(prefsProvider).setString(_key, m.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

/// Remembers a string preference (last tab / view) under [key].
class PrefNotifier extends Notifier<String?> {
  PrefNotifier(this.key);
  final String key;
  @override
  String? build() => ref.watch(prefsProvider).getString(key);
  Future<void> set(String v) async {
    state = v;
    await ref.read(prefsProvider).setString(key, v);
  }
}

final prefProvider = NotifierProvider.family<PrefNotifier, String?, String>(PrefNotifier.new);

/// Unsaved editor drafts keyed by entity (e.g. `note:<id>`), so rotating / resizing keeps edits (spec §9.3).
class DraftsNotifier extends Notifier<Map<String, Map<String, Object?>>> {
  @override
  Map<String, Map<String, Object?>> build() => {};
  void put(String key, Map<String, Object?> draft) => state = {...state, key: draft};
  void clear(String key) {
    if (!state.containsKey(key)) return;
    state = {...state}..remove(key);
  }
}

final draftsProvider = NotifierProvider<DraftsNotifier, Map<String, Map<String, Object?>>>(DraftsNotifier.new);
