import 'dates.dart';
import 'models.dart';

/// First day of the period containing [date].
DateTime periodStart(DateTime date, GoalPrecision p) => switch (p) {
      GoalPrecision.day => dateOnly(date),
      GoalPrecision.month => DateTime(date.year, date.month, 1),
      GoalPrecision.quarter => DateTime(date.year, ((date.month - 1) ~/ 3) * 3 + 1, 1),
      GoalPrecision.year => DateTime(date.year, 1, 1),
    };

/// EXCLUSIVE end of the period: the first day after it.
DateTime periodEnd(DateTime start, GoalPrecision p) => switch (p) {
      GoalPrecision.day => addDays(start, 1),
      GoalPrecision.month => DateTime(start.year, start.month + 1, 1),
      GoalPrecision.quarter => DateTime(start.year, start.month + 3, 1),
      GoalPrecision.year => DateTime(start.year + 1, 1, 1),
    };

int quarterOf(DateTime start) => (start.month - 1) ~/ 3;

const _monthAbbr = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// Label for a goal target. [formatDay] renders `day` precision (user's date format).
String periodLabel(DateTime date, GoalPrecision p, String Function(DateTime) formatDay) {
  final s = periodStart(date, p);
  return switch (p) {
    GoalPrecision.day => formatDay(s),
    GoalPrecision.month => '~${_monthAbbr[s.month - 1]} ${s.year}',
    GoalPrecision.quarter => '~${s.year}-Q${quarterOf(s) + 1}',
    GoalPrecision.year => '~${s.year}',
  };
}

/// Progress 0..100, or null when there are no steps and no target.
double? goalProgress(Goal goal, List<GoalStep> steps, DateTime now) {
  if (steps.isNotEmpty) {
    return steps.where((s) => s.done).length / steps.length * 100;
  }
  final target = goal.targetDate;
  final precision = goal.precision;
  if (target == null || precision == null) return null;
  final start = goal.createdAt.toUtc();
  final endLocal = periodEnd(periodStart(target, precision), precision);
  final end = DateTime(endLocal.year, endLocal.month, endLocal.day).toUtc();
  if (!end.isAfter(start)) return 100;
  final p = now.toUtc().difference(start).inMicroseconds / end.difference(start).inMicroseconds * 100;
  return p.clamp(0, 100).toDouble();
}

String formatProgress(double? p) => p == null ? '-' : '${p.round()}%';

class YearBoard {
  YearBoard({
    required this.year,
    required this.completed,
    required this.total,
    required this.percent,
    required this.wholeYear,
    required this.quarters,
    required this.noTarget,
  });
  final int year;
  final int completed;
  final int total;
  final int percent;
  final List<Goal> wholeYear;
  final List<List<Goal>> quarters; // Q1..Q4
  final List<Goal> noTarget;
}

YearBoard yearBoard(Iterable<Goal> goals, int year) {
  final withTarget = goals.where((g) => g.targetDate != null && g.targetDate!.year == year).toList();
  final completed = withTarget.where((g) => g.status == GoalStatus.completed).length;
  final quarters = List.generate(4, (_) => <Goal>[]);
  final whole = <Goal>[];
  for (final g in withTarget) {
    if (g.precision == GoalPrecision.year) {
      whole.add(g);
    } else {
      quarters[quarterOf(g.targetDate!)].add(g);
    }
  }
  return YearBoard(
    year: year,
    completed: completed,
    total: withTarget.length,
    percent: withTarget.isEmpty ? 0 : (completed / withTarget.length * 100).round(),
    wholeYear: whole,
    quarters: quarters,
    noTarget: goals.where((g) => g.targetDate == null).toList(),
  );
}
