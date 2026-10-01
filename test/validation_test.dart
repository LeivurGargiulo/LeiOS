import 'package:flutter_test/flutter_test.dart';
import 'package:leios/core/validation/validation.dart';
import 'package:leios/domain/models.dart';

void main() {
  test('requiredText trims and rejects blanks', () {
    expect(requiredText('  hi ', 'Title'), 'hi');
    expect(() => requiredText('   ', 'Title'), throwsA(isA<ValidationException>().having((e) => e.message, 'm', 'Title is required.')));
    expect(() => requiredText(null, 'Habit name'), throwsA(isA<ValidationException>()));
  });

  test('ranges', () {
    expect(rangeInt(7, 1, 7, 'Frequency'), 7);
    expect(() => rangeInt(0, 1, 7, 'Frequency'), throwsA(isA<ValidationException>()));
    expect(() => rangeInt(6, 1, 5, 'Rating'), throwsA(isA<ValidationException>()));
    expect(() => atLeast(0, 1, 'Amount'), throwsA(isA<ValidationException>()));
  });

  test('price only on wishlist', () {
    expect(priceFor(ListKind.wishlist, 10), 10);
    expect(priceFor(ListKind.wishlist, 0), 0);
    expect(priceFor(ListKind.media, 10), isNull);
    expect(() => priceFor(ListKind.wishlist, -1), throwsA(isA<ValidationException>()));
  });

  group('event times', () {
    final d = DateTime(2027, 3, 10);
    test('valid', () => validateEventTimes(date: d, startMinutes: 600, endMinutes: 660));
    test('end requires start', () => expect(() => validateEventTimes(date: d, endMinutes: 600), throwsA(isA<ValidationException>())));
    test('end after start on a single day', () {
      expect(() => validateEventTimes(date: d, startMinutes: 600, endMinutes: 600), throwsA(isA<ValidationException>().having((e) => e.message, 'm', 'End must be after the start.')));
    });
    test('multi-day may have earlier end time', () => validateEventTimes(date: d, endDate: DateTime(2027, 3, 11), startMinutes: 600, endMinutes: 540));
    test('end date not before start', () {
      expect(() => validateEventTimes(date: d, endDate: DateTime(2027, 3, 9)), throwsA(isA<ValidationException>().having((e) => e.message, 'm', 'End date must not be before the start.')));
    });
    test('minutes range', () => expect(() => validateEventTimes(date: d, startMinutes: 1440), throwsA(isA<ValidationException>())));
    test('recurring rules', () {
      validateEventTimes(date: d, weekdays: 5, until: d);
      expect(() => validateEventTimes(date: d, weekdays: 0), throwsA(isA<ValidationException>()));
      expect(() => validateEventTimes(date: d, weekdays: 128), throwsA(isA<ValidationException>()));
      expect(() => validateEventTimes(date: d, weekdays: 5, endDate: d), throwsA(isA<ValidationException>()));
      expect(() => validateEventTimes(date: d, weekdays: 5, until: DateTime(2027, 3, 9)), throwsA(isA<ValidationException>()));
      expect(() => validateEventTimes(date: d, until: d), throwsA(isA<ValidationException>()));
    });
  });

  test('goal target normalization', () {
    expect(normalizeGoalTarget(DateTime(2027, 5, 17), GoalPrecision.month).date, DateTime(2027, 5, 1));
    expect(normalizeGoalTarget(DateTime(2027, 5, 17), GoalPrecision.quarter).date, DateTime(2027, 4, 1));
    expect(normalizeGoalTarget(DateTime(2027, 5, 17), GoalPrecision.year).date, DateTime(2027, 1, 1));
    expect(normalizeGoalTarget(null, null).date, isNull);
    expect(() => normalizeGoalTarget(DateTime(2027), null), throwsA(isA<ValidationException>()));
    expect(() => normalizeGoalTarget(null, GoalPrecision.day), throwsA(isA<ValidationException>()));
  });

  test('date format validation', () {
    validateDateFormat('dd/MM/yyyy');
    expect(() => validateDateFormat(''), throwsA(isA<ValidationException>()));
  });

  test('fund id only for savings', () {
    expect(fundIdFor(TxType.savingsContribution, 'f'), 'f');
    expect(fundIdFor(TxType.expense, 'f'), isNull);
  });
}
