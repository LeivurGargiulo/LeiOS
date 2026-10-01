import 'package:intl/intl.dart';

import '../../domain/dates.dart';
import '../../domain/goals.dart';
import '../../domain/models.dart';
import '../../domain/tags.dart';

class ValidationException implements Exception {
  ValidationException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Trimmed non-empty text or throws `"<Label> is required."`.
String requiredText(String? value, String label) {
  final v = (value ?? '').trim();
  if (v.isEmpty) throw ValidationException('$label is required.');
  return v;
}

int rangeInt(int value, int min, int max, String label) {
  if (value < min || value > max) {
    throw ValidationException('$label must be between $min and $max.');
  }
  return value;
}

int atLeast(int value, int min, String label) {
  if (value < min) throw ValidationException('$label must be at least $min.');
  return value;
}

/// Wishlist-only price; any other list stores null.
int? priceFor(ListKind list, int? price) {
  if (list != ListKind.wishlist || price == null) return null;
  if (price < 0) throw ValidationException('Price must be 0 or more.');
  return price;
}

void validateEventTimes({
  required DateTime date,
  DateTime? endDate,
  int? startMinutes,
  int? endMinutes,
  int? weekdays,
  DateTime? until,
}) {
  for (final m in [startMinutes, endMinutes]) {
    if (m != null && (m < 0 || m > 1439)) {
      throw ValidationException('Time must be between 00:00 and 23:59.');
    }
  }
  if (endMinutes != null && startMinutes == null) {
    throw ValidationException('An end time requires a start time.');
  }
  if (endDate != null && dateOnly(endDate).isBefore(dateOnly(date))) {
    throw ValidationException('End date must not be before the start.');
  }
  final singleDay = endDate == null || sameDay(endDate, date);
  if (singleDay && endMinutes != null && endMinutes <= startMinutes!) {
    throw ValidationException('End must be after the start.');
  }
  if (weekdays != null) {
    if (weekdays < 1 || weekdays > 127) {
      throw ValidationException('Pick at least one weekday.');
    }
    if (endDate != null) {
      throw ValidationException('Repeating events cannot have an end date.');
    }
    if (until != null && dateOnly(until).isBefore(dateOnly(date))) {
      throw ValidationException('"Until" must not be before the start.');
    }
  } else if (until != null) {
    throw ValidationException('"Until" only applies to repeating events.');
  }
}

/// Both-or-neither target; the date is normalised to the period's first day.
({DateTime? date, GoalPrecision? precision}) normalizeGoalTarget(DateTime? date, GoalPrecision? precision) {
  if ((date == null) != (precision == null)) {
    throw ValidationException('Target date and precision go together.');
  }
  if (date == null) return (date: null, precision: null);
  return (date: periodStart(date, precision!), precision: precision);
}

void validateDateFormat(String pattern) {
  try {
    if (pattern.trim().isEmpty) throw const FormatException();
    DateFormat(pattern).format(DateTime(2027, 3, 14));
  } catch (_) {
    throw ValidationException('Invalid date format.');
  }
}

/// `savings_fund_id` survives only for savings contributions.
String? fundIdFor(TxType type, String? fundId) =>
    type == TxType.savingsContribution ? fundId : null;

String normalizedTags(String raw) => normalizeTags(raw);
