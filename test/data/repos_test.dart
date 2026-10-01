import 'package:flutter_test/flutter_test.dart';
import 'package:leios/core/validation/validation.dart';
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
import 'package:powersync/powersync.dart';

import 'test_db.dart';

void main() {
  late PowerSyncDatabase db;
  var clock = DateTime.utc(2027, 3, 10, 12);
  String? uid() => testUser;
  DateTime now() => clock;

  setUp(() async {
    db = await openTestDb();
    clock = DateTime.utc(2027, 3, 10, 12);
  });
  tearDown(() => db.close());

  Future<int> count(String table) async => (await db.get('SELECT COUNT(*) c FROM $table'))['c'] as int;

  group('tasks', () {
    test('create validates, trims and stamps user_id', () async {
      final repo = TasksRepo(db, userId: uid, clock: now);
      await expectLater(repo.create(title: '  '), throwsA(isA<ValidationException>()));
      final id = await repo.create(title: '  Buy milk ', dueDate: DateTime(2027, 3, 11), urgent: true);
      final t = (await repo.get(id))!;
      expect(t.title, 'Buy milk');
      expect(t.urgent, isTrue);
      expect(t.dueDate, DateTime(2027, 3, 11));
      expect((await db.get('SELECT user_id FROM tasks WHERE id = ?', [id]))['user_id'], testUser);
    });

    test('completed_at follows status transitions', () async {
      final repo = TasksRepo(db, userId: uid, clock: now);
      final id = await repo.create(title: 'x');
      await repo.setStatus(id, TaskStatus.done);
      expect((await repo.get(id))!.completedAt, clock);
      await repo.setStatus(id, TaskStatus.todo);
      expect((await repo.get(id))!.completedAt, isNull);
    });

    test('advance cycles todo → doing → done → todo', () async {
      final repo = TasksRepo(db, userId: uid, clock: now);
      final id = await repo.create(title: 'x');
      expect(await repo.advance(id), TaskStatus.doing);
      expect(await repo.advance(id), TaskStatus.done);
      expect(await repo.advance(id), TaskStatus.todo);
    });

    test('update keeps title non-empty and can clear the due date', () async {
      final repo = TasksRepo(db, userId: uid, clock: now);
      final id = await repo.create(title: 'x', dueDate: DateTime(2027, 3, 11));
      await expectLater(repo.update(id, title: ' '), throwsA(isA<ValidationException>()));
      await repo.update(id, clearDueDate: true, title: ' y ');
      final t = (await repo.get(id))!;
      expect(t.dueDate, isNull);
      expect(t.title, 'y');
    });

    test('watch emits new data reactively', () async {
      final repo = TasksRepo(db, userId: uid, clock: now);
      final first = repo.watchAll().firstWhere((l) => l.length == 1);
      await repo.create(title: 'a');
      expect((await first).single.title, 'a');
    });
  });

  group('habits', () {
    test('validation and cascade delete', () async {
      final repo = HabitsRepo(db, userId: uid, clock: now);
      await expectLater(repo.create(name: ' '), throwsA(isA<ValidationException>()));
      await expectLater(repo.create(name: 'a', targetFrequency: 8), throwsA(isA<ValidationException>()));
      final id = await repo.create(name: 'Read', targetFrequency: 5);
      await repo.toggle(id, DateTime(2027, 3, 10));
      await repo.toggle(id, DateTime(2027, 3, 9));
      expect(await count('habit_completions'), 2);
      await repo.delete(id);
      expect(await count('habit_completions'), 0);
      expect(await count('habits'), 0);
    });

    test('toggle is idempotent per day with a deterministic id', () async {
      final repo = HabitsRepo(db, userId: uid, clock: now);
      final id = await repo.create(name: 'Read');
      expect(await repo.toggle(id, DateTime(2027, 3, 10)), isTrue);
      final rowId1 = (await db.get('SELECT id FROM habit_completions'))['id'];
      expect(await repo.toggle(id, DateTime(2027, 3, 10)), isFalse);
      expect(await count('habit_completions'), 0);
      await repo.toggle(id, DateTime(2027, 3, 10));
      expect((await db.get('SELECT id FROM habit_completions'))['id'], rowId1);
    });
  });

  group('feelings', () {
    test('daily upsert keeps one row and preserves notes when only rating changes', () async {
      final repo = FeelingsRepo(db, userId: uid, clock: now);
      await expectLater(repo.upsert(DateTime(2027, 3, 10), 6), throwsA(isA<ValidationException>()));
      await repo.upsert(DateTime(2027, 3, 10), 3, notes: 'meh', tags: 'Work, work, gym');
      await repo.upsert(DateTime(2027, 3, 10), 5);
      expect(await count('feelings'), 1);
      final f = (await db.get('SELECT * FROM feelings'));
      expect(f['rating'], 5);
      expect(f['notes'], 'meh');
      expect(f['tags'], 'Work, gym');
    });
  });

  group('goals', () {
    test('target normalized to period start and validated', () async {
      final repo = GoalsRepo(db, userId: uid, clock: now);
      await expectLater(repo.create(title: 'g', targetDate: DateTime(2027, 5, 17)), throwsA(isA<ValidationException>()));
      final id = await repo.create(title: 'g', targetDate: DateTime(2027, 5, 17), precision: GoalPrecision.quarter);
      expect((await db.get('SELECT target_date FROM goals WHERE id = ?', [id]))['target_date'], '2027-04-01');
    });

    test('steps keep contiguous per-goal order and cascade on goal delete', () async {
      final repo = GoalsRepo(db, userId: uid, clock: now);
      final g1 = await repo.create(title: 'g1');
      final g2 = await repo.create(title: 'g2');
      final a = await repo.addStep(g1, 'a');
      final b = await repo.addStep(g1, 'b');
      final c = await repo.addStep(g1, 'c');
      await repo.addStep(g2, 'other');
      await expectLater(repo.addStep(g1, ' '), throwsA(isA<ValidationException>()));

      Future<List<String>> order(String g) async => [
            for (final r in await db.getAll('SELECT title FROM goal_steps WHERE goal_id = ? ORDER BY sort_order', [g])) r['title'] as String
          ];
      expect(await order(g1), ['a', 'b', 'c']);
      await repo.moveStep(g1, b, 1);
      expect(await order(g1), ['a', 'c', 'b']);
      await repo.moveStep(g1, a, -1); // no-op
      await repo.deleteStep(g1, a);
      expect(await order(g1), ['c', 'b']);
      expect([for (final r in await db.getAll('SELECT sort_order FROM goal_steps WHERE goal_id = ? ORDER BY sort_order', [g1])) r['sort_order']], [0, 1]);
      expect(await order(g2), ['other']); // other group untouched, still 0
      expect((await db.get('SELECT sort_order FROM goal_steps WHERE goal_id = ?', [g2]))['sort_order'], 0);
      expect(c, isNotEmpty);

      await repo.delete(g1);
      expect(await count('goal_steps'), 1);
      expect(await count('goals'), 1);
    });

    test('advance cycles status', () async {
      final repo = GoalsRepo(db, userId: uid, clock: now);
      final id = await repo.create(title: 'g');
      expect(await repo.advance(id), GoalStatus.active);
      expect(await repo.advance(id), GoalStatus.completed);
      expect(await repo.advance(id), GoalStatus.pending);
    });
  });

  group('events', () {
    test('validation rules are enforced before writing', () async {
      final repo = EventsRepo(db, userId: uid, clock: now);
      final d = DateTime(2027, 3, 10);
      await expectLater(repo.create(title: 'e', date: d, startMinutes: 600, endMinutes: 600), throwsA(isA<ValidationException>()));
      await expectLater(repo.create(title: 'e', date: d, weekdays: 5, endDate: d), throwsA(isA<ValidationException>()));
      expect(await count('events'), 0);
      final id = await repo.create(title: 'Gym', date: d, startMinutes: 600, endMinutes: 660, weekdays: 5, until: DateTime(2027, 6, 1));
      final e = (await repo.get(id))!;
      expect(e.weekdays, 5);
      expect(e.until, DateTime(2027, 6, 1));
    });
  });

  group('notes', () {
    test('tags normalized and updated_at bumped on edit', () async {
      final repo = NotesRepo(db, userId: uid, clock: now);
      final id = await repo.create(title: 'n', tags: 'A, a, B');
      expect((await repo.get(id))!.tags, 'A, B');
      clock = DateTime.utc(2027, 3, 11);
      await repo.update(id, content: 'hello');
      expect((await repo.get(id))!.updatedAt, clock);
    });
  });

  group('list items', () {
    test('price only on wishlist; order is per list', () async {
      final repo = ListItemsRepo(db, userId: uid, clock: now);
      final w1 = await repo.create(ListKind.wishlist, title: 'Shoes', price: 50);
      final m1 = await repo.create(ListKind.media, title: 'Dune', price: 99);
      await repo.create(ListKind.wishlist, title: 'Hat');
      expect((await db.get('SELECT price FROM list_items WHERE id = ?', [w1]))['price'], 50);
      expect((await db.get('SELECT price FROM list_items WHERE id = ?', [m1]))['price'], isNull);
      expect((await db.get('SELECT sort_order FROM list_items WHERE id = ?', [m1]))['sort_order'], 0);
      final wish = await repo.watch(ListKind.wishlist).first;
      expect([for (final i in wish) i.sortOrder], [0, 1]);
      await repo.update(m1, setPrice: true, price: 10);
      expect((await db.get('SELECT price FROM list_items WHERE id = ?', [m1]))['price'], isNull);
    });

    test('delete renumbers within its list only', () async {
      final repo = ListItemsRepo(db, userId: uid, clock: now);
      final a = await repo.create(ListKind.dream, title: 'a');
      await repo.create(ListKind.dream, title: 'b');
      await repo.create(ListKind.dream, title: 'c');
      await repo.create(ListKind.media, title: 'm');
      await repo.delete(ListKind.dream, a);
      final rows = await db.getAll("SELECT title, sort_order FROM list_items WHERE list = 'dream' ORDER BY sort_order");
      expect([for (final r in rows) (r['title'], r['sort_order'])], [('b', 0), ('c', 1)]);
      expect((await db.get("SELECT sort_order FROM list_items WHERE list = 'media'"))['sort_order'], 0);
    });
  });

  group('finance', () {
    test('validations and fund rules', () async {
      final repo = FinanceRepo(db, userId: uid, clock: now);
      final d = DateTime(2027, 3, 10);
      await expectLater(repo.createTransaction(amount: 0, type: TxType.expense, date: d), throwsA(isA<ValidationException>()));
      await expectLater(repo.createFund(name: 'x', targetAmount: 0), throwsA(isA<ValidationException>()));
      await expectLater(repo.createTransaction(amount: 5, type: TxType.savingsContribution, date: d, savingsFundId: 'nope'), throwsA(isA<ValidationException>()));
      final fund = await repo.createFund(name: 'Trip', targetAmount: 1000);
      // fund id is dropped for non-savings types
      final e = await repo.createTransaction(amount: 5, type: TxType.expense, date: d, savingsFundId: fund);
      expect((await db.get('SELECT savings_fund_id FROM transactions WHERE id = ?', [e]))['savings_fund_id'], isNull);
      final s = await repo.createTransaction(amount: 100, type: TxType.savingsContribution, date: d, savingsFundId: fund);
      expect((await db.get('SELECT savings_fund_id FROM transactions WHERE id = ?', [s]))['savings_fund_id'], fund);
      // changing the type clears the fund
      await repo.updateTransaction(s, amount: 100, type: TxType.expense, date: d, savingsFundId: fund);
      expect((await db.get('SELECT savings_fund_id FROM transactions WHERE id = ?', [s]))['savings_fund_id'], isNull);
    });

    test('deleting a fund sets linked transactions to null and keeps them', () async {
      final repo = FinanceRepo(db, userId: uid, clock: now);
      final fund = await repo.createFund(name: 'Trip', targetAmount: 1000);
      await repo.createTransaction(amount: 100, type: TxType.savingsContribution, date: DateTime(2027, 3, 10), savingsFundId: fund);
      await repo.deleteFund(fund);
      expect(await count('savings_funds'), 0);
      expect(await count('transactions'), 1);
      expect((await db.get('SELECT savings_fund_id FROM transactions'))['savings_fund_id'], isNull);
    });
  });

  group('settings', () {
    test('upsert keeps one row with id = user_id and validates the format', () async {
      final repo = SettingsRepo(db, userId: uid, clock: now);
      await expectLater(repo.save(dateFormat: ''), throwsA(isA<ValidationException>()));
      await repo.save(displayName: ' Lei ');
      await repo.save(dateFormat: 'dd/MM/yyyy');
      expect(await count('settings'), 1);
      final s = await repo.watch().first;
      expect(s.displayName, 'Lei');
      expect(s.dateFormat, 'dd/MM/yyyy');
      expect((await db.get('SELECT id FROM settings'))['id'], testUser);
    });
  });
}
