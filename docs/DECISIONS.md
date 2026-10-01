# Decisions

Ambiguities are resolved with the simplest option that satisfies the spec.

| # | Decision | Why |
|---|---|---|
| 1 | **Sync Streams** (`config: edition: 3`, `auth.user_id()`) instead of `bucket_definitions` | Current PowerSync docs make Sync Streams the standard. Legacy equivalent kept in `docs/SYNC.md`. |
| 2 | Publication `powersync` lists the 12 tables explicitly | The name is mandatory; the docs use `FOR ALL TABLES`, which also works. |
| 3 | `flutter_markdown_plus` instead of `flutter_markdown` | `flutter_markdown` is discontinued; spec allows a maintained equivalent. |
| 4 | `Supabase.initialize(publishableKey: SUPABASE_ANON_KEY)` | `anonKey` is deprecated in `supabase_flutter`; the same value works. Env var name kept as in the spec. |
| 5 | No `sqlite3_flutter_libs` | PowerSync 2.x loads SQLite via build hooks; the package is end-of-life. |
| 6 | Theme: `ColorScheme.fromSeed(#4F8F82)`; contrast checked in `test/theme_contrast_test.dart` | All 15 role pairings the UI uses pass WCAG AA (4.5:1) in light and dark. No role was hand-tweaked. |
| 7 | Bottom sheets set `enableDrag: false` and draw their own drag handle | Flutter's built-in drag-dismiss bypasses `PopScope`; the custom handle lets a dirty sheet ask "Discard changes?" on swipe-down too. |
| 8 | FAB has **no `Tooltip`**; label + long-press action live in `Semantics`; `heroTag: null` | A tooltip's own long-press recogniser beats the quick-add long-press; every branch keeps a FAB alive so a shared hero tag throws on route pushes. |
| 9 | Destination switches use a fade-through over an always-alive `Stack` of branches (`FadeThroughBranches`) | Keeps each destination's scroll position and tab, as `StatefulShellRoute` intends. |
| 10 | Swipe actions run then spring back (`confirmDismiss` → `false`); the row leaves when the data stream stops emitting it | Returning `true` while the DB write is still async trips Flutter's "dismissed Dismissible still in tree" assertion. |
| 11 | Undo of a deleted list item re-inserts it at the end of its list | Re-inserting at the old index would need a second reorder transaction; the trade-off is documented in `SYNC.md`. |
| 12 | A new goal's steps are held in memory until the first Save; steps of an existing goal edit the database live | `goal_steps.goal_id` needs the goal row to exist. |
| 13 | Mood history is a card at the bottom of Review rather than a bare list | Keeps Review a single consistent card column. |
| 14 | Compact deep links such as `/notes/<id>` show the list (the editor opens through the normal tap flow) | On compact the editor is a pushed full-screen route; drafts survive a resize to expanded. |
| 15 | `AuthUser` has value equality | Token refreshes emit the same user; without equality each refresh would rebuild providers and reconnect sync. |
| 16 | Finance route selection encodes the tab: `/finance/tx:<id>` / `/finance/fund:<id>` | One route param serves both master-detail lists. |

## Known gaps / not verified in this environment
- **Not run against real Supabase / PowerSync Cloud.** No cloud projects exist in this environment, so Milestone 0's cloud spike, the RLS SQL test and the two-device checklist are written but **unexecuted**. Everything client-side is tested against a real local PowerSync (SQLite) database.
- **Android build/emulator not verified** (no Android SDK here). `minSdk 24`, `INTERNET` permission and app id are configured; CI builds the APK. Linux release build and the Linux integration test (Xvfb) were run successfully.
- **Windows/macOS** projects are generated but never built here.
- **l10n:** shared strings (navigation, common actions, quick-add, all empty states) are in `lib/l10n/app_en.arb`; many screen-level labels are still inline English literals and need moving to ARB before adding Spanish.
- **Golden tests:** instead of pixel-comparison goldens, `test/golden/screenshots_test.dart` renders reference screenshots into `docs/screenshots` (skipped by default).
- Optional items not built: debug design-gallery route, Markdown toolbar, window size/position memory, `flutter_secure_storage` session store.
- In headless renders even a stock Material 3 FAB draws a thick dark outline; it appeared on the app's FAB too and is not caused by app code (not checked on a device).
