import 'package:flutter_test/flutter_test.dart';
import 'package:leios/domain/streak.dart';

void main() {
  final today = DateTime(2027, 3, 10);
  DateTime d(int day) => DateTime(2027, 3, day);

  group('streak', () {
    test('empty is 0', () => expect(streak({}, today), 0));
    test('counts including today', () => expect(streak({d(10), d(9), d(8)}, today), 3));
    test('stays alive from yesterday when today unmarked', () => expect(streak({d(9), d(8)}, today), 2));
    test('broken by a gap', () => expect(streak({d(10), d(8)}, today), 1));
    test('older than yesterday is 0', () => expect(streak({d(7)}, today), 0));
    test('crosses month boundary', () {
      expect(streak({DateTime(2027, 2, 28), DateTime(2027, 3, 1), DateTime(2027, 3, 2)}, DateTime(2027, 3, 2)), 3);
    });
    test('ignores time of day', () => expect(streak({DateTime(2027, 3, 10, 22)}, today), 1));
  });

  group('weeklyCount', () {
    test('counts only the Monday-based current week', () {
      // 2027-03-10 is a Wednesday; week = Mar 8..14
      expect(weeklyCount([d(7), d(8), d(10), d(14), d(15)], today), 3);
    });
    test('counts dates after today in the same week too', () => expect(weeklyCount([d(12)], today), 1));
    test('duplicates count once', () => expect(weeklyCount([d(8), DateTime(2027, 3, 8, 5)], today), 1));
  });
}
