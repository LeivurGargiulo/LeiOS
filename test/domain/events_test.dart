import 'package:flutter_test/flutter_test.dart';
import 'package:leios/domain/events.dart';
import 'package:leios/domain/models.dart';

Event ev({String id = 'e', String title = 't', required DateTime date, DateTime? end, int? start, int? endM, int? wd, DateTime? until}) =>
    Event(id: id, title: title, date: date, endDate: end, startMinutes: start, endMinutes: endM, weekdays: wd, until: until);

void main() {
  group('occursOn', () {
    test('single day', () {
      final e = ev(date: DateTime(2027, 3, 10));
      expect(occursOn(e, DateTime(2027, 3, 10)), isTrue);
      expect(occursOn(e, DateTime(2027, 3, 11)), isFalse);
    });
    test('multi-day inclusive', () {
      final e = ev(date: DateTime(2027, 3, 10), end: DateTime(2027, 3, 12));
      expect([for (final d in [9, 10, 11, 12, 13]) occursOn(e, DateTime(2027, 3, d))], [false, true, true, true, false]);
    });
    test('recurring respects mask, start and until', () {
      // Mon(1) + Wed(4) = 5, starting Mon 2027-03-08, until Wed 2027-03-17
      final e = ev(date: DateTime(2027, 3, 8), wd: 5, until: DateTime(2027, 3, 17));
      expect(occursOn(e, DateTime(2027, 3, 8)), isTrue); // Mon
      expect(occursOn(e, DateTime(2027, 3, 9)), isFalse); // Tue
      expect(occursOn(e, DateTime(2027, 3, 10)), isTrue); // Wed
      expect(occursOn(e, DateTime(2027, 3, 15)), isTrue); // Mon
      expect(occursOn(e, DateTime(2027, 3, 17)), isTrue); // Wed (until inclusive)
      expect(occursOn(e, DateTime(2027, 3, 22)), isFalse); // after until
      expect(occursOn(e, DateTime(2027, 3, 1)), isFalse); // before start
    });
    test('Sunday is bit 6', () {
      final e = ev(date: DateTime(2027, 3, 1), wd: 64);
      expect(occursOn(e, DateTime(2027, 3, 14)), isTrue); // Sunday
      expect(occursOn(e, DateTime(2027, 3, 13)), isFalse);
    });
    test('open-ended recurring', () {
      final e = ev(date: DateTime(2027, 3, 1), wd: 127);
      expect(occursOn(e, DateTime(2035, 1, 1)), isTrue);
    });
  });

  test('eventsOn sorts all-day first, then start, then title', () {
    final day = DateTime(2027, 3, 10);
    final list = eventsOn([
      ev(id: '1', title: 'b', date: day, start: 600),
      ev(id: '2', title: 'a', date: day, start: 600),
      ev(id: '3', title: 'z', date: day),
      ev(id: '4', title: 'c', date: day, start: 60),
    ], day);
    expect([for (final e in list) e.id], ['3', '4', '2', '1']);
  });

  group('monthGrid', () {
    test('always 42 cells starting on Monday', () {
      for (final (y, m) in [(2027, 2), (2027, 3), (2026, 2), (2027, 8), (2024, 2), (2027, 12)]) {
        final g = monthGrid(y, m);
        expect(g.length, 42);
        expect(g.first.weekday, DateTime.monday);
        expect(g.any((d) => d.year == y && d.month == m && d.day == 1), isTrue);
      }
    });
    test('Feb 2027 begins Mon Feb 1', () => expect(monthGrid(2027, 2).first, DateTime(2027, 2, 1)));
    test('March 2027 begins Mon Mar 1 minus 0 (Mar 1 is Monday)', () => expect(monthGrid(2027, 3).first, DateTime(2027, 3, 1)));
    test('Jan 2027 starts in December', () => expect(monthGrid(2027, 1).first, DateTime(2026, 12, 28)));
  });

  test('formatMinutes', () {
    expect(formatMinutes(0), '00:00');
    expect(formatMinutes(13 * 60 + 5), '13:05');
    expect(formatMinutes(0, use24h: false), '12:00 AM');
    expect(formatMinutes(13 * 60 + 5, use24h: false), '1:05 PM');
  });
}
