# Fix Guest-Wall Signup Existing-User Bounce ke Legal Consent

Date: 2026-09-12
Time: 16:21:23
Topic: guest-wall-signup-bounce-fix
Status: done (analyze/test/build + commit `7416a7f`)

## Task / Problem
User lapor: input email existing ke form sign up dari guest wall → dilempar ke form legal acceptance tanpa pesan error yang jelas.

## Key Files Changed
- `lib/presentation/blocs/auth/auth_bloc.dart` - `_onSignUp` gagal + `upgradeGuest:true` → tetap `guest`; `_onSignIn` gagal + `isGuestAuthWall:true` → tetap `guest` (sesi anonim masih hidup)
- `lib/presentation/screens/auth/auth_screen.dart` - guest wall hanya auto-pop saat `authenticated`, bukan saat `guest`
- `test/auth_bloc_guest_wall_test.dart` (NEW) - 4 test bloc_test + mocktail
- `pubspec.yaml` - `0.26.4+86` → `0.26.5+87`

## Technical / Business Decisions
- Root cause: signup existing dari guest wall gagal di `updateUser`, tapi `AuthBloc._onSignUp` emit `unauthenticated` → `_AuthGate` spawn akun anonim BARU (userId baru → consent re-check `requiresAcceptance=true` → render `LegalConsentScreen`). Wall ikut ke-pop sehingga snackbar error hilang.
- Non-wall tetap `unauthenticated` seperti semula - mirror pola `AuthGoogleSignInRequested` (`fallbackStatus = upgradeGuest ? guest : unauthenticated`).

## Assumptions & Risks
- Status `guest` optimistis bisa basi bila sesi anonim sudah mati server-side; `_onUserChanged` via `authChanges` akan mengoreksi ke status real.
- Pesan exact Supabase ("already registered" vs "duplicate") perlu konfirmasi log produksi.

## Blockers / Unresolved
- Tidak ada.

## Verification
- `flutter analyze` 0
- `flutter test` 197/197 (+4 regression test baru)
- APK 3 ABI sukses

## Commit
- `fix(auth): keep guest session on wall signup failure, don't bounce to legal consent` (`7416a7f`)

## Related
- Tidak ada plan file terpisah.
