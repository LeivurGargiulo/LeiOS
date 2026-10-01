# Sync design

```
UI ⇄ PowerSync (local SQLite) ⇄ PowerSync Cloud ⇄ Supabase Postgres
   │ writes → local CRUD queue → SupabaseConnector.uploadData → PostgREST (RLS with the user's JWT)
   └ reads  ← sync stream (rows with user_id = JWT subject) ← Postgres logical replication
```

## Rules of the road
- **Reads are always local** (`db.watch` → `StreamProvider`). The app opens and works offline with a stored session; nothing waits on the network.
- **Writes go through repositories only**, inside `writeTransaction` when they touch several tables.
- The client schema has **no FK, UNIQUE, CHECK, cascades or defaults** (views over JSON), so cascades / SET NULL / validation live in repositories; Postgres re-enforces them as a server-side safety net.
- **IDs:** random UUID v4, except natural-key rows which use a deterministic UUID v5 over `user_id|type|key` so two offline devices never duplicate a day: `feelings` (date), `habit_completions` (habit_id|date), `settings` (id = user_id).
- **Dates:** instants are UTC ISO-8601 with `Z`; everything else is a plain `YYYY-MM-DD` date or floating minutes-since-midnight (no timezone drift).

## Upload errors
`uploadData` loops `getNextCrudTransaction()`:
- network / transient → rethrow, PowerSync retries;
- Postgres class `22` (data), `23` (integrity, incl. FK/check) or `42501` (RLS) can never succeed → the transaction is recorded in the **local-only** `sync_errors` table and discarded so the queue isn't blocked. Settings → Sync shows "N changes could not be synced" with the message. Nothing is lost silently.

## Conflicts (known trade-offs)
- `PATCH` carries only the changed columns ⇒ **last-write-wins per column**.
- `sort_order` is renumbered contiguously after each change; two devices reordering the same list at once may overwrite each other.
- Hard deletes sync as `DELETE`; there is no trash. Undo re-inserts the row with the same id (list items come back at the end of their list).
- Editing a recurring event edits the whole series (no per-occurrence exceptions).

## Sign-out
`db.disconnectAndClear()` after a confirmation that shows the number of pending (unsynced) operations.

## Legacy sync-rules equivalent
If an instance is on an older edition, use buckets instead of `powersync/sync-rules.yaml`:
```yaml
bucket_definitions:
  user_data:
    parameters: SELECT request.user_id() AS user_id
    data:
      - SELECT * FROM tasks WHERE user_id = bucket.user_id
      # … one line per table (12)
```

## Manual two-device checklist
1. Sign in with the same account on two instances (e.g. Android + Linux).
2. Go offline on both (airplane mode / network off). Edit different fields of the same task on each; create a habit completion for the same day on both; add a mood entry for the same day on both.
3. Reconnect both. Expect: both task edits survive (per-column LWW), exactly one habit completion and one mood row for that day, no duplicates anywhere.
4. Sign in as a *different* user on one device: none of the first user's data is visible (RLS).
5. Break a row on purpose (e.g. a transaction pointing at a deleted fund) and check it lands in Settings → Sync → errors.
