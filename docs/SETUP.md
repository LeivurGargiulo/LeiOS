# Setup: standing up the cloud backend from scratch

Everything runs in the cloud (no Docker, no local Supabase/PowerSync). Do this once for `leios-dev`, then again for `leios-prod`.

## Free-tier limits (checked 2026-10-01; re-check before relying on them)

| Service | Limit |
|---|---|
| Supabase Free | 500 MB database, 50,000 MAU, **project pauses after 1 week of inactivity**, **no automatic backups** |
| PowerSync Cloud Free | 2 instances, 2 GB synced / month, 500 MB hosted, **deactivated after 1 week of inactivity** |

Consequences: a paused project must be un-paused from its dashboard before the app can sync again (local data is untouched, the app keeps working offline). Because there are no free backups, use **Settings → Export data** regularly.

## Order of operations

1. **Supabase project.** Create `leios-dev` (and later `leios-prod`). Note *Project URL*, the *anon / publishable key*, the project ref and the database password. Under Authentication → Providers keep **Email** enabled; decide whether "Confirm email" is on (the app handles both).
2. **Migration.** With the Supabase CLI (it only migrates, nothing runs locally):
   ```bash
   supabase login
   supabase link --project-ref <ref>
   supabase db push
   ```
   This applies `supabase/migrations/*`: the 12 tables, indexes, RLS on every table, and the `powersync` publication.
3. **Replication role.** In the Supabase SQL editor (the password is a secret, never commit it):
   ```sql
   CREATE ROLE powersync_role WITH REPLICATION BYPASSRLS LOGIN PASSWORD '<long random password>';
   GRANT SELECT ON ALL TABLES IN SCHEMA public TO powersync_role;
   ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO powersync_role;
   ```
   The publication **must be named `powersync`** (the migration creates it for the 12 tables; `FOR ALL TABLES` also works).
4. **PowerSync Cloud instance.** Create an instance, choose Supabase as the source, and enter the connection (use the Supabase *direct/session* connection string host, user `powersync_role`, the password above). Credentials are entered in the dashboard, not in the repo. Copy the instance URL.
5. **Client auth.** In the PowerSync dashboard → Client Auth, tick **Use Supabase Auth**. Modern projects with JWT signing keys need nothing else (JWKS is auto-configured); legacy projects paste the Supabase JWT secret.
6. **Deploy sync rules.** Paste `powersync/sync-rules.yaml` in the dashboard (or deploy it with the PowerSync CLI) and deploy.

Always cross-check against the current official guide, "Supabase + PowerSync": these UIs move.

## Run the app

```bash
flutter pub get
flutter run -d <android|linux|windows|macos> \
  --dart-define=SUPABASE_URL=https://<ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon key> \
  --dart-define=POWERSYNC_URL=https://<instance>.powersync.journeyapps.com
```
`--dart-define-from-file=.env.json` works too (JSON of the same three keys; `.env.json` is git-ignored). Without these values the app shows a "not configured" screen. Never put the `service_role` key anywhere in the client.

## Verifying RLS

```bash
psql "$DEV_DB_URL" -v ON_ERROR_STOP=1 -f supabase/tests/rls_isolation.sql
```
Creates two users inside a transaction, proves user B cannot read, update, delete or spoof user A's rows, then rolls everything back. Run it against `leios-dev` only.

## Windows toolchain notes

- Turn on **Developer Mode** (`start ms-settings:developers`); plugin builds (Windows and Android) fail with "Building with plugins requires symlink support" otherwise.
- Android: Gradle needs the NDK pinned by Flutter. If auto-install fails with "Package ndk not found" (the new `sdkmanager` shim), run `android sdk install ndk/<version>` from `%LOCALAPPDATA%\Android\Sdk\cmdline-tools\latestinndroid.exe`; the first build then also pulls Platform 35 and CMake 3.22.1.
- If a fresh emulator stays `offline` in `adb devices`, kill `emulator`/`qemu-system-x86_64` and cold-boot with `emulator -avd <name> -no-snapshot`.

## Android release signing

Keystore lives outside the repo. Create `android/key.properties` (git-ignored) with `storeFile`, `storePassword`, `keyAlias`, `keyPassword`, and reference it from `android/app/build.gradle.kts`'s `signingConfigs.release` before `flutter build appbundle --release`. Until then CI produces a debug-signed APK.

## Desktop packaging

- **Linux:** `flutter build linux --release`, then tar the `build/linux/x64/release/bundle` directory (CI does this). Needs `libgtk-3-dev`, clang, cmake, ninja.
- **Windows:** `flutter build windows --release`, zip the `Release` folder or wrap it with MSIX.
- **macOS:** `flutter build macos --release` then `create-dmg`; needs a macOS runner (not automated here).
