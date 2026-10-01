import 'dates.dart';
import 'models.dart';

/// Monday = bit 0 … Sunday = bit 6.
int weekdayBit(DateTime day) => 1 << (day.weekday - 1);

bool occursOn(Event e, DateTime day) {
  final d = dateOnly(day);
  if (e.weekdays == null) {
    return !dateOnly(e.date).isAfter(d) && !d.isAfter(dateOnly(e.endDate ?? e.date));
  }
  if (d.isBefore(dateOnly(e.date))) return false;
  if (e.until != null && d.isAfter(dateOnly(e.until!))) return false;
  return (e.weekdays! & weekdayBit(d)) != 0;
}

/// Occurrences on [day]: all-day first, then by start time, then title.
List<Event> eventsOn(Iterable<Event> events, DateTime day) {
  final list = events.where((e) => occursOn(e, day)).toList();
  list.sort((a, b) {
    if (a.allDay != b.allDay) return a.allDay ? -1 : 1;
    final c = (a.startMinutes ?? 0).compareTo(b.startMinutes ?? 0);
    return c != 0 ? c : a.title.toLowerCase().compareTo(b.title.toLowerCase());
  });
  return list;
}

/// 42 cells starting on the Monday on/before the 1st of the month.
List<DateTime> monthGrid(int year, int month) {
  final first = DateTime(year, month, 1);
  final start = addDays(first, -(first.weekday - 1));
  return [for (var i = 0; i < 42; i++) addDays(start, i)];
}

String formatMinutes(int minutes, {bool use24h = true}) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (use24h) return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:${m.toString().padLeft(2, '0')} ${h < 12 ? 'AM' : 'PM'}';
}
