# Auth Callback Redirect Plan (ala Bagistruk: `bikinstiker://auth/callback`)

Created: 2026-09-23 13:20:00

## Objective

Ganti redirect auth dari `io.supabase.bikinstiker://login-callback/` menjadi
`bikinstiker://auth/callback` (cermin bagistruk), daftarkan di native Android,
dan tangani di Dart via `getSessionFromUrl`, sehingga link fallback
`{{ .ConfirmationURL }}` di email OTP membuka app dan menyelesaikan sesi —
bukan nyasar ke browser. Keputusan user: adopsi pola bagistruk.

## Scope

- Masuk: 1 konstanta terpusat, 2 call site
  (`auth_repository.dart:136,187`), `config.toml:25`, 1 intent-filter Android,
  1 service Dart baru + wiring `di.dart`/`main.dart`, 1 file test baru,
  Dashboard Redirect URLs.
- Keluar: iOS plist (tak perlu ubah — scheme `bikinstiker` sudah terdaftar,
  iOS match level-scheme), `share_mission_service.dart`, template email,
  OTP length/SMTP (tetap S8 plan OTP), migrasi DB, edge function.

## Requirement Traceability

| ID | Requirement / Finding | Ditangani oleh |
|----|----------------------|----------------|
| R1 | Satu nilai redirect untuk OTP + Google OAuth, tanpa drift hardcode ganda | S1 |
| R2 | Tap link email di Android membuka app | S2 |
| R3 | iOS tetap jalan tanpa ubah plist | S3 (verifikasi saja) |
| R4 | Callback ditukar jadi sesi (`getSessionFromUrl`), cold + warm start | S4 |
| R5 | Dashboard allowlist cocok persis (tanpa trailing slash) | S5 |
| R6 | Ada test otomatis untuk filter callback | S6 |
| F1 | 2 string hardcode `io.supabase...login-callback/` (dengan trailing slash) | S1 |
| F2 | Tidak ada intent-filter Android untuk scheme auth | S2 |
| F3 | Scheme `bikinstiker` sudah terdaftar di iOS (`Info.plist:78`) | S3 |
| F4 | `getSessionFromUrl` nol hit di `lib/` — link fallback mati total | S4 |
| F5 | Dashboard Redirect URLs belum memuat nilai baru | S5 |

## Milestones

1. Nilai tunggal + native (S1, S2, S3) — fondasi, risiko rendah-sedang.
2. Handler Dart + test (S4, S6) — logika inti.
3. Dashboard + verifikasi penuh (S5, S7) — bukti selesai.

## Tasks

- [x] S1 Konstanta terpusat + 2 call site + config.toml
- [x] S2 Intent-filter Android
- [x] S3 Verifikasi iOS (tanpa edit)
- [x] S4 Service AuthCallbackHandler + wiring
- [ ] S5 Dashboard Redirect URLs (manual, owner)
- [x] S6 Test baru auth callback
- [x] S7 Verifikasi akhir + smoke tap-link

---

## Implementation Steps (atomik, deterministik)

### S1 — Konstanta redirect terpusat + ganti 2 call site + `config.toml`

- Tujuan langkah: Satu nilai `bikinstiker://auth/callback` (tanpa trailing
  slash) dipakai OTP + Google OAuth + config, tanpa drift hardcode ganda.
- Finding/requirement: R1, R5, F1.
- Dependency: Tidak ada. Wajib selesai sebelum S2 (nilai final untuk
  intent-filter), S4 (konstanta dipakai repo), S5 (nilai untuk Dashboard).
- File yang harus dibaca:
  - `lib/core/constants/env_constants.dart` (16 baris)
  - `lib/data/repositories/auth_repository.dart` (baris 125-195)
  - `supabase/config.toml` (baris 22-32)
- File yang harus diubah:
  - `lib/core/constants/env_constants.dart`
  - `lib/data/repositories/auth_repository.dart`
  - `supabase/config.toml`
- Class/function/method/type/simbol terkait:
  - `EnvConstants.authCallbackUrl` (baru, `static const String`)
  - `SupabaseAuthRepository.signInWithGoogle` (param `redirectTo`)
  - `SupabaseAuthRepository.sendEmailOtp` (param `emailRedirectTo`)
- Kondisi implementasi saat ini:
  - `EnvConstants` hanya punya `googleWebClientId`, `supabaseUrl`,
    `supabaseAnonKey`. Tidak ada konstanta callback.
  - Baris 136: `redirectTo: 'io.supabase.bikinstiker://login-callback/',`
  - Baris 187: `emailRedirectTo: 'io.supabase.bikinstiker://login-callback/',`
  - `config.toml:25`:
    `additional_redirect_urls = ["io.supabase.bikinstiker://login-callback"]`
    (tanpa slash — mismatch dengan kode yang pakai slash).
- Perubahan konkret (urutan wajib):
  1. Di `env_constants.dart`, setelah getter `supabaseAnonKey` (baris 12-15),
     tambahkan persis:
     ```dart
     /// Deep-link callback for Supabase auth emails (OTP magic-link fallback
     /// and Google OAuth). Must be allowlisted in Dashboard → Redirect URLs.
     /// No trailing slash: the allowlist match is exact.
     static const authCallbackUrl = 'bikinstiker://auth/callback';
     ```
  2. Di `auth_repository.dart` baris 136, ganti menjadi persis:
     `redirectTo: EnvConstants.authCallbackUrl,`
  3. Di `auth_repository.dart` baris 187, ganti menjadi persis:
     `emailRedirectTo: EnvConstants.authCallbackUrl,`
  4. Di `config.toml:25`, ganti menjadi persis:
     `additional_redirect_urls = ["bikinstiker://auth/callback"]`
- Urutan perubahan di dalam file: (1) konstanta dulu, (2)-(3) call site,
  (4) config. Jangan ubah baris lain.
- Behavior yang harus dipertahankan: Signature method, error mapping
  (`AuthException → AuthFailure`), dan nilai non-redirect lain tidak berubah.
  Google OAuth tetap memanggil endpoint yang sama, hanya nilai redirect beda.
- Error handling dan edge case:
  - Trailing slash dihapus di KETIGA tempat sekaligus; jangan sisakan satu
    pun varian berslash agar allowlist cocok persis.
  - Env var ala bagistruk (`AUTH_EMAIL_REDIRECT_TO`) SENGAJA tidak dipakai:
    satu nilai untuk semua environment, dan `.env` ter-bundle ke APK —
    const menghindari plumbing tanpa manfaat.
- Test yang harus ditambahkan atau diperbarui: Tidak ada di S1 (repo sudah
  di-cover mock di test OTP existing; nilai const diverifikasi via grep).
- Input test dan expected result: (didefinisikan di S6-S7).
- Command verifikasi yang tersedia di repository:
  1. `flutter analyze` (dari repo root)
- Hasil verifikasi yang diharapkan: `No issues found!`
- Completion criteria:
  - `EnvConstants.authCallbackUrl` ada dan bernilai
    `bikinstiker://auth/callback` (tanpa slash).
  - Grep `login-callback` di `lib/` dan `supabase/config.toml` nol hit.
  - `flutter analyze` bersih.
- File atau area yang tidak boleh diubah: file native (`android/`, `ios/`),
  `share_mission_service.dart`, `app.dart`, bloc, test, template email.

### S2 — Intent-filter Android untuk `bikinstiker://auth/callback`

- Tujuan langkah: Tap link `bikinstiker://auth/*` di Android membuka
  `MainActivity` (bukan browser).
- Finding/requirement: R2, F2.
- Dependency: Wajib setelah S1 (skema/host/path final). Independen dari
  S3-S4 secara file, tapi S7 (tap-test) blokir sampai S2+S4 selesai.
- File yang harus dibaca:
  - `android/app/src/main/AndroidManifest.xml` (full, 80 baris)
  - Referensi:
    `C:\Works\github.com\alamaby\bagistruk\android\app\src\main\AndroidManifest.xml`
    baris 64-74 (pola `autoVerify="false"`, scheme/host/path terpisah)
- File yang harus diubah:
  - `android/app/src/main/AndroidManifest.xml` (satu-satunya)
- Class/function/simbol terkait: `<intent-filter>`, `android:scheme`,
  `android:host`, `android:path`, `MainActivity` (`singleTop`).
- Kondisi implementasi saat ini:
  - `MainActivity` punya 3 filter: MAIN/LAUNCHER (42-45), App Link https
    share-claimed (47-52), custom scheme `bikinstiker://share-claimed` (54-59).
  - Tidak ada filter untuk host `auth`.
- Perubahan konkret (satu sisipan, setelah filter share fallback baris 54-59
  dan sebelum `</activity>` baris 60), persis:
  ```xml
  <!-- Supabase auth callback: bikinstiker://auth/callback -->
  <intent-filter android:autoVerify="false">
      <action android:name="android.intent.action.VIEW"/>
      <category android:name="android.intent.category.DEFAULT"/>
      <category android:name="android.intent.category.BROWSABLE"/>
      <data android:scheme="bikinstiker" android:host="auth" android:path="/callback"/>
  </intent-filter>
  ```
- Urutan perubahan di dalam file: sisipkan sebagai filter TERAKHIR di dalam
  `<activity>`. Jangan pindahkan/mengubah 3 filter existing.
- Behavior yang harus dipertahankan: `launchMode="singleTop"`,
  `taskAffinity=""`, semua filter share, provider, permission — byte-identik.
  `autoVerify="false"` disengaja (custom scheme, bukan App Link; sama seperti
  bagistruk dan filter share existing).
- Error handling dan edge case:
  - Path dibatasi `/callback` agar link share (`share-claimed`) tidak
    tertangkap filter ini dan sebaliknya.
  - Native salah tidak terdeteksi `flutter analyze`; satu-satunya bukti
    adalah tap-test S7 — jangan anggap selesai sebelum itu.
- Test yang harus ditambahkan atau diperbarui: Tidak ada test otomatis di S2
  (verifikasi via tap-test manual S7).
- Input test dan expected result: (S7: tap link → app terbuka).
- Command verifikasi yang tersedia di repository:
  1. `flutter build apk --split-per-abi --debug` (wajib rebuild penuh karena
     native berubah; install ulang APK di device uji)
- Hasil verifikasi yang diharapkan: Build sukses 3 APK.
- Completion criteria: Filter ada persis seperti snippet; build sukses.
- File atau area yang tidak boleh diubah: `build.gradle.kts`, iOS, Dart,
  filter/permission/provider lain di manifest.

### S3 — Verifikasi iOS tanpa edit

- Tujuan langkah: Buktikan tidak ada perubahan iOS yang diperlukan.
- Finding/requirement: R3, F3.
- Dependency: Setelah S1 (nilai final). Tidak memblokir langkah lain.
- File yang harus dibaca:
  - `ios/Runner/Info.plist` (baris 71-81)
- File yang harus diubah: TIDAK ADA.
- Simbol terkait: `CFBundleURLTypes`, `CFBundleURLSchemes` (= `bikinstiker`).
- Kondisi implementasi saat ini: Scheme `bikinstiker` sudah terdaftar
  (baris 78) untuk share. iOS mencocokkan custom URL di level scheme saja.
- Perubahan konkret: Tidak ada. Jika scheme di S1 adalah `bikinstiker`,
  `bikinstiker://auth/callback` otomatis membuka app.
- Behavior yang harus dipertahankan: Entitlements applinks dan URL types
  tidak berubah.
- Error handling: Jika S1 memakai scheme selain `bikinstiker`, S3 batal dan
  plist wajib ditambah — dengan nilai S1 saat ini hal itu tidak terjadi.
- Test: Tidak ada. Verifikasi via tap-test iOS bila device tersedia
  (opsional); Android (S7) wajib.
- Command verifikasi: Tidak ada (read-only check).
- Hasil verifikasi yang diharapkan: Konfirmasi tertulis bahwa scheme cocok.
- Completion criteria: Checklist ini dicentang + alasan tercatat.
- File atau area yang tidak boleh diubah: Seluruh `ios/`.

### S4 — Service `AuthCallbackHandler` + wiring `di.dart` / `main.dart`

- Tujuan langkah: Tukar callback jadi sesi via `getSessionFromUrl` pada cold
  start dan warm start, tanpa mengganggu share flow dan tanpa crash startup.
- Finding/requirement: R4, F4.
- Dependency: Wajib setelah S1 (nilai filter). S2 boleh paralel (file beda).
  Blokir S6 (test file baru menarget simbol dari langkah ini) dan S7.
- File yang harus dibaca:
  - `lib/core/services/share_mission_service.dart` (full, 146 baris — pola
    `AppLinks`, `getInitialLink`, `uriLinkStream`, lazy `_ensureInitialized`)
  - `lib/core/di.dart` (baris 24, 74)
  - `lib/main.dart` (full, 35 baris — `_drainInitialShareDeepLink`)
  - Referensi:
    `C:\Works\github.com\alamaby\bagistruk\lib\data\services\deep_link_handler.dart`
    baris 98-142 (aturan swallow double-consume: abaikan jika message
    mengandung `flow_state`/`already`)
- File yang harus diubah (1 baru + 2 edit):
  - BARU `lib/core/services/auth_callback_handler.dart`
  - `lib/core/di.dart` (+1 import, +1 registrasi)
  - `lib/main.dart` (+1 import, +1 init call)
- Class/function/method/type/simbol terkait:
  - `bool isAuthCallbackUri(Uri uri)` (top-level, untuk test)
  - `class AuthCallbackHandler` (`init()`, `_consume(Uri)`, `dispose()`)
  - `SupabaseClient.auth.getSessionFromUrl`, `AppLinks.getInitialLink`,
    `AppLinks.uriLinkStream`, `getIt.registerLazySingleton`, `debugPrint`
- Kondisi implementasi saat ini:
  - Tidak ada handler auth callback; `getSessionFromUrl` nol hit di `lib/`.
  - `main.dart:26` drain share link lalu `runApp`; `di.dart:74` registrasi
    `ShareMissionService` sebagai lazy singleton terakhir sebelum onboarding.
  - `_AuthGate` (`app.dart`) bereaksi ke `onAuthStateChange` → tidak butuh
    kerja router (beda dari bagistruk yang pakai go_router).
- Perubahan konkret (urutan wajib):
  1. Tulis file baru `lib/core/services/auth_callback_handler.dart` persis:
     ```dart
     import 'dart:async';

     import 'package:app_links/app_links.dart';
     import 'package:flutter/foundation.dart';
     import 'package:supabase_flutter/supabase_flutter.dart';

     /// Returns true if [uri] is a Supabase auth callback
     /// (`bikinstiker://auth/callback`, with or without query parameters).
     /// Kept top-level so it can be unit-tested without mocks.
     bool isAuthCallbackUri(Uri uri) =>
         uri.scheme == 'bikinstiker' && uri.host == 'auth';

     /// Consumes Supabase auth-callback deep links and exchanges them for a
     /// session via `getSessionFromUrl`.
     ///
     /// Covers cold start ([AppLinks.getInitialLink]) and warm start
     /// ([AppLinks.uriLinkStream]). Share-claim links are ignored here; they
     /// belong to [ShareMissionService] whose filter is disjoint.
     class AuthCallbackHandler {
       AuthCallbackHandler({SupabaseClient? client, AppLinks? appLinks})
         : _client = client ?? Supabase.instance.client,
           _appLinks = appLinks ?? AppLinks();

       final SupabaseClient _client;
       final AppLinks _appLinks;

       StreamSubscription<Uri>? _linkSubscription;
       bool _initialized = false;

       /// Starts listening. Safe to call once; subsequent calls are no-ops.
       /// Never throws: startup must not crash because of deep links.
       Future<void> init() async {
         if (_initialized) return;
         _initialized = true;
         try {
           final initial = await _appLinks.getInitialLink();
           if (initial != null) await _consume(initial);
           _linkSubscription = _appLinks.uriLinkStream.listen(_consume);
         } catch (e) {
           debugPrint('AuthCallbackHandler: failed to start listener: $e');
         }
       }

       Future<void> _consume(Uri uri) async {
         if (!isAuthCallbackUri(uri)) return;
         try {
           await _client.auth.getSessionFromUrl(uri);
         } catch (e) {
           // The same link can be observed twice (initial + stream, or double
           // emission). An already-consumed link is not an error.
           final msg = e.toString().toLowerCase();
           if (msg.contains('flow_state') || msg.contains('already')) return;
           debugPrint('AuthCallbackHandler: getSessionFromUrl failed: $e');
         }
       }

       Future<void> dispose() async {
         await _linkSubscription?.cancel();
         _linkSubscription = null;
       }
     }
     ```
  2. Di `di.dart`: tambah import
     `import 'services/auth_callback_handler.dart';` setelah import
     `share_mission_service.dart` (baris 24), dan setelah registrasi
     `ShareMissionService` (baris 74) tambahkan:
     `getIt.registerLazySingleton<AuthCallbackHandler>(() => AuthCallbackHandler());`
  3. Di `main.dart`: tambah import
     `import 'core/services/auth_callback_handler.dart';` setelah import
     share service (baris 6), dan setelah baris 26
     (`await _drainInitialShareDeepLink();`) tambahkan:
     `await getIt<AuthCallbackHandler>().init();`
     Urutan ini menjaga share behavior byte-identik; kedua service boleh
     memanggil `getInitialLink` karena filter disjoint
     (`_maybeBuildClaim` return null untuk URI auth — verified).
- Behavior yang harus dipertahankan: Share drain/startup order, `runApp`
  timing, semua bloc listener. Tidak ada navigasi manual: sesi hasil
  `getSessionFromUrl` memicu `onAuthStateChange` → `_AuthGate` pindah ke
  `authenticated` dengan sendirinya.
- Error handling dan edge case:
  - `init()` tidak pernah throw (try/catch + flag).
  - Double-consume (`flow_state_not_found`, `already_used`) ditelan diam;
    error lain hanya `debugPrint` (aturan copy bagistruk).
  - URI non-auth (termasuk share-claimed) diabaikan via filter pertama.
  - Cold start: initial link diproses sebelum `runApp`, sebelum UI mount —
    tidak ada context/navigator yang disentuh.
- Test yang harus ditambahkan atau diperbarui: S6 (4 kasus pure function).
  Tidak ubah test lama.
- Input test dan expected result: (S6).
- Command verifikasi yang tersedia di repository:
  1. `flutter analyze`
- Hasil verifikasi yang diharapkan: `No issues found!`
- Completion criteria: File ada persis snippet; 2 wiring ada; `analyze`
  bersih; `share_mission_service.dart` dan `app.dart` untouched.
- File atau area yang tidak boleh diubah: `share_mission_service.dart`,
  `app.dart`, bloc, repo, `mission_bloc.dart`, manifest/plist.

### S5 — Dashboard Redirect URLs (manual, owner)

- Tujuan langkah: Allowlist cocok persis dengan nilai S1 agar Supabase tidak
  menolak `signInWithOtp` / OAuth.
- Finding/requirement: R5, F5.
- Dependency: Setelah S1 (nilai final). Independen kode; smoke S7 blokir
  sampai ini selesai.
- File yang harus dibaca: `supabase/config.toml:22-32` (referensi nilai).
- File yang harus diubah: TIDAK ADA file repo. Semua via Dashboard.
- Perubahan konkret (checklist):
  1. Authentication → URL Configuration → Redirect URLs: TAMBAH
     `bikinstiker://auth/callback` (tanpa trailing slash, persis S1).
  2. BIARKAN entry lama `io.supabase.bikinstiker://login-callback` tetap ada
     selama transisi (harmless; cegah sesi/link lama rusak). Boleh dihapus
     setelah rilis ini teradopsi penuh.
  3. Sisa S8 plan OTP tidak berubah: OTP length=8, kedua template mengandung
     `{{ .Token }}`, SMTP Resend.
- Behavior dipertahankan: Site URL dan setting lain tidak diubah.
- Edge case: Jika email LAMA pun gagal kirim dengan error redirect/allowlist,
  itu misconfig S5 — bedakan dari `otp_disabled` by-design untuk email baru
  (R2 plan OTP).
- Test: Smoke S7 (dua kasus kirim).
- Command verifikasi: Tidak ada CLI; via UI Dashboard + smoke.
- Hasil verifikasi yang diharapkan: Entry baru tersimpan; smoke kirim sukses.
- Completion criteria: Entry baru ada + smoke dua kasus lolos.
- File atau area yang tidak boleh diubah: File repo apapun.

### S6 — Test baru `test/auth_callback_handler_test.dart`

- Tujuan langkah: Kunci filter callback agar perubahan future tidak
  menelan link share atau sebaliknya.
- Finding/requirement: R6.
- Dependency: Wajib setelah S4 (simbol `isAuthCallbackUri`).
- File yang harus dibaca:
  - `lib/core/services/auth_callback_handler.dart` (hasil S4)
  - Pola grup: `test/safe_error_message_test.dart` (gaya `group`/`test`)
- File yang harus diubah (dibuat):
  - BARU `test/auth_callback_handler_test.dart`
- Simbol terkait: `isAuthCallbackUri`, `group`, `test`, `expect`, `isTrue`,
  `isFalse`.
- Kondisi implementasi saat ini: 28+ file test, tidak ada test auth callback.
- Perubahan konkret (tulis file persis):
  ```dart
  import 'package:bikin_stiker/core/services/auth_callback_handler.dart';
  import 'package:flutter_test/flutter_test.dart';

  void main() {
    group('isAuthCallbackUri', () {
      test('auth callback without query returns true', () {
        expect(
          isAuthCallbackUri(Uri.parse('bikinstiker://auth/callback')),
          isTrue,
        );
      });
      test('auth callback with code query returns true', () {
        expect(
          isAuthCallbackUri(
            Uri.parse('bikinstiker://auth/callback?code=abc123'),
          ),
          isTrue,
        );
      });
      test('share-claim custom scheme returns false', () {
        expect(
          isAuthCallbackUri(Uri.parse('bikinstiker://share-claimed/xyz')),
          isFalse,
        );
      });
      test('https share-claim link returns false', () {
        expect(
          isAuthCallbackUri(
            Uri.parse('https://bikinstiker.alamaby.com/share-claimed/xyz'),
          ),
          isFalse,
        );
      });
    });
  }
  ```
- Behavior dipertahankan: Tidak ubah test lama.
- Error handling: Tidak ada (pure function).
- Input test dan expected result: Tercantum di atas (2 true, 2 false).
- Command verifikasi yang tersedia di repository:
  1. `flutter test test/auth_callback_handler_test.dart`
- Hasil verifikasi yang diharapkan: `All tests passed!` (4/4).
- Completion criteria: File ada, 4 kasus hijau, test lama untouched.
- File atau area yang tidak boleh diubah: Test lama, kode `lib/` di langkah
  ini.

### S7 — Verifikasi akhir + smoke tap-link

- Tujuan langkah: Bukti tidak ada regresi dan link fallback hidup.
- Dependency: Wajib setelah S1-S6 semua.
- File yang harus dibaca: Tidak ada (hanya jalankan).
- File yang harus diubah: Tidak ada.
- Command verifikasi (urutan wajib, dari repo root):
  1. `flutter pub get`
  2. `flutter analyze` → diharapkan `No issues found!`
  3. `flutter test test/auth_callback_handler_test.dart` → `All tests passed!`
  4. `flutter test` (full) → semua hijau (baseline pasca-OTP: 221 passed;
     setelah S6 harus ≥225)
  5. `flutter build apk --split-per-abi --debug` → 3 APK (wajib rebuild penuh
     + install ulang karena S2 native berubah)
  6. Smoke manual (device Android, app terinstall ulang dari APK langkah 5):
     (a) kirim OTP ke email lama → tap **link** di email → app terbuka +
     status `authenticated`; (b) ulangi dengan app killed (cold start) → sama;
     (c) kode 8-digit tetap jalan (ketik manual → verify sukses);
     (d) Google login smoke (redirectTo ikut pindah scheme).
- Completion criteria: analyze 0, test target + full hijau, build sukses,
  4 smoke lolos, Progress Log plan diisi.
- File atau area yang tidak boleh diubah: Kode apapun. Jika merah, kembali ke
  langkah terkait; jangan hotfix di S7.

## Risks

- Native salah tidak terdeteksi `analyze` — hanya tap-test S7 yang
  membuktikan. Mitigasi: S7 smoke (a)-(b) wajib, bukan opsional.
- `getSessionFromUrl` double-consume (`flow_state_not_found`) — pernah
  terjadi di bagistruk; ditangani aturan swallow S4 (copy gedrag mereka).
- Google OAuth ikut pindah scheme (satu const) — smoke (d) menutupnya; jalur
  modal IdToken tidak memakai redirect sehingga risiko rendah.
-Dto: Enum `AuthStatus.submitting` overlay di `_AuthGate` tidak terkait —
  handler tidak emit bloc event, jadi tidak ada interferensi.
- Counter-argument: alternatif tanpa handler sama sekali (opsi A awal) tetap
  valid untuk flow kode; S1-S7 ini dipilih karena user memutuskan link
  fallback harus hidup. Biaya: file native + 1 service + rebuild penuh.

## Blockers / Open Questions

- Tidak ada blocker teknis. Satu keputusan yang diambil eksplisit (bukan
  diam-diam): URL lama `io.supabase...` DIBIARKAN di Dashboard selama
  transisi (S5 poin 2) — harmless, bisa dihapus setelah adopsi penuh.
- Satu keputusan eksplisit: tanpa env var ala bagistruk (S1) — satu nilai
  untuk semua environment, `.env` ter-bundle ke APK sehingga const lebih
  aman dari drift.

## Progress Log

- 2026-09-23 13:20:00 — Plan ditulis (S1-S7). Belum ada kode diubah. Menunggu
  eksekusi bertahap S1→S7.
- 2026-09-23 14:00:00 — S1 selesai: konstanta `authCallbackUrl` ditambahkan ke
  `env_constants.dart`, 2 call site di `auth_repository.dart` diganti,
  `config.toml:25` diperbarui. Grep `login-callback` di `lib/` dan
  `config.toml` nol hit.
- 2026-09-23 14:01:00 — S2 selesai: intent-filter `bikinstiker://auth/callback`
  disisipkan di `AndroidManifest.xml` setelah filter share-claimed.
- 2026-09-23 14:01:00 — S3 selesai: iOS `Info.plist:78` sudah mendaftarkan
  scheme `bikinstiker`, tidak perlu edit.
- 2026-09-23 14:02:00 — S4 selesai: file baru
  `lib/core/services/auth_callback_handler.dart` dibuat; wiring di
  `di.dart` (+lazy singleton) dan `main.dart` (+init call setelah share drain).
- 2026-09-23 14:03:00 — S6 selesai: test `test/auth_callback_handler_test.dart`
  dibuat (4 kasus), semua hijau.
- 2026-09-23 14:04:00 — S7 verifikasi: `flutter analyze` No issues,
  `flutter test` 225 passed, APK 3 ABI build sukses. Smoke tap-link manual
  (owner) + Dashboard S5 masih pending.

## Notes

- Skala fitur kecil-menengah → tanpa seremonial TOGAF/ODA penuh; referensi
  utama adalah implementasi bagistruk yang sudah terbukti
  (`auth_remote_datasource.dart`, `deep_link_handler.dart`,
  `AndroidManifest.xml:64-74`, `Info.plist`, `PROJECT_MEMORY.md:457-460`).
- Satu file = satu plan. Jangan overwrite plan OTP
  (`plans/2026-09-22-email-otp-login-plan.md`).
- Env guard: dilarang print/cat `.env*`, `sb_secret_*`, `sb_publishable_*`,
  `SUPABASE_*`, `CRON_SECRET` ke chat/log.

---

## Handoff Checklist (untuk model kecil)

- [x] S1: tambah const → ganti 2 call site → config.toml; grep
  `login-callback` nol hit; `analyze` bersih.
- [x] S2: sisipkan tepat 1 intent-filter setelah filter share; filter lain
  untouched.
- [x] S3: baca plist, tanpa edit, centang dengan alasan.
- [x] S4: tulis file baru persis snippet → wiring di + main; share service
  dan app.dart untouched; `analyze` bersih.
- [ ] S5: owner tambah Redirect URL baru (lama dibiarkan) + sisa S8 OTP.
- [x] S6: tulis file test persis snippet; 4/4 hijau; test lama untouched.
- [x] S7: pub get → analyze → test target → full test (225) → rebuild APK
  (3 ABI) sukses; smoke tap-link (manual, owner).
- [ ] Dilarang: migrasi DB, edge function, `build.gradle.kts`, iOS edits,
  `share_mission_service.dart`, `app.dart`, bloc, repo error mapping,
  template email, staging/commit selain file plan ini.
