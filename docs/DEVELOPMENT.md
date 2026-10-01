# Development and release guide

Part 1 is how to test LeiOS while developing (against `leios-dev`). Part 2 is what to do when it is ready for production (`leios-prod`). Backend setup itself lives in [SETUP.md](SETUP.md); sync design in [SYNC.md](SYNC.md).

## Part 1: Testing in development

### 0. Environment

- `leios-dev` = Supabase project `ytqaephergdkoilnntjb` + PowerSync instance "Development" (`6abed2ef3b1803753bce254d`).
- Client values live in `.env.json` (git-ignored): `SUPABASE_URL`, `SUPABASE_ANON_KEY` (the `sb_publishable_…` key), `POWERSYNC_URL`.
- Server-side secrets live in `.env` (git-ignored): `PS_ADMIN_TOKEN`, `PS_DATABASE_*`. They are read by the PowerSync CLI only, never by the app.
- Windows: Developer Mode on, see the toolchain notes in [SETUP.md](SETUP.md).
- Free tier: Supabase and PowerSync both pause after a week of inactivity. If the app shows "Syncing…" forever after a quiet week, un-pause both from their dashboards first.

### 1. Automated checks (no backend needed)

```bash
flutter pub get && flutter gen-l10n
flutter analyze --fatal-infos --fatal-warnings   # must be zero issues
flutter test                                      # unit, repository, widget, l10n guard (real local PowerSync DB)
xvfb-run -a flutter test integration_test/app_test.dart -d linux   # Linux; mock login → quick add → Today/Tasks
flutter test test/golden --run-skipped            # only when UI changed: regenerates docs/screenshots
```

CI runs the first three plus the integration test on every PR (`.github/workflows/ci.yml`).

### 2. Run the app against dev

```bash
flutter run -d windows --dart-define-from-file=.env.json     # or: -d <android-device-id>, linux, macos
```

Without those values the app shows a "not configured" screen. Android emulator: `emulator -avd <name> -no-snapshot` if it stays `offline`.

### 3. Manual smoke test (one device, 10 minutes)

1. **Sign up** with a throwaway email. If "Confirm email" is on in Supabase (Authentication → Providers → Email), confirm via the email first.
2. Create one item in every area: task (try the Eisenhower flags and a due date), habit + completion, mood check-in, goal with steps, calendar event (single, multi-day, recurring), note with tags, a list item per list, savings fund + income/expense/contribution.
3. **Verify it reached the cloud**: Supabase dashboard → Table Editor, or ask for `select count(*) from tasks;` through the Supabase MCP. Rows must carry your `user_id`.
4. **Offline**: turn the network off, edit and add items, restart the app (it must still open and show everything), turn the network on, and confirm the changes arrive in Supabase.
5. **Settings → Export data**: file is produced and contains what you created.
6. **Sign out**: the confirmation shows the pending-operations count; after sign-out the local data is gone; sign back in and it re-syncs.
7. **Settings → Sync**: no "changes could not be synced" entries. If there are, the message names the failing Postgres error (see `docs/SYNC.md` § Upload errors).

For the two-device and two-user checks, follow the checklist at the bottom of [SYNC.md](SYNC.md).

### 4. Backend checks

| Check | How | Expect |
|---|---|---|
| RLS isolation | `psql "$DEV_DB_URL" -v ON_ERROR_STOP=1 -f supabase/tests/rls_isolation.sql` (or run the same SQL via the Supabase MCP without the `\echo`) | "RLS isolation test passed"; the test rolls back and leaves no users or rows |
| Security advisor | Supabase dashboard → Advisors, or MCP `get_advisors security` | no findings; re-run after every schema change |
| PowerSync health | `powersync status` | connection `connected`, "Initial replication done: true", 12 tables listed |
| Sync config | `powersync validate --sync-config-file-path=powersync/sync-rules.yaml` | all green |
| Dev token | `powersync generate token --subject=<a real auth.users id>` | token for pointing a test client at the instance without signing in |

PowerSync CLI auth: `PS_ADMIN_TOKEN` from `.env` (`set -a; . ./.env; set +a` in bash). The CLI installs to the global npm folder; open a new terminal if `powersync` is "not found".

### 5. Changing the schema

1. Add a new file in `supabase/migrations/` (never edit applied ones). Include RLS, an `authenticated` grant, `replica identity full`, and add the table to the `powersync` publication.
2. Add the table to `powersync/sync-rules.yaml` and to the client schema in `lib/`.
3. Apply to dev, re-run the RLS test and advisors, then `powersync deploy sync-config --sync-config-file-path=powersync/sync-rules.yaml`.

### 6. Troubleshooting

- **Stuck on "Syncing…"**: check backend first. `powersync status` (replication connected?), is the sync config deployed, is the Supabase project un-paused, does `https://<instance>.powersync.journeyapps.com` resolve (a new instance takes ~2.5 minutes).
- **`PSYNC_S2101` / `S2105` in PowerSync logs**: JWT not accepted. Keep `client_auth: supabase: true`; if the project ever moves back to legacy HS256 keys, add the JWT secret (see the PowerSync skill's `supabase-auth.md`).
- **`42501 permission denied` on upload**: missing `authenticated` grant or RLS policy on that table.
- **Rows never appear on a second device**: table missing from the publication or from `sync-rules.yaml`.
- **Migration drift in dev**: the dev schema was first applied through the Supabase MCP, so the remote migration versions are `20261001215355` and `20261001215359`, not the local file names. Before the first `supabase db push` (or the dev-migrate GitHub workflow), align them:
  ```bash
  supabase link --project-ref ytqaephergdkoilnntjb
  supabase migration repair --status reverted 20261001215355 20261001215359
  supabase migration repair --status applied 20261001000000 20261001000100
  supabase db push      # applies 20261001000200 (idempotent)
  ```

## Part 2: Going to production

Do all of Part 1 on dev first. Production is a separate Supabase project **and** a separate PowerSync instance (free tier allows two PowerSync instances: dev + prod). Never point the dev config at prod or the reverse.

### A. Pre-flight

- [ ] `flutter analyze` clean, `flutter test` and the integration test green on `main`, CI green.
- [ ] RLS test and security advisor clean on dev; every table has RLS and a policy.
- [ ] Manual smoke test, two-device test and two-user isolation test done (Part 1 §3, SYNC.md checklist).
- [ ] Android release signing configured (SETUP.md § Android release signing); keystore backed up outside the repo. **Losing it means you can never update the installed app.**
- [ ] Decide the paid-tier question: Free Supabase has **no automatic backups** and pauses after a week idle. For real data, use Supabase Pro (daily backups, no pausing) and PowerSync Pro, or accept manual exports (Settings → Export data).

### B. Production Supabase (`leios-prod`)

1. Create the project (dashboard). Note the ref, URL, publishable key, and set a strong DB password (password manager).
2. Apply migrations from the repo (the only supported way to change prod schema):
   ```bash
   supabase link --project-ref <prod-ref>
   supabase db push
   ```
   This creates the 12 tables, RLS policies, grants, `REPLICA IDENTITY FULL` and the `powersync` publication.
3. Create the replication role with a **new** password (never reuse dev's):
   ```sql
   CREATE ROLE powersync_role WITH REPLICATION BYPASSRLS LOGIN PASSWORD '<new long random password>';
   GRANT SELECT ON ALL TABLES IN SCHEMA public TO powersync_role;
   ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO powersync_role;
   ```
4. Authentication settings:
   - Email provider on, **Confirm email on**, anonymous sign-ins off.
   - Site URL and redirect URLs set for the app's deep links, if used.
   - Configure custom SMTP (the built-in sender is heavily rate-limited and meant for testing).
   - Review password rules and rate limits.
   - Use the new JWT signing keys (asymmetric), the default for new projects.
5. Run `supabase/tests/rls_isolation.sql` against prod once (it rolls back) and check Advisors. Do not add test data.
6. Never put the `service_role` key in the app or in CI secrets used by the build.

### C. Production PowerSync

Keep prod config in its own directory so a dev command can never hit it:

```bash
mkdir powersync-prod && cp powersync/service.yaml powersync-prod/ && cp powersync/sync-rules.yaml powersync-prod/sync-config.yaml
```

1. In the PowerSync dashboard create a new project (or instance) for prod. Set `name: Production` in `powersync-prod/service.yaml`.
2. Use a separate env file for the prod values (`PS_DATABASE_HOST=db.<prod-ref>.supabase.co`, the new password), and a prod PAT if you use one.
3. Link and deploy, confirming the target instance each time:
   ```bash
   powersync link cloud --instance-id=<prod-instance-id> --directory=powersync-prod
   powersync validate --directory=powersync-prod
   powersync deploy --directory=powersync-prod
   powersync status --directory=powersync-prod
   ```
4. Keep `sync-config.yaml` identical to the dev one; the schema is the contract.

### D. Build and ship the app

Production values go in `.env.prod.json` (git-ignored) with the prod URL, publishable key and instance URL.

- **Android**: `flutter build appbundle --release --dart-define-from-file=.env.prod.json` → upload the `.aab` to Play Console (internal testing first). Use `flutter build apk --release …` for sideloading.
- **Windows**: `flutter build windows --release --dart-define-from-file=.env.prod.json`, zip `build/windows/x64/runner/Release` or package as MSIX.
- **Linux**: `flutter build linux --release …`, tar the bundle (CI does this).
- **macOS**: `flutter build macos --release …` then `create-dmg` on a Mac.

Bump `version:` in `pubspec.yaml` for every release and tag the commit (`git tag vX.Y.Z`).

CI: set repository secrets `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `POWERSYNC_URL` to the **prod** values only for release builds (or keep two sets of secrets). The `db-migrate-dev` workflow must keep targeting dev only.

### E. Production smoke test and monitoring

1. Install the release build on a clean device, sign up with a real account, create data, kill the network, edit, reconnect, confirm sync in the prod Table Editor.
2. Second device: sign in and confirm the data arrives.
3. After the first real users: check Supabase Advisors, Supabase logs (`Logs → API/Postgres`), and PowerSync dashboard → instance diagnostics.
4. Set a calendar reminder to review the paused-project and backup situation (Part 2 §A) if you stayed on free tiers.

### F. Ongoing release routine

1. Schema change → new migration → dev → RLS test + advisors → `supabase db push` to prod **before** shipping the app version that needs it (additive changes only, so old clients keep working).
2. Sync-config change → `powersync deploy sync-config` on dev, verify, then prod.
3. App release → bump version → CI green → build with prod values → staged rollout.
4. Rollback plan: the previous app build stays available; migrations are additive so rolling the app back is safe. Take an export or backup before any destructive migration.

### G. Cleanup before go-live

- Rotate the dev `powersync_role` password (it was shown in a chat session) and the dev PowerSync PAT if it was shared.
- Delete throwaway test users from dev if you will promote dev data to anything (you should not; prod starts empty).
- Do not commit `.env`, `.env.json`, `.env.prod.json`, `android/key.properties` or any keystore (all git-ignored; verify with `git status` before committing).
