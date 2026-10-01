import 'package:flutter_test/flutter_test.dart';
import 'package:leios/domain/finance.dart';
import 'package:leios/domain/mood.dart';
import 'package:leios/domain/models.dart';
import 'package:leios/domain/ordering.dart';

Tx tx(int amount, TxType type, {String cat = '', DateTime? date, String? fund}) =>
    Tx(id: '$amount$type$cat', amount: amount, type: type, category: cat, date: date ?? DateTime(2027, 3, 5), savingsFundId: fund);

Feeling f(DateTime d, int r) => Feeling(id: '$d', date: d, rating: r);

void main() {
  group('monthlySummary', () {
    test('totals, balance, categories sorted desc then alpha', () {
      final s = monthlySummary([
        tx(1000, TxType.income),
        tx(200, TxType.expense, cat: 'Food'),
        tx(200, TxType.expense, cat: 'Bills'),
        tx(50, TxType.expense, cat: '  '),
        tx(100, TxType.savingsContribution),
        tx(999, TxType.expense, date: DateTime(2027, 4, 1)),
      ], 2027, 3);
      expect(s.income, 1000);
      expect(s.expenses, 450);
      expect(s.saved, 100);
      expect(s.balance, 450);
      expect([for (final c in s.byCategory) c.category], ['Bills', 'Food', 'Uncategorized']);
    });
    test('empty month', () => expect(monthlySummary([], 2027, 3).balance, 0));
  });

  test('fundProgress clamps', () {
    expect(fundProgress(50, 200), 25);
    expect(fundProgress(500, 200), 100);
    expect(fundProgress(5, 0), 0);
    expect(fundProgress(-5, 10), 0);
  });

  test('fundCurrent sums only that fund savings', () {
    expect(fundCurrent([tx(10, TxType.savingsContribution, fund: 'a'), tx(5, TxType.savingsContribution, fund: 'b'), tx(7, TxType.expense)], 'a'), 10);
  });

  group('mood', () {
    test('average', () {
      expect(moodAverage([]), isNull);
      expect(moodAverage([f(DateTime(2027, 3, 1), 4), f(DateTime(2027, 3, 2), 2)]), 3);
    });
    test('best/worst weekday with tie keeping earliest', () {
      // 2027-03-08 Mon, 03-09 Tue, 03-10 Wed
      final r = bestWorstWeekday([f(DateTime(2027, 3, 8), 3), f(DateTime(2027, 3, 9), 3), f(DateTime(2027, 3, 10), 3)]);
      expect(r.best, 'Monday');
      expect(r.worst, 'Monday');
    });
    test('best/worst distinct', () {
      final r = bestWorstWeekday([f(DateTime(2027, 3, 8), 1), f(DateTime(2027, 3, 12), 5), f(DateTime(2027, 3, 9), 3)]);
      expect(r.best, 'Friday');
      expect(r.worst, 'Monday');
      expect(bestWorstWeekday([]).best, isNull);
    });
    test('trend has 30 days with gaps', () {
      final t = moodTrend([f(DateTime(2027, 3, 10), 4)], DateTime(2027, 3, 10));
      expect(t.length, 30);
      expect(t.last.rating, 4);
      expect(t.first.rating, isNull);
      expect(t.first.day, DateTime(2027, 2, 9));
    });
  });

  group('ordering', () {
    test('append', () => expect(appendOrder(3), 3));
    test('move swaps neighbours', () {
      expect(planMove(['a', 'b', 'c'], 'b', 1), [(id: 'b', sortOrder: 2), (id: 'c', sortOrder: 1)]);
      expect(planMove(['a', 'b', 'c'], 'a', -1), isEmpty);
      expect(planMove(['a', 'b', 'c'], 'c', 1), isEmpty);
      expect(planMove(['a'], 'zzz', 1), isEmpty);
    });
    test('delete renumbers the tail', () {
      expect(planRenumberAfterDelete(['a', 'b', 'c', 'd'], 'b'), [(id: 'c', sortOrder: 1), (id: 'd', sortOrder: 2)]);
      expect(planRenumberAfterDelete(['a', 'b'], 'b'), isEmpty);
    });
    test('reorder renumbers changed rows', () {
      expect(planReorder(['a', 'b', 'c'], 0, 2), [(id: 'b', sortOrder: 0), (id: 'c', sortOrder: 1), (id: 'a', sortOrder: 2)]);
    });
  });
}
