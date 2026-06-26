# Project Memory - BikinStiker

Persistent context for future sessions. Update after every significant change.
Per AGENTS.md, this file captures: features/bugs worked on, key files modified,
technical decisions, verification commands, and proposed commit messages.

---

## Snapshot

- **Stack**: Flutter 3.41 (Dart 3.11) + Supabase (Postgres, Auth, Storage, Edge Functions on Deno)
- **AI provider**: OpenRouter `sourceful/riverflow-v2-fast` (modalities: ["image"])
- **Domain**: WhatsApp sticker generator. User picks preset + short prompt -> atomic
  credit deduction -> OpenRouter -> upload PNG to private bucket -> return signed URL.
- **Branch state**: `main`, 1 commit ahead of `origin/main` (init-session work uncommitted).

---

## Architecture

```
Flutter app (BLoC + Repository)
  -> Supabase (Auth, Postgres w/ RLS, private Storage, generate-sticker edge fn)
     -> OpenRouter (server-side only; key never leaves the edge function)
```

**Clean layers** inside `lib/`:

| Layer | Folder | Depends on |
|---|---|---|
| Presentation | `presentation/{blocs,screens,widgets}` | Domain glue only |
| Domain glue | `data/repositories` | Data sources |
| Data sources | `data/{datasources,models}` | Supabase SDK |
| Cross-cutting | `core/{theme,constants,errors,di}` | None of the above |

UI never imports `supabase_flutter` directly.

---

## Key Technical Decisions

| # | Decision | Rationale |
|---|---|---|
| 1 | SECURITY DEFINER RPCs own all credit mutations | RLS is SELECT-only; RPCs provide atomic `FOR UPDATE` wallet lock + sticker row + ledger insert in one tx |
| 2 | `deduct_credit_for_sticker` derives user from `auth.uid()` (post-init) | Old caller-supplied `p_user_id` allowed cross-user deduction. See C1 below. |
| 3 | OpenRouter key lives only in the edge function | Stored as a Supabase secret; never in Flutter `.env` |
| 4 | Private bucket + signed URLs (TTL 1h) + path-prefix RLS | `auth.uid()::text = (storage.foldername(name))[1]` |
| 5 | BLoC + Repository abstraction (not Riverpod) | Auditable event->state flow; tests can override repos via `MultiRepositoryProvider` |
| 6 | Okabe-Ito palette + icon+label+color pairing | Color-blind safe; hue never carries meaning alone |
| 7 | In-memory signed URL cache, keyed by path (post-init) | History rebuilds were issuing duplicate signed-URL requests. 1h cache TTL matches server. |
| 8 | `HistoryBloc` hoisted to `app.dart` (post-init) | Per-screen `BlocProvider` discarded list+cache on every History open. Refresh dispatched in `initState`. |
| 9 | `AuthBlocState.copyWith` uses `Object()` sentinel (post-init) | Omitted param keeps current value; explicit `null` overwrites. Fixes stale-snackbar bug. |
| 10 | `HistoryCleared` event dispatched on signout | Prevents cross-user data leak via retained bloc state |
| 11 | APK output auto-renamed to `{applicationId}-{versionName}-{descriptor}.apk` (B1) | `android/app/build.gradle.kts` registers a `doLast` hook on `assemble{Release,Debug,Profile}` that moves the generated APK(s) in `build/app/outputs/flutter-apk/` to a descriptive filename. Pubspec stays single source of truth (Flutter Gradle plugin already maps `version: X.Y.Z+N` -> `versionName/versionCode`); the hook only encodes that into the artifact name. |

---

## Migrations

`supabase/migrations/`:

| File | Purpose |
|---|---|
| `20260505000001_init_schema.sql` | Tables, enums, RLS (SELECT-only), `deduct_credit_for_sticker` + `refund_failed_sticker` RPCs |
| `20260505000002_wallet_trigger.sql` | `on_auth_user_created` -> wallet row + 5-credit `topup` ledger entry |
| `20260505000003_storage_bucket.sql` | Private `stickers` bucket, owner-scoped RLS |
| `20260505000004_deduct_credit_user_scope.sql` | **Security hardening**: drops 4-arg `deduct_credit_for_sticker`, recreates 3-arg deriving user from `auth.uid()`. Edge function caller in `index.ts` updated in lockstep. |

---

## Edge Function Contract

`supabase/functions/generate-sticker/index.ts`:

- `POST {presetId, userInput}` (userInput <= 200 chars) with bearer JWT
- Preset IDs (must match `lib/core/constants/presets.dart`): `kawaii | pixel_art | vector_flat | chibi_3d | retro_sticker`
- Flow: validate -> atomic RPC deduct -> OpenRouter -> upload to `stickers/{uid}/{stickerId}.{ext}` -> update row -> return signed URL (TTL 1h)
- Failure path: any post-RPC error -> `refund_failed_sticker` (idempotent guard on `status IN ('failed','success')`)

---

## Recent Work (init session, 2026-06-07)

### C1 - SECURITY: RPC privilege escalation
- **New**: `supabase/migrations/20260505000004_deduct_credit_user_scope.sql`
- **Modified**: `supabase/functions/generate-sticker/index.ts` - drop `p_user_id` from RPC payload
- **Risk closed**: Old RPC accepted caller-supplied `p_user_id`; with `SECURITY DEFINER` bypassing RLS, any authenticated user could decrement another user's wallet.

### C2 - gitignore hardening
- **Modified**: `.gitignore` - added `.env`, `.env.*`, `!.env.example`, `.claude/`, `.idea/`, `.metadata`, `*.iml` (generic), `*.iws`, `*.ipr`, `.fvm/`, `fvm_config.json`, Supabase local dev artifacts (`supabase/.branches/`, `supabase/.temp/`, `supabase/.env`, `supabase/.env.local`), cross-platform OS metadata (`.DS_Store`, `Thumbs.db`, `ehthumbs.db`, `Desktop.ini`), built mobile artifacts (`*.apk`, `*.aab`, `*.ipa`, `*.app`), signing material (`*.keystore`, `*.p12`, `*.p8`). `!pubspec.lock` exception added (app convention: track lockfile for reproducible builds).

### H1 - `AuthBlocState.copyWith` sentinel pattern
- **Modified**: `lib/presentation/blocs/auth/auth_bloc.dart`
- **Bug**: omitting nullable params implicitly cleared them (e.g. `errorMessage: errorMessage` with no `??`).
- **Fix**: `static const Object _undefined = Object();` - omitted param keeps current value, explicit `null` overwrites. All existing callers in the bloc remain correct without modification.

### H2 - Signed URL cache
- **Modified**: `lib/data/repositories/sticker_repository.dart`
- Added `Map<String, Future<String?>> _signedUrlCache` keyed by storage path.
- `signedUrlForPath` is now a cache lookup via `putIfAbsent`; private `_fetchSignedUrl` does the actual call. Concurrent calls for the same path share one in-flight `Future`.

### H3 - `HistoryBloc` hoisted
- **Modified**: `lib/app.dart`, `lib/presentation/blocs/history/history_bloc.dart`, `lib/presentation/screens/history/history_screen.dart`
- `BlocProvider` moved to `app.dart`'s `MultiBlocProvider` (lazy).
- `HistoryScreen` converted to `StatefulWidget`; `HistoryRefreshed` dispatched once in `initState`.
- Added `HistoryCleared` event; dispatched in `_AuthGate` listener on signout to prevent cross-user data leak.

### H4 - README paths
- **Modified**: `README.md` - layout section rewritten for root-based structure; `cd bikin_stiker`/`cd ..` removed from setup; migrations table extended with `20260505000004_*` row; running section simplified.

### B1 - APK rename on build
- **Modified**: `android/app/build.gradle.kts` - added a `gradle.projectsEvaluated` block hooking `assembleRelease/assembleDebug/assembleProfile` to rename generated APK(s) in `build/app/outputs/flutter-apk/` to `{applicationId}-{versionName}-{descriptor}.apk` (e.g. `com.bikinstiker.bikin_stiker-1.0.0-release.apk`, `com.bikinstiker.bikin_stiker-1.0.0-arm64-v8a-release.apk`).
- **Semver handling**: No pubspec changes needed; bumping `version:` in `pubspec.yaml` propagates through `flutter.versionName`/`flutter.versionCode` and is picked up by the rename hook automatically.

---

## Pending (M-tier)

| ID | Item | Primary file(s) |
|---|---|---|
| M1 | Client-side preset whitelist + max-length validation in `home_screen` (empty prompt already checked) | `lib/presentation/screens/home/home_screen.dart` |
| M2 | Remove silent error swallow in `_fetchSignedUrl` (deliberately deferred from H2) | `lib/data/repositories/sticker_repository.dart` |
| M3 | Use `CachedNetworkImage` consistently - `_ResultPanel` currently uses `Image.network` | `lib/presentation/screens/home/home_screen.dart` |
| M4 | Add bloc tests (auth state transitions, sticker gen error mapping) and repository tests | `test/` |
| M5 | Smooth `WalletBloc` loading on re-login (avoid flash of 0 -> loading -> real) | `lib/presentation/blocs/wallet/wallet_bloc.dart` |
| M6 | Improve `_AuthGate` for `AuthStatus.submitting` (loading overlay vs full `AuthScreen`) | `lib/app.dart` |
| M7 | Strengthen preset contract test (parse from `index.ts` or shared fixture) | `test/widget_test.dart` |

---

## Verification (run manually)

```bash
# 1. Static analysis + tests
flutter analyze
flutter test

# 2. Migrations from clean state
supabase db reset

# 3. Edge function (local)
supabase functions serve generate-sticker --env-file .env.local
# smoke: POST with valid JWT + {presetId, userInput} -> 200 + signedUrl
# failure: set OPENROUTER_API_KEY=invalid, generate -> 500, status='failed',
#          balance restored, 'refund' row in credit_transactions

# 4. CRITICAL C1 regression check
# After db reset, sign in as user A, then in psql run:
#   SELECT deduct_credit_for_sticker(1, 'kawaii', 'pwn');
# EXPECTED: ERROR: Not authenticated  (auth.uid() is A; no p_user_id to override)
# This proves the old cross-user deduction vector is closed.
```

---

## Proposed Commit Messages (pending user approval)

Conventional commit, 1 line each:

```text
fix(supabase): drop p_user_id from deduct_credit_for_sticker; derive from auth.uid()
chore(git): ignore .env, IDE, and generated Flutter artifacts
refactor(app): hoist HistoryBloc to app.dart; cache signed URLs; fix AuthBlocState.copyWith
docs: update README layout/paths after root-relative move
build(android): rename built APKs to {applicationId}-{versionName}-{descriptor}.apk
```

Or a single combined commit:

```text
fix(security,ux): harden RPC user scope, gitignore, Bloc state, signed URL cache, README paths
```

---

## Notes for Next Session

- All init-session work is in the working tree, uncommitted. User controls commit/push.
- Still untracked (will land in the first commit): `lib/`, `pubspec.yaml`, `test/`, `android/`, `ios/`, `analysis_options.yaml`, `TODO.md`, plus the new `supabase/migrations/20260505000004_*` and this `PROJECT_MEMORY.md`.
- The repo's `TODO.md` duplicates the M-tier items above. Keep this memory and `TODO.md` in sync if status changes.
