import 'package:flutter/material.dart';

/// The single source of the visual identity (sage teal). Every role derives from it.
const Color kSeedColor = Color(0xFF4F8F82);

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: kSeedColor, brightness: brightness);
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: brightness);
  return base.copyWith(
    visualDensity: VisualDensity.standard,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerHighest,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1, thickness: 1),
    listTileTheme: const ListTileThemeData(minVerticalPadding: 8),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    bottomSheetTheme: const BottomSheetThemeData(
      showDragHandle: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(borderRadius: BorderRadius.all(Radius.circular(4))),
    inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
  );
}

/// Tabular-figure numeric text style for amounts and counters (spec §9.2).
TextStyle moneyStyle(TextStyle? base) =>
    (base ?? const TextStyle()).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
