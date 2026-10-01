import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../domain/events.dart' as ev;

/// Single point for date formatting (spec §2.1). Falls back safely on a bad pattern.
String formatDateWith(String pattern, DateTime d) {
  try {
    return DateFormat(pattern).format(d);
  } catch (_) {
    return DateFormat('yyyy-MM-dd').format(d);
  }
}

/// `String Function(DateTime)` bound to the user's date format.
final formatDateProvider = Provider<String Function(DateTime)>((ref) {
  final pattern = ref.watch(dateFormatProvider);
  return (d) => formatDateWith(pattern, d);
});

/// Times follow the device's 12/24-hour setting.
String formatTimeOfDayMinutes(BuildContext context, int minutes) {
  final use24 = MediaQuery.alwaysUse24HourFormatOf(context);
  return ev.formatMinutes(minutes, use24h: use24);
}

/// Short weekday name for ISO weekday index [i] (0 = Monday).
String weekdayShort(int i) => DateFormat.E().format(DateTime(2024, 1, 1 + i));

String longDate(DateTime d) => DateFormat('EEEE, d MMMM').format(d);
String monthYear(DateTime d) => DateFormat('MMMM yyyy').format(d);

/// Whole-number money (amounts are integers in the smallest unit chosen by the user).
String formatMoney(int amount) => NumberFormat.decimalPattern().format(amount);
