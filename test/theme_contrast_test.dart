import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leios/core/design/theme.dart';

double _lum(Color c) {
  double ch(double v) => v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double contrast(Color a, Color b) {
  final l1 = _lum(a), l2 = _lum(b);
  final hi = math.max(l1, l2), lo = math.min(l1, l2);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  for (final brightness in Brightness.values) {
    test('WCAG AA (4.5:1) for the role pairings the UI uses — ${brightness.name}', () {
      final s = buildTheme(brightness).colorScheme;
      final pairs = <String, (Color, Color)>{
        'onSurface/surface': (s.onSurface, s.surface),
        'onSurfaceVariant/surface': (s.onSurfaceVariant, s.surface),
        'onSurface/surfaceContainerHighest (cards)': (s.onSurface, s.surfaceContainerHighest),
        'onSurfaceVariant/surfaceContainerHighest (cards)': (s.onSurfaceVariant, s.surfaceContainerHighest),
        'onPrimary/primary': (s.onPrimary, s.primary),
        'primary/surface (income, links)': (s.primary, s.surface),
        'primary/surfaceContainerHighest (income in cards)': (s.primary, s.surfaceContainerHighest),
        'onPrimaryContainer/primaryContainer': (s.onPrimaryContainer, s.primaryContainer),
        'onSecondaryContainer/secondaryContainer': (s.onSecondaryContainer, s.secondaryContainer),
        'onTertiaryContainer/tertiaryContainer (streak chip)': (s.onTertiaryContainer, s.tertiaryContainer),
        'tertiary/surface (saved)': (s.tertiary, s.surface),
        'error/surface (overdue, expenses)': (s.error, s.surface),
        'error/surfaceContainerHighest': (s.error, s.surfaceContainerHighest),
        'onErrorContainer/errorContainer': (s.onErrorContainer, s.errorContainer),
        'onSurface/secondaryContainer (selected rows)': (s.onSurface, s.secondaryContainer),
      };
      final failures = <String>[];
      pairs.forEach((name, p) {
        final c = contrast(p.$1, p.$2);
        if (c < 4.5) failures.add('$name = ${c.toStringAsFixed(2)}');
      });
      expect(failures, isEmpty, reason: 'Report in docs/DECISIONS.md instead of hand-tweaking roles');
    });
  }
}
