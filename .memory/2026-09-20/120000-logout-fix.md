# Logout Fix: land on Login + no more silent failure

Date: 2026-09-20 12:00 (planned) / impl selesai 2026-09-20

## Masalah
Pengguna email yang tap Logout mengalami: tetap di halaman Profil, tanpa snackbar error, dan mendarat sebagai guest di Home (bukan Login).

## Root Cause (3 titik)
1. `_onSignOut` di AuthBloc tidak emit state sama sekali — sukses maupun gagal.
2. `ProfileScreen` tidak pernah pop/quit setelah logout — user terjebak di layar Profil.
3. `_AuthGate` auto-spawn akun anonim saat `unauthenticated`, sehingga walau logout berhasil, user tetap masuk Home sebagai guest, bukan Login.

## File Diubah
- `lib/data/repositories/auth_repository.dart:87-88` — tambah `try/catch` → `AuthFailure` / `UnknownFailure`.
- `lib/presentation/blocs/auth/auth_bloc.dart` — field `explicitSignOut: bool` di state + `copyWith` + `props`; rewrite `_onSignOut` dengan preserve status/user saat gagal; preservasi flag di `_onUserChanged`; reset flag di semua emit `submitting` lainnya.
- `lib/core/auth_gate_policy.dart` (BARU) — helper pure `shouldAutoSpawnGuest`.
- `lib/app.dart` — cabang `unauthenticated` cek `shouldAutoSpawnGuest`; kalau false → render `AuthScreen()` langsung.
- `lib/presentation/screens/auth/auth_screen.dart` — tombol "Lanjut sebagai tamu" (hanya saat bukan guest wall).
- `lib/l10n/app_en.arb` + `app_id.arb` — key `continueAsGuest`.
- `lib/l10n/app_localizations*.dart` — di-generate ulang via `flutter gen-l10n`.
- `lib/presentation/screens/profile/profile_screen.dart` — null-safe `userId`; `_ProfileView` dibungkus `BlocListener<AuthBloc>` untuk pop-ke-root + snackbar error.
- `test/auth_bloc_signout_test.dart` (BARU) — 3 test signOut (sukses/gagal AuthFailure/gagal generic) + 5 test shouldAutoSpawnGuest.
- `pubspec.yaml` — versi `0.26.7+89` → `0.26.8+90`.

## Keputusan
- Pasca-logout HARUS ke Login (bukan guest-Home); tombol tamu di Login YA — konfirmasi user 2026-09-20.
- Flag `explicitSignOut` in-memory saja; restart app setelah logout akan kembali auto-guest — ini expected, didokumentasikan di plan risks.
- Race stream vs emit eksplisit ditangani di T2c (`_onUserChanged` preservasi flag).

## Verifikasi
- `flutter pub get` ✓
- `flutter gen-l10n` ✓ (getter `continueAsGuest` tersedia di EN & ID)
- `flutter analyze` ✓ (0 issues)
- `flutter test` ✓ (206/206 passing, termasuk 4 test regresi guest-wall lama + 8 test baru)
- Manual device: login email → Profile → Logout → HARUS tampil Login; tekan "Lanjut sebagai tamu" → masuk Home tamu; offline → logout → snackbar error muncul, tetap di Profil.

## Risiko / Catatan
- Flag in-memory: restart app pasca-logout kembali auto-guest — bukan bug, hanya trade-off state UI sesaat.
- Tidak mengubah scope `signOut()` Supabase (lokal vs global) — blast radius minim.
- Alur delete-account ikut membaik (dispatch `AuthSignOutRequested` → mendarat di Login).

## Usulan Commit
fix(auth): land on Login after explicit sign-out + show error via snackbar
