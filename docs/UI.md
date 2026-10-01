# UI reference

## Tokens (`core/design/tokens.dart`)
Spacing `4 · 8 · 12 · 16 · 24 · 32`; gutters 16 (compact) / 24 (medium+); content max 720 (Settings 640, auth 400, sheets 560); durations `150 / 250 / 350 ms`; easing emphasized-decelerate (enter), emphasized-accelerate (exit), ease-in-out-cubic (in place). Masters pane width `clamp(360, 40%, 440)`. FAB clearance (list bottom padding) 88.

## Theme
`ColorScheme.fromSeed(kSeedColor = #4F8F82)` for light and dark; theme mode System/Light/Dark in Settings. Widgets only use `Theme`/`ColorScheme` roles: errors → `error*`, income/positive → `primary`, savings/streak → `tertiary*`, selection → `secondaryContainer`. Numbers use tabular figures (`moneyStyle`).

## Window size classes
| Class | Width | Navigation | Content |
|---|---|---|---|
| Compact | < 600 | `NavigationBar`: Today · Tasks · Calendar · Goals · More | single pane, FAB |
| Medium | 600–839 | `NavigationRail` (all 8, labels) | single pane, centred ≤ 720 |
| Expanded | ≥ 840 | extended rail + sync chip | master-detail (Today: 2-column cards; Settings: centred column); FAB replaced by `+ New` |

## Shared components
`AdaptiveScaffold`, `ScreenScaffold` (AppBar + contextual FAB, hides on scroll, long-press = quick add), `MasterDetailScaffold`, `EntitySheet` / `EntityScreen` / `EntityEditor`, `MoreDetails`, `SwipeActionTile`, `ReorderableGroup`, `ChipFilterRow` / `SegmentFilter`, `TabbedScreen`, `MonthSelector` / `PeriodPicker`, `EmptyState` + code-drawn `EmptyIllustration`, `SyncStatusChip`, `StatusCircle`, `StatTile`, `TonalCard`, `LabeledProgress`, `SectionHeader`, `confirmDelete` / `confirmDiscard`, `showUndoSnackOn`.

## Forms
Sheets: task, transaction, list item, habit, mood, savings fund. Full screen: event, goal, note. On expanded widths every form renders inline in the detail pane. Save is disabled until valid; validation errors show inline; dismissing a dirty form asks first.

## Keyboard (desktop)
`Ctrl+N` new (in a master-detail screen) or quick add (elsewhere) · `↑/↓` move selection · `Esc` deselect · rows are focusable with visible focus.

## Screenshots
`docs/screenshots/*-compact.png` (360×780), `*-expanded.png` (1280×800), `*-compact-dark.png`. Regenerate: `flutter test test/golden --run-skipped`.

## Accessibility
Verified by tests: no overflow at text scale 2.0 on every destination and editor, at 360×800, 412×915, 600×960, 840×1200 and 1280×800 (light and dark for the extremes); reduce-motion renders. Icon-only buttons have tooltips; mood faces, habit-grid cells, calendar days and status circles expose button/selected/checked semantics; every swipe action also exists in the row menu.
