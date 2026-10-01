/// Calendar-date helpers. A "date" is a `DateTime` at local midnight with no
/// meaningful time part; dates are stored as `YYYY-MM-DD` strings (spec §8).
library;

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Adds [days] calendar days (DST-safe, unlike `Duration`).
DateTime addDays(DateTime d, int days) => DateTime(d.year, d.month, d.day + days);

DateTime addMonths(DateTime d, int months) => DateTime(d.year, d.month + months, d.day);

String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime parseIsoDate(String s) {
  final p = s.substring(0, 10).split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

DateTime? tryParseIsoDate(Object? s) =>
    (s is String && s.length >= 10) ? parseIsoDate(s) : null;

/// Monday of the week containing [day].
DateTime weekStart(DateTime day) => addDays(dateOnly(day), -(day.weekday - 1));

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

int compareDates(DateTime a, DateTime b) => dateOnly(a).compareTo(dateOnly(b));

/// Instant (UTC ISO-8601 with `Z`) for storage.
String isoInstant(DateTime d) => d.toUtc().toIso8601String();

DateTime parseInstant(String s) => DateTime.parse(s).toUtc();

/// Local calendar date on which an instant falls.
DateTime localDateOf(DateTime instant) => dateOnly(instant.toLocal());
