import 'package:flutter_test/flutter_test.dart';
import 'package:leios/domain/goals.dart';
import 'package:leios/domain/models.dart';

Goal goal({DateTime? target, GoalPrecision? p, GoalStatus s = GoalStatus.pending, DateTime? created, String id = 'g'}) =>
    Goal(id: id, title: 't', targetDate: target, precision: p, status: s, createdAt: created ?? DateTime.utc(2027, 1, 1));

GoalStep step(bool done) => GoalStep(id: '$done${done.hashCode}', goalId: 'g', title: 's', done: done, sortOrder: 0);

void main() {
  group('periods', () {
    final d = DateTime(2027, 5, 17);
    test('start', () {
      expect(periodStart(d, GoalPrecision.day), DateTime(2027, 5, 17));
      expect(periodStart(d, GoalPrecision.month), DateTime(2027, 5, 1));
      expect(periodStart(d, GoalPrecision.quarter), DateTime(2027, 4, 1));
      expect(periodStart(d, GoalPrecision.year), DateTime(2027, 1, 1));
    });
    test('quarter edges', () {
      expect(periodStart(DateTime(2027, 3, 31), GoalPrecision.quarter), DateTime(2027, 1, 1));
      expect(periodStart(DateTime(2027, 12, 31), GoalPrecision.quarter), DateTime(2027, 10, 1));
    });
    test('end is exclusive', () {
      expect(periodEnd(DateTime(2027, 5, 17), GoalPrecision.day), DateTime(2027, 5, 18));
      expect(periodEnd(DateTime(2027, 12, 1), GoalPrecision.month), DateTime(2028, 1, 1));
      expect(periodEnd(DateTime(2027, 10, 1), GoalPrecision.quarter), DateTime(2028, 1, 1));
      expect(periodEnd(DateTime(2027, 1, 1), GoalPrecision.year), DateTime(2028, 1, 1));
    });
    test('quarterOf', () => expect(quarterOf(DateTime(2027, 4, 1)), 1));
    test('labels', () {
      String f(DateTime x) => 'F';
      expect(periodLabel(d, GoalPrecision.day, f), 'F');
      expect(periodLabel(d, GoalPrecision.month, f), '~May 2027');
      expect(periodLabel(d, GoalPrecision.quarter, f), '~2027-Q2');
      expect(periodLabel(d, GoalPrecision.year, f), '~2027');
    });
  });

  group('goalProgress', () {
    final now = DateTime.utc(2027, 1, 1);
    test('steps ratio wins', () {
      final g = goal(target: DateTime(2027, 1, 1), p: GoalPrecision.year);
      expect(goalProgress(g, [step(true), step(false), step(false), step(true)], now), 50);
    });
    test('null without steps or target', () => expect(goalProgress(goal(), [], now), isNull));
    test('time-based for each precision is clamped 0..100', () {
      for (final p in GoalPrecision.values) {
        final g = goal(target: DateTime(2030, 6, 15), p: p, created: DateTime.utc(2029, 1, 1));
        final v = goalProgress(g, [], DateTime.utc(2029, 6, 1))!;
        expect(v, inInclusiveRange(0, 100));
      }
    });
    test('before creation is 0, after end is 100', () {
      final g = goal(target: DateTime(2027, 12, 1), p: GoalPrecision.month, created: DateTime.utc(2027, 6, 1));
      expect(goalProgress(g, [], DateTime.utc(2027, 1, 1)), 0);
      expect(goalProgress(g, [], DateTime.utc(2030, 1, 1)), 100);
    });
    test('end <= start is 100', () {
      final g = goal(target: DateTime(2020, 1, 1), p: GoalPrecision.day, created: DateTime.utc(2027, 1, 1));
      expect(goalProgress(g, [], now), 100);
    });
    test('formatProgress', () {
      expect(formatProgress(null), '-');
      expect(formatProgress(66.6), '67%');
    });
  });

  test('yearBoard groups and counts only goals with a target', () {
    final goals = [
      goal(id: 'a', target: DateTime(2027, 1, 1), p: GoalPrecision.quarter, s: GoalStatus.completed),
      goal(id: 'b', target: DateTime(2027, 4, 1), p: GoalPrecision.month),
      goal(id: 'c', target: DateTime(2027, 1, 1), p: GoalPrecision.year),
      goal(id: 'd'),
      goal(id: 'e', target: DateTime(2028, 1, 1), p: GoalPrecision.year),
    ];
    final b = yearBoard(goals, 2027);
    expect(b.total, 3);
    expect(b.completed, 1);
    expect(b.percent, 33);
    expect([for (final g in b.quarters[0]) g.id], ['a']);
    expect([for (final g in b.quarters[1]) g.id], ['b']);
    expect([for (final g in b.wholeYear) g.id], ['c']);
    expect([for (final g in b.noTarget) g.id], ['d']);
    expect(yearBoard(goals, 2030).percent, 0);
  });
}
