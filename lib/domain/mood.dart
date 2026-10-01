import 'dates.dart';
import 'models.dart';

const weekdayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

double? moodAverage(Iterable<Feeling> entries) {
  if (entries.isEmpty) return null;
  return entries.fold<int>(0, (a, e) => a + e.rating) / entries.length;
}

/// Best/worst weekday by average rating. Ties keep the earliest day of the week.
({String? best, String? worst}) bestWorstWeekday(Iterable<Feeling> entries) {
  final sum = List<int>.filled(7, 0);
  final cnt = List<int>.filled(7, 0);
  for (final e in entries) {
    final i = e.date.weekday - 1;
    sum[i] += e.rating;
    cnt[i]++;
  }
  int? best, worst;
  double? bestAvg, worstAvg;
  for (var i = 0; i < 7; i++) {
    if (cnt[i] == 0) continue;
    final avg = sum[i] / cnt[i];
    if (bestAvg == null || avg > bestAvg) {
      bestAvg = avg;
      best = i;
    }
    if (worstAvg == null || avg < worstAvg) {
      worstAvg = avg;
      worst = i;
    }
  }
  return (
    best: best == null ? null : weekdayNames[best],
    worst: worst == null ? null : weekdayNames[worst],
  );
}

/// Last 30 days ending today (oldest first); null where there is no entry.
List<({DateTime day, int? rating})> moodTrend(Iterable<Feeling> entries, DateTime today, {int days = 30}) {
  final byDay = {for (final e in entries) dateOnly(e.date): e.rating};
  final t = dateOnly(today);
  return [
    for (var i = days - 1; i >= 0; i--)
      (day: addDays(t, -i), rating: byDay[addDays(t, -i)]),
  ];
}
