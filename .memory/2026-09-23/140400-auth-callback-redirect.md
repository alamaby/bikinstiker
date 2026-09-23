# Auth Callback Redirect

Date: 2026-09-23 14:04:00

## Task
Ganti redirect auth dari `io.supabase.bikinstiker://login-callback/` menjadi
`bikinstiker://auth/callback` (cermin bagistruk), daftarkan di native Android,
dan tangani di Dart via `getSessionFromUrl`.

## Files Changed
- `lib/core/constants/env_constants.dart` — tambah `static const authCallbackUrl`
- `lib/data/repositories/auth_repository.dart` — 2 call site (`signInWithGoogle`,
  `sendEmailOtp`) pakai konstanta baru
- `supabase/config.toml:25` — `additional_redirect_urls` diganti
- `android/app/src/main/AndroidManifest.xml` — sisip 1 intent-filter
  `bikinstiker://auth/callback` setelah filter share-claimed
- `lib/core/services/auth_callback_handler.dart` — file baru, handler + pure
  `isAuthCallbackUri()`
- `lib/core/di.dart` — +1 import, +1 lazy singleton registrasi
- `lib/main.dart` — +1 import, +init call setelah `_drainInitialShareDeepLink`
- `test/auth_callback_handler_test.dart` — file baru, 4 kasus (2 true, 2 false)

## Decisions
- Tanpa env var ala bagistruk: satu nilai const untuk semua env, `.env` ter-bundle
  ke APK sehingga const lebih aman dari drift.
- URL lama `io.supabase...` DIBIARKAN di Dashboard selama transisi (harmless).
- Filter Android dibatasi `/callback` path agar tidak bentrok dengan
  `share-claimed`.

## Status
- S1–S4, S6, S7 (kode): done
- S5 (Dashboard Redirect URLs): manual, owner
- S7 (smoke tap-link): manual, owner

## Verification
- `flutter analyze`: No issues found!
- `flutter test`: 225 passed (naik dari baseline ~221)
- `flutter build apk --split-per-abi --debug`: 3 APK sukses
- Grep `login-callback` di `lib/` dan `supabase/config.toml`: 0 hit

## Commit proposal
`fix(auth): switch auth callback to bikinstiker://auth/callback deep link`
