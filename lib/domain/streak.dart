import 'dates.dart';

/// Consecutive-day streak ending today, or yesterday if today isn't marked yet.
int streak(Set<DateTime> dates, DateTime today) {
  final set = {for (final d in dates) dateOnly(d)};
  var cursor = dateOnly(today);
  if (!set.contains(cursor)) cursor = addDays(cursor, -1);
  var n = 0;
  while (set.contains(cursor)) {
    n++;
    cursor = addDays(cursor, -1);
  }
  return n;
}

/// Completions in the Monday-based week containing [today].
int weeklyCount(Iterable<DateTime> completions, DateTime today) {
  final start = weekStart(today);
  final end = addDays(start, 6);
  return {for (final d in completions) dateOnly(d)}
      .where((d) => !d.isBefore(start) && !d.isAfter(end))
      .length;
}
