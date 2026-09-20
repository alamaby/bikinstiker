# Logout Fix: land on Login + no more silent failure

Created: 2026-09-20 12:00:00

## Objective

Pengguna email yang tap Logout harus: keluar dari sesi, keluar dari halaman Profil, dan mendarat di halaman Login (mode normal + tombol "Lanjut sebagai tamu"). Kegagalan logout harus terlihat via snackbar, tidak lagi diam total.

Latar RCA (sudah dikonfirmasi user: akun email, tetap di Profil, murni diam tanpa log):

1. `_onSignOut` (`lib/presentation/blocs/auth/auth_bloc.dart:396-401`) tanpa `emit` dan tanpa `try/catch` — sukses pun tak ada transisi eksplisit, gagal pun diam.
2. Route `ProfileScreen` (di-push dari `lib/presentation/screens/home/home_screen.dart:402-404`) tidak pernah di-pop — user tetap melihat Profil.
3. `_AuthGate` (`lib/app.dart:270-283`) auto-spawn akun anonim di setiap `unauthenticated` — kalaupun keluar Profil, user mendarat di Home tamu, bukan Login.

## Scope

In scope (Flutter client saja):

- `lib/data/repositories/auth_repository.dart` — error mapping `signOut()`.
- `lib/presentation/blocs/auth/auth_bloc.dart` — flag `explicitSignOut` + rewrite `_onSignOut` + preservasi flag di `_onUserChanged` + reset flag di semua `submitting` emit lain.
- `lib/core/auth_gate_policy.dart` (NEW) — helper pure `shouldAutoSpawnGuest`.
- `lib/app.dart` — cabang gate `unauthenticated` + `explicitSignOut` → `AuthScreen()` tanpa auto-guest.
- `lib/presentation/screens/auth/auth_screen.dart` — tombol "Lanjut sebagai tamu" di mode normal.
- `lib/l10n/app_en.arb` + `lib/l10n/app_id.arb` + regenerate (`continueAsGuest`).
- `lib/presentation/screens/profile/profile_screen.dart` — listener AuthBloc (pop + snackbar) + null-safe `userId`.
- `test/auth_bloc_signout_test.dart` (NEW).
- `pubspec.yaml` — `0.26.7+89` → `0.26.8+90` (bugfix: patch +1, build +1).

Out of scope (JANGAN disentuh):

- Backend / migrasi DB / edge function — tidak ada.
- Scope `signOut()` Supabase (local vs global) — biarkan default seperti sekarang.
- Logika guest-wall fallback (`isGuestAuthWall` / `upgradeGuest`, fix 2026-09-12) — jangan diubah.
- Alur delete-account selain efek sampingnya yang ikut membaik (ia juga dispatch `AuthSignOutRequested`, otomatis mendarat di Login — itu diinginkan).

## Milestones

1. Failure tidak senyap (T1 + T2 + separuh T6).
2. Logout eksplisit dibedakan dari cold-start; gate render Login (T3 + separuh T6).
3. Pintu tamu di layar Login + string lokalisasi (T4).
4. Keluar dari Profil + null-safety (T5).
5. Test hijau + bump versi + verifikasi manual (T7 + T8 + T9).

## Tasks

- [x] **T1 — Error mapping `signOut()` di repository**
  File: `lib/data/repositories/auth_repository.dart:87-88`.
  Ganti:
  ```dart
  @override
  Future<void> signOut() => _client.auth.signOut();
  ```
  Menjadi:
  ```dart
  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }
  ```
  Catatan: import `failures.dart` (baris 8) dan `supabase_flutter` (baris 5) sudah ada. Tanpa ini, `AuthException` mentah lolos dari bloc tanpa tertangkap `on Failure`.

- [x] **T2 — Flag `explicitSignOut` di AuthBloc**
  File: `lib/presentation/blocs/auth/auth_bloc.dart`.
  - T2a. State (`AuthBlocState`, baris 80-117): tambah field `final bool explicitSignOut;`, default constructor `false`, param `copyWith({..., bool? explicitSignOut})` → `explicitSignOut ?? this.explicitSignOut`, dan **tambah ke `props`** (wajib, kalau tidak gate tidak rebuild).
  - T2b. Rewrite `_onSignOut` (baris 396-401) menjadi:
    ```dart
    Future<void> _onSignOut(
      AuthSignOutRequested e,
      Emitter<AuthBlocState> emit,
    ) async {
      final prevStatus = state.status;
      final prevUser = state.user;
      emit(
        state.copyWith(
          status: AuthStatus.submitting,
          errorMessage: null,
          infoMessage: null,
          explicitSignOut: false,
        ),
      );
      try {
        await _repo.signOut();
        emit(
          const AuthBlocState(
            status: AuthStatus.unauthenticated,
            explicitSignOut: true,
          ),
        );
      } on Failure catch (f) {
        emit(
          state.copyWith(
            status: prevStatus,
            user: prevUser,
            errorMessage: f.message,
          ),
        );
      } catch (e) {
        emit(
          state.copyWith(
            status: prevStatus,
            user: prevUser,
            errorMessage: e.toString(),
          ),
        );
      }
    }
    ```
    Pakai constructor `const AuthBlocState(...)` untuk sukses (bukan `copyWith(user: null)`) agar tidak ambigu dengan sentinel `copyWith`.
  - T2c. `_onUserChanged` (baris 226-236): preservasi flag saat stream datang belakangan (stream `onAuthStateChange(null)` bisa tiba SEBELUM atau SESUDAH emit eksplisit T2b — kedua urutan harus berakhir dengan flag `true`):
    ```dart
    void _onUserChanged(_AuthUserChanged e, Emitter<AuthBlocState> emit) {
      final status = _resolveStatus(e.user);
      emit(
        state.copyWith(
          status: status,
          user: e.user,
          errorMessage: null,
          infoMessage: null,
          explicitSignOut: e.user == null ? state.explicitSignOut : false,
        ),
      );
    }
    ```
  - T2d. Reset flag di SEMUA emit `submitting` lain (tambah `explicitSignOut: false`): `_onGoogleSignIn` (baris 154-160), `_onAnonymous` (242-248), `_onUpgradeAnonymous` (275-281), `_onSignIn` (304-310), `_onSignUp` (344-351). Emit sukses/gagal yang diturunkan via `copyWith` dari state `submitting` mewarisi `false` otomatis — TIDAK perlu diubah. `_onStarted` tidak perlu diubah (state awal sudah `false`).

- [x] **T3 — Gate: logout eksplisit → Login, bukan auto-guest**
  - T3a. File BARU `lib/core/auth_gate_policy.dart`:
    ```dart
    import '../presentation/blocs/auth/auth_bloc.dart';

    /// Decides whether [_AuthGate] should auto-spawn an anonymous session.
    ///
    /// Returns false after an explicit sign-out so the user lands on the
    /// login screen instead of being silently re-logged in as guest.
    /// Fresh starts (never signed out) still auto-spawn a guest.
    bool shouldAutoSpawnGuest(AuthBlocState state) {
      if (state.status != AuthStatus.unauthenticated) return false;
      return !state.explicitSignOut;
    }
    ```
  - T3b. File `lib/app.dart`, cabang `AuthStatus.unauthenticated` (baris 270-282) menjadi:
    ```dart
    case AuthStatus.unauthenticated:
      if (!shouldAutoSpawnGuest(state)) {
        return const AuthScreen();
      }
      if (!_anonymousRequested) {
        // ... existing auto-guest block unchanged ...
      }
      return const _PreparingSession();
    ```
    Tambah import helper di atas. `AuthScreen` sudah di-import (baris 39). Jangan ubah listener `_anonymousRequested`/`_startingGuestSession` dan JANGAN ubah cabang lain.

- [x] **T4 — Tombol "Lanjut sebagai tamu" di Login mode normal**
  File: `lib/presentation/screens/auth/auth_screen.dart`, setelah `OutlinedButton` Google (baris 320-328), tambah (HANYA saat bukan guest wall):
  ```dart
  if (!_isGuestWall) ...[
    const SizedBox(height: 12),
    TextButton.icon(
      onPressed: submitting
          ? null
          : () => context.read<AuthBloc>().add(
                const AuthAnonymousRequested(),
              ),
      icon: const Icon(Icons.person_outline),
      label: Text(l10n.continueAsGuest),
    ),
  ],
  ```
  `context` di sini adalah context param dari `builder: (context, state)` — valid karena `AuthBloc` ada di atas tree. Keputusan user: YA, tombol ini ada (kunci 2026-09-20).
  String baru di ARB (sisipkan setelah `logoutConfirmBody`, gaya plain key-value tanpa metadata, sama seperti key lain):
  - `app_en.arb`: `"continueAsGuest": "Continue as guest",`
  - `app_id.arb`: `"continueAsGuest": "Lanjut sebagai tamu",`
  Lalu jalankan `flutter gen-l10n` dan pastikan `lib/l10n/app_localizations*.dart` memuat getter `continueAsGuest` SEBELUM `flutter analyze`.

- [x] **T5 — Keluar dari Profil + snackbar error + null-safety**
  File: `lib/presentation/screens/profile/profile_screen.dart`.
  - T5a. `ProfileScreen.build` (baris 32): buat null-safe:
    ```dart
    final user = context.read<AuthBloc>().state.user;
    if (user == null) return const SizedBox.shrink();
    final userId = user.id;
    ```
    (Sisa body memakai `userId` seperti semula.)
  - T5b. Di `_ProfileView.build`, bungkus `Scaffold` dengan listener AuthBloc (import `flutter_bloc`, `AuthBloc`, `safe_error_message` semua sudah ada):
    ```dart
    return BlocListener<AuthBloc, AuthBlocState>(
      listenWhen: (prev, next) =>
          prev.status != next.status ||
          prev.errorMessage != next.errorMessage,
      listener: (context, authState) {
        if (authState.status == AuthStatus.unauthenticated &&
            authState.user == null) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else if (authState.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: context.colors.error,
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      safeErrorMessage(l10n, authState.errorMessage),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
      child: Scaffold( /* existing, unchanged */ ),
    );
    ```
    `l10n` sudah ada di scope `build`. `popUntil(isFirst)` aman: root adalah `_AuthGate` yang kini menampilkan `AuthScreen`. Jangan pakai `pop()` sekali (dialog konfirmasi sudah di-pop duluan).

- [x] **T6 — Test baru `test/auth_bloc_signout_test.dart`**
  Tiru pola mock dari `test/auth_bloc_guest_wall_test.dart` (MockAuthRepository + MockUser + stub `id`/`isAnonymous`). Isi lengkap yang diharapkan:
  - `signOut` sukses (seed `authenticated` + user non-anonim) → emit `[submitting(user tetap), unauthenticated + explicitSignOut:true + user null]`.
  - `signOut` throw `AuthFailure('Network error')` → emit `[submitting, authenticated + errorMessage + user tetap]`.
  - `shouldAutoSpawnGuest`: explicit → `false`; fresh unauthenticated → `true`; authenticated → `false`.
  - Catatan mocktail: `_onSignOut` tidak menyentuh getter `authChanges`, jadi tidak perlu stub stream. `AuthBloc(repo)` tanpa `AuthStarted` tidak memasang subscription — aman.
  - Seluruh suite lama (terutama `auth_bloc_guest_wall_test.dart`) harus tetap hijau — JANGAN ubah file test lama.

- [x] **T7 — Bump versi**
  `pubspec.yaml:4`: `0.26.7+89` → `0.26.8+90`.

- [x] **T8 — Verifikasi**
  Jalankan berurutan, semua harus hijau:
  ```
  flutter pub get
  flutter gen-l10n
  flutter analyze
  flutter test
  ```
  Manual di device (tidak butuh logcat — snackbar adalah bukti):
  1. Login email → buka Profil → Keluar → HARUS tampil halaman Login (tab Masuk/Daftar + tombol tamu), bukan Home.
  2. Dari Login tekan "Lanjut sebagai tamu" → masuk Home sebagai tamu.
  3. Login ulang dengan email yang sama → masuk normal.
  4. Matikan data/WiFi → coba logout → snackbar error muncul, tetap di Profil, sesi tidak hilang (nyalakan data, profil masih bisa dibuka).
  5. (Opsional) Alur hapus akun tetap mendarat di Login.

- [x] **T9 — Project memory**
  Setelah T8 hijau: tulis satu entry `.memory/2026-09-20/HHmmss-logout-fix.md` (format aktif: masalah, file diubah, keputusan, risiko, verifikasi, satu baris usulan Conventional Commit `fix(auth): ...`) dan update link Recent Entries + timestamp di `.memory/README.md`. Baca ulang kedua file tepat sebelum edit (agen lain mungkin konkuren). Jangan sentuh `PROJECT_MEMORY.md` (arsip read-only).

## Risks

- **Funnel berubah:** user yang tidak sengaja logout harus mengetik ulang kredensial (dulu "kembali sendiri" sebagai tamu). Mitigasi: tombol tamu T4 (sudah dikunci YA). Risiko diterima owner 2026-09-20.
- **Flag in-memory:** restart app setelah logout → kembali auto-guest (flag hilang). Wajar untuk state UI sesaat; didokumentasikan di sini, bukan bug.
- **Race stream vs emit eksplisit:** ditangani T2c; jika T2c dilewati, hasil akhir kadang auto-guest lagi (flaky). Jangan lewati T2c.
- **`props` lupa flag:** gate tidak rebuild → tetap `_PreparingSession` + auto-guest. Jangan lewati T2a-props.
- **Lupa `flutter gen-l10n`:** `analyze` gagal (getter hilang). Urutan T8 mengikat.
- **Sesi perangkat lain tetap hidup** (scope sign-out tak diubah) — di luar laporan, sengaja tidak disentuh agar blast radius kecil.

## Progress Log

- 2026-09-20 12:00:00 — Plan detail ditulis (untuk diimplementasikan model lain). Keputusan dikunci: pasca-logout HARUS ke Login (bukan guest-Home); tombol "Lanjut sebagai tamu" YA. Belum ada kode diubah.
- 2026-09-20 12:05:00 — Semua task T1–T9 selesai. Analyze 0 issues; test 206/206 (termasuk 8 test baru signOut + shouldAutoSpawnGuest). Versi bumped 0.26.8+90. Memory entry dibuat.

## Notes

- Perilaku login/signup/guest-wall hasil fix 2026-09-12 (fallback `guest` saat wall gagal) tidak diubah; hanya jalur logout eksplisit yang dibedakan via flag.
- Ini bugfix kecil client-only: tanpa registrasi ADM/TOGAF, tanpa migrasi, tanpa dokumen reasoning tambahan.
- File plan ini adalah single source of truth status: coret `- [x]` per task saat selesai dan tambah baris Progress Log per perkembangan.
