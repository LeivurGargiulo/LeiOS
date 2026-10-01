import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leios/app/app.dart';
import 'package:leios/app/providers.dart';
import 'package:leios/core/sync/auth_service.dart';
import 'package:powersync/powersync.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:leios/data/events_repo.dart';
import 'package:leios/data/feelings_repo.dart';
import 'package:leios/data/finance_repo.dart';
import 'package:leios/data/goals_repo.dart';
import 'package:leios/data/habits_repo.dart';
import 'package:leios/data/list_items_repo.dart';
import 'package:leios/data/notes_repo.dart';
import 'package:leios/data/settings_repo.dart';
import 'package:leios/data/tasks_repo.dart';
import 'package:leios/domain/models.dart';

import '../data/test_db.dart';

const testAuthUser = AuthUser(id: testUser, email: 'lei@example.com');

class Harness {
  Harness(this.db, this.prefs, this.auth);
  final PowerSyncDatabase db;
  final SharedPreferences prefs;
  final FakeAuthService auth;
}

/// Opens a temp DB + prefs (real async work, so it runs outside the fake-async zone).
Future<Harness> openHarness(WidgetTester tester, {bool signedIn = true}) async {
  late Harness h;
  await tester.runAsync(() async {
    SharedPreferences.setMockInitialValues({});
    h = Harness(await openTestDb(), await SharedPreferences.getInstance(), FakeAuthService(initial: signedIn ? testAuthUser : null));
  });
  addTearDown(() async {
    // Unmount first so no stream is watching the DB when it closes.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await h.db.close().timeout(const Duration(milliseconds: 300), onTimeout: () {});
    });
  });
  return h;
}

void setScreen(WidgetTester tester, double w, double h, {double textScale = 1.0}) {
  tester.view.physicalSize = Size(w, h);
  tester.view.devicePixelRatio = 1.0;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
}

Future<void> pumpApp(WidgetTester tester, Harness h) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      dbProvider.overrideWithValue(h.db),
      prefsProvider.overrideWithValue(h.prefs),
      authServiceProvider.overrideWithValue(h.auth),
      syncEnabledProvider.overrideWithValue(false),
    ],
    child: const LeiOSApp(),
  ));
  await settle(tester);
}

/// Lets streams + animations finish. DB streams need real time, so interleave runAsync.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump(const Duration(milliseconds: 100));
  }
  // Let route / sheet exit animations and snackbars finish.
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
}

/// Cheaper settle for large matrix tests.
Future<void> settleLight(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 25)));
    await tester.pump(const Duration(milliseconds: 120));
  }
  await tester.pump(const Duration(milliseconds: 400));
}

/// Fills every table so each screen renders real rows.
Future<void> seedAll(WidgetTester tester, Harness h) async {
  await tester.runAsync(() async {
    String? uid() => testUser;
    final today = DateTime.now();
    final tasks = TasksRepo(h.db, userId: uid);
    await tasks.create(title: 'A long task title that should wrap nicely on small screens with big text', urgent: true, important: true, dueDate: today);
    await tasks.create(title: 'Doing task', status: TaskStatus.doing, dueDate: DateTime(today.year, today.month, today.day + 2));
    await tasks.create(title: 'Overdue task', dueDate: DateTime(today.year, today.month, today.day - 3), important: true);
    await tasks.create(title: 'Long-term task', longTerm: true);
    await tasks.create(title: 'Finished', status: TaskStatus.done);
    final habits = HabitsRepo(h.db, userId: uid);
    final hid = await habits.create(name: 'Meditate', targetFrequency: 5);
    await habits.create(name: 'Read a very long habit name for the layout');
    await habits.toggle(hid, today);
    final feelings = FeelingsRepo(h.db, userId: uid);
    for (var i = 0; i < 5; i++) {
      await feelings.upsert(DateTime(today.year, today.month, today.day - i), 1 + i % 5, tags: 'calm, work', notes: 'note $i');
    }
    final goals = GoalsRepo(h.db, userId: uid);
    final gid = await goals.create(title: 'Run a marathon', targetDate: DateTime(today.year, 6, 1), precision: GoalPrecision.quarter);
    await goals.addStep(gid, 'Buy shoes');
    await goals.addStep(gid, 'Train weekly');
    await goals.create(title: 'Learn Dart', description: 'desc');
    final events = EventsRepo(h.db, userId: uid);
    await events.create(title: 'Standup', date: today, startMinutes: 540, endMinutes: 570, weekdays: 31);
    await events.create(title: 'Holiday', date: today, endDate: DateTime(today.year, today.month, today.day + 2));
    final notes = NotesRepo(h.db, userId: uid);
    await notes.create(title: 'Ideas', content: '# Heading\n\nSome **markdown** text', tags: 'work, ideas');
    final lists = ListItemsRepo(h.db, userId: uid);
    await lists.create(ListKind.media, title: 'Dune', category: 'book', notes: 'classic', url: 'example.com');
    await lists.create(ListKind.wishlist, title: 'Headphones', category: 'tech', price: 199);
    await lists.create(ListKind.dream, title: 'See the northern lights');
    await lists.create(ListKind.learning, title: 'Rust', category: 'programming');
    final fin = FinanceRepo(h.db, userId: uid);
    final fund = await fin.createFund(name: 'Trip to Japan', targetAmount: 5000);
    await fin.createTransaction(amount: 3000, type: TxType.income, category: 'Salary', date: today);
    await fin.createTransaction(amount: 120, type: TxType.expense, category: 'Groceries', date: today, note: 'weekly shop');
    await fin.createTransaction(amount: 500, type: TxType.savingsContribution, date: today, savingsFundId: fund);
    await SettingsRepo(h.db, userId: uid).save(displayName: 'Lei');
  });
}
