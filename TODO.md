# TODO

## Critical

- [x] Add `.env` ignore rules before committing.
  - Current `git status` shows `.env` as untracked.
  - Add `.env`, `.env.*`, and `!.env.example` to `.gitignore`.
  - Ensure Flutter client `.env` only contains `SUPABASE_URL` and `SUPABASE_ANON_KEY`; never include `SUPABASE_SERVICE_ROLE_KEY` or `OPENROUTER_API_KEY`.
  - **Done (2026-06-07)**: rules added in `.gitignore` (lines 122-124), plus Supabase local artifacts, cross-platform OS metadata, FVM, build artifacts, and signing material (lines 127-160). `pubspec.lock` explicitly tracked. Verified via `git check-ignore`.

- [x] Harden `deduct_credit_for_sticker` RPC ownership checks.
  - `supabase/migrations/20260505000001_init_schema.sql` exposes a `SECURITY DEFINER` RPC with caller-supplied `p_user_id`.
  - Validate `p_user_id = auth.uid()` inside the function, or remove `p_user_id` and derive the user from `auth.uid()`.
  - Keep the atomic wallet lock, sticker row insert, and ledger insert behavior intact.
  - **Done (2026-06-07)**: new migration `supabase/migrations/20260505000004_deduct_credit_user_scope.sql` drops the 4-arg overload, recreates as 3-arg with `v_user_id := auth.uid()` + `IS NULL` guard. Edge function caller in `index.ts` updated in lockstep (no more `p_user_id` in RPC payload). `userId` still kept locally for the storage path.

## High Priority

- [x] Fix nullable field clearing in `AuthBlocState.copyWith`.
  - `lib/presentation/blocs/auth/auth_bloc.dart` currently uses `field ?? this.field`.
  - This prevents intentionally clearing `user`, `errorMessage`, and `infoMessage`.
  - Use explicit clear flags, sentinel values, or a more explicit state model.
  - **Done (2026-06-07)**: applied `Object()` sentinel pattern in `auth_bloc.dart` (`static const Object _undefined = Object()`). Omitted param = keep current value; explicit `null` = overwrite. All existing callers still work without modification.

- [x] Update README paths after moving Flutter app to the repository root.
  - Replace references to `bikin_stiker/lib`, `bikin_stiker/.env`, and `cd bikin_stiker`.
  - Update repository layout so `lib/`, `android/`, `ios/`, `test/`, and `pubspec.yaml` are shown at root.
  - **Done (2026-06-07)**: layout, setup, and running sections in `README.md` rewritten for root-based structure. Migrations table extended with the `20260505000004_*` row.

- [x] Hoist `HistoryBloc` to `app.dart` for state retention (not in original TODO; raised during init-session code review).
  - Per-screen `BlocProvider` in `HistoryScreen` discarded the list + signed-URL cache on every open.
  - **Done (2026-06-07)**: `HistoryBloc` moved into `app.dart`'s `MultiBlocProvider` (lazy). `HistoryScreen` converted to `StatefulWidget`; `HistoryRefreshed` dispatched once in `initState`. Added `HistoryCleared` event, dispatched in `_AuthGate` listener on signout to prevent cross-user data leak via retained state.

## Medium Priority

- [x] Avoid creating signed URLs inside history item builds.
  - `lib/presentation/screens/history/history_screen.dart` calls `signedUrlForPath` in a `FutureBuilder`.
  - Move signed URL resolution/caching into `HistoryBloc` or `StickerRepository`.
  - Avoid repeated signed URL requests during rebuilds and list scrolling.
  - **Done (2026-06-07)**: `StickerRepository.signedUrlForPath` backed by `Map<String, Future<String?>> _signedUrlCache` + private `_fetchSignedUrl`. Repeated calls for the same path share one in-flight `Future`. 1h cache TTL matches server. Concurrent calls deduplicated.

- [ ] Add local validation before sticker generation submission.
  - Keep edge function validation as the source of truth.
  - Add client-side guards for empty prompt, max prompt length, and known preset IDs in BLoC/repository for faster UX feedback.

- [x] Review untracked project files before first commit.
  - Decide whether `.idea/`, `.metadata`, `.flutter-plugins-dependencies`, and `bikin_stiker.iml` should be tracked.
  - Keep generated/cache files out of Git unless they are intentionally required.
  - **Done (2026-06-07)**: covered by the new `.gitignore` entries (`.claude/`, `.idea/`, `.metadata`, `*.iml`, `*.iws`, `*.ipr`, `.fvm/`, `fvm_config.json`, `.flutter-plugins-dependencies`, plus Supabase local artifacts and signing material). `pubspec.lock` explicitly kept tracked for reproducible builds.

## Tests And Verification

- [ ] Add focused tests for auth state transitions.
  - Cover sign-in failure, sign-up info message, sign-out user clearing, and stale snackbar prevention.

- [ ] Add tests around sticker generation error mapping.
  - Cover insufficient credits, malformed function response, and generic function failures.

- [ ] Add a contract check for preset IDs across Dart and the Supabase edge function.
  - Current Dart test checks a hard-coded expected set.
  - Prefer a shared fixture or generated contract if the preset list grows.

- [ ] Run manual verification after fixes.
  - `flutter analyze`
  - `flutter test`
  - `supabase db reset`
  - Local edge function failure-path test with an invalid OpenRouter key to confirm refunds.
  - C1 regression check: `SELECT deduct_credit_for_sticker(1, 'kawaii', 'pwn');` while authenticated as user A should ERROR with "Not authenticated" (proves the old cross-user deduction vector is closed).
