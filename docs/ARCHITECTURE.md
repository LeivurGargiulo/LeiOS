# Architecture

Dependencies point down: `features/` → `data/` → `core/`; `domain/` is pure Dart used by all.

```
lib/
  app/        providers (Riverpod), router (go_router StatefulShellRoute), AdaptiveScaffold, ScreenScaffold, quick-add
  core/
    config/ db/ sync/ ids/ validation/ export/
    design/   theme (seed colour), tokens, breakpoints, motion
    widgets/  shared kit: EntitySheet/EntityScreen/EntityEditor, MasterDetailScaffold, SwipeActionTile,
              ReorderableGroup, ChipFilterRow, TabbedScreen, PeriodPicker/MonthSelector, EmptyState, SyncStatusChip, …
  domain/     pure functions + models: streak, mood, goals/periods, events/recurrence, tasks, finance, tags, ordering
  data/       repositories (the only layer that touches SQL) + OrderedGroup (sort_order per group)
  features/   today, tasks, calendar, goals, notes, lists, finance, settings, auth
  l10n/       ARB + generated localizations
supabase/migrations  powersync/sync-rules.yaml  docs/  test/  integration_test/
```

## Key patterns
- **Reactive reads:** repositories expose `watch…()` streams → `StreamProvider`s in `app/providers.dart`. Data from other devices simply appears.
- **Validation before write:** repositories call `core/validation` and throw `ValidationException(message)`; `EntitySheet`/`EntityScreen` catch it and show it inline next to Save.
- **One editor per entity, three presentations** (`EditorPresentation.sheet | screen | inline`): the same form widget renders as a bottom sheet, a full-screen route, or inside the master-detail detail pane.
- **Master-detail:** selection lives in the route (`/tasks/:id`, `/notes/:id`, `/goals/:id`, `/lists/:id`, `/calendar/:date/:eventId`, `/finance/tx:<id>` | `fund:<id>`), so it is deep-linkable; a selection whose row disappears is cleared.
- **Drafts:** unsaved editor state is kept in `draftsProvider` keyed by entity (`DraftFormMixin`), so rotating or resizing between layouts doesn't lose edits.
- **Lists:** `ListItemsView(ListConfig)` powers the four tabs; `OrderedGroup` powers `goal_steps` and `list_items`.
- **Auth seam:** `AuthService` (Supabase impl + in-memory fake) keeps UI and tests independent of the network.
