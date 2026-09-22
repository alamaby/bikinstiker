# Email OTP Login Implementation Plan (shouldCreateUser=false, 8 digit)

Created: 2026-09-22 12:00:00

## Objective

Tambah alternatif login via kode OTP 8-digit yang dikirim ke email, tanpa menghapus alur `email+password` / Google / guest. Referensi implementasi: sibling repo `bagistruk` (native Supabase Auth, tanpa edge function / tabel OTP kustom). Keputusan final user: alternatif login saja, `shouldCreateUser=false`, guest wall OTP boleh hilang, kode 8 digit.

## Scope

- Masuk: `AuthRepository`, `AuthBloc`, `AuthScreen` + layar `OtpVerifyScreen` baru, `l10n en/id`, `safe_error_message`, config manual Dashboard Supabase (OTP length, SMTP, template `{{ .Token }}`), test baru.
- Keluar: hapus password, migrasi stiker guest via OTP, throttle server kustom, perubahan migrasi DB, perubahan edge function, perubahan Android/iOS manifest, perubahan `_AuthGate` / `auth_gate_policy`.

## Requirement Traceability

| ID | Requirement / Finding | Ditangani oleh |
|----|----------------------|----------------|
| R1 | Alternatif login OTP, daftar tetap password | S1, S2, S5, S6 |
| R2 | `shouldCreateUser=false`, email baru ditolak OTP | S1, S2, S3, S7 |
| R3 | Kode 8 digit konsisten app + Dashboard | S4, S6, S8 |
| R4 | Guest wall OTP boleh hilang (seperti sign-in password) | S2, S5, S7 |
| R5 | Resend cooldown 60s client | S6, S7 |
| R6 | Error mapping aman (`otp_disabled`, `otp_expired`, rate-limit) | S3, S7 |
| R7 | l10n en + id untuk semua string OTP baru | S4, S7 |
| R8 | Alur password/Google/guest tidak rusak | S2, S5, S9 |
| R9 | Dashboard OTP length 8 + template wajib `{{ .Token }}` | S8, S9 |
| F1 | `bikinstiker` saat ini nol OTP (`signInWithOtp/verifyOTP` 0 hit) | S1 |
| F2 | Failure guest wall harus stay `guest` (regresi legal-consent bounce) | S2, S7 |
| F3 | `bagistruk` gap: `otp_expired` belum dipetakan, 8 vs 6 mismatch | S3, S8 |

## Milestones

1. Fondasi data + string (S1, S4) — tanpa UI, risiko rendah.
2. Logika + error mapping (S2, S3) — inti behavior, risiko sedang.
3. UI (S5, S6) — terlihat user, tergantung milestone 1-2.
4. Verifikasi otomatis + manual (S7, S8, S9) — bukti selesai.

## Tasks

- [ ] S1 Repository OTP
- [ ] S4 l10n keys en/id + regen
- [ ] S2 Bloc events/state/handlers
- [ ] S3 Error mapping aman
- [ ] S5 Tombol OTP di AuthScreen
- [ ] S6 Layar OtpVerifyScreen baru
- [ ] S7 Test baru + update test lama
- [ ] S8 Konfigurasi Dashboard manual
- [ ] S9 Verifikasi akhir analyze + test

---

## Implementation Steps (atomik, deterministik)

### S1 — Repository: `sendEmailOtp` + `verifyEmailOtp`

- Tujuan langkah: Menyediakan akses data OTP Supabase tanpa mengubah alur existing.
- Finding/requirement: F1, R1, R2.
- Dependency: Tidak ada. Wajib selesai sebelum S2, S7.
- File yang harus dibaca:
  - `lib/data/repositories/auth_repository.dart` (full, 252 baris, verified 2026-09-22)
  - `C:\Works\github.com\alamaby\bagistruk\lib\data\datasources\auth_remote_datasource.dart` baris 129-160 (referensi API)
- File yang harus diubah:
  - `lib/data/repositories/auth_repository.dart` (satu-satunya file kode di langkah ini)
- Class/function/method/type/simbol terkait:
  - `abstract class AuthRepository`
  - `class SupabaseAuthRepository`
  - `Future<void> sendEmailOtp({required String email})`
  - `Future<void> verifyEmailOtp({required String email, required String token})`
  - `SupabaseClient.auth.signInWithOtp`, `verifyOTP`, `OtpType.email`, `AuthException`, `AuthFailure`, `UnknownFailure`
- Kondisi implementasi saat ini:
  - Interface baris 10-34 memiliki 11 anggota (`authChanges`, `currentUser`, `signIn`, `signUp`, `signOut`, `signInAnonymously`, `signInWithGoogle`, `upgradeAnonymousAccount`, `grantRegisteredBonus`, `signInWithGoogleModal`, `createGuestMigrationToken`, `migrateGuestStickers`). Tidak ada anggota OTP.
  - Impl `SupabaseAuthRepository` baris 55-252. Pola error: `on AuthException catch (e) throw AuthFailure(e.message)`, `catch (e) throw UnknownFailure(e.toString())`, kecuali `createGuestMigrationToken/migrateGuestStickers` yang rethrow `AuthFailure`.
  - Import sudah ada `supabase_flutter` (menyediakan `OtpType`).
- Perubahan konkret:
  1. Di `abstract class AuthRepository`, setelah deklarasi `signInWithGoogleModal()` (baris 26) dan sebelum `createGuestMigrationToken()` (baris 32), sisipkan dua deklarasi persis:
     ```dart
     Future<void> sendEmailOtp({required String email});
     Future<void> verifyEmailOtp({required String email, required String token});
     ```
  2. Di `SupabaseAuthRepository`, setelah method `signInWithGoogleModal()` (baris 140-173) dan sebelum `createGuestMigrationToken()` (baris 176), sisipkan dua method persis:
     ```dart
     @override
     Future<void> sendEmailOtp({required String email}) async {
       try {
         await _client.auth.signInWithOtp(
           email: email,
           shouldCreateUser: false,
           emailRedirectTo: 'io.supabase.bikinstiker://login-callback/',
         );
       } on AuthException catch (e) {
         throw AuthFailure(e.message);
       } catch (e) {
         throw UnknownFailure(e.toString());
       }
     }

     @override
     Future<void> verifyEmailOtp({
       required String email,
       required String token,
     }) async {
       try {
         await _client.auth.verifyOTP(
           email: email,
           token: token,
           type: OtpType.email,
         );
       } on AuthException catch (e) {
         throw AuthFailure(e.message);
       } catch (e) {
         throw UnknownFailure(e.toString());
       }
     }
     ```
  3. Jangan tambah parameter `data:{language}`, `shouldCreateUser:true`, atau `migrate_anon_data` (sengaja dibuang: R2=false, R4=boleh hilang).
- Urutan perubahan di dalam file: (a) interface, (b) impl. Jangan ubah urutan method lain.
- Behavior yang harus dipertahankan: Semua method existing tidak berubah signature/body. `emailRedirectTo` sama persis dengan `signInWithGoogle()` baris 130 (`io.supabase.bikinstiker://login-callback/`).
- Error handling dan edge case:
  - Email baru → Supabase throw `AuthException(message: "Signups not allowed for otp")`. Teruskan sebagai `AuthFailure` apa adanya; mapping ke l10n dilakukan di S3, bukan di repo.
  - `error.code` Supabase (`otp_disabled`) sering hilang di client — implementer DILARANG branching pada `code`; hanya teruskan `message`.
  - Timeout/jaringan → `UnknownFailure` / `AuthFailure` sesuai pola existing.
- Test: Tidak tambah test di S1. Verifikasi via S7.
- Input test dan expected result: (didefinisikan di S7).
- Command verifikasi: `flutter analyze` (harus 0 issue untuk file ini).
- Hasil verifikasi yang diharapkan: Tidak ada error `missing_override`, `non_abstract_class_inherits_abstract_member`.
- Completion criteria: Interface memiliki 13 anggota, impl meng-override keduanya, `flutter analyze` bersih untuk file ini.
- File atau area yang tidak boleh diubah: `supabase/*`, `android/*`, `ios/*`, `lib/app.dart`, `lib/core/auth_gate_policy.dart`, file test apapun.

### S4 — l10n: keys OTP en/id + regen (didahulukan sebelum S3/S5/S6)

- Tujuan langkah: Menyediakan semua string OTP sebelum dipakai error-mapper dan UI, agar tidak ada string hardcode.
- Finding/requirement: R3, R7.
- Dependency: Tidak ada dependency kode. Wajib selesai sebelum S3, S5, S6, S7.
- File yang harus dibaca:
  - `lib/l10n/app_en.arb` (437 baris, locale en)
  - `lib/l10n/app_id.arb` (437 baris, locale id)
  - `l10n.yaml` (`arb-dir: lib/l10n`, `template-arb-file: app_en.arb`)
- File yang harus diubah:
  - `lib/l10n/app_en.arb`
  - `lib/l10n/app_id.arb`
  - File generated `lib/l10n/app_localizations*.dart` HANYA via generator, dilarang edit manual.
- Class/function/simbol terkait: `AppLocalizations.of(context).<key>`, `flutter gen-l10n`.
- Kondisi saat ini: Tidak ada key mengandung `otp` (verified grep). Key terakhir `themeDark` baris 436, penutup `}` baris 437 di kedua file.
- Perubahan konkret (urutan: en dulu, lalu id, lalu regen):
  1. Di `app_en.arb`, setelah baris `"themeDark": "Dark"` (tanpa koma), ubah menjadi `"themeDark": "Dark",` lalu tambahkan persis (termasuk koma, kecuali entri terakhir sebelum `}`):
     ```json
     "otpLoginButton": "Login with email code",
     "otpTitle": "Check your email",
     "otpSubtitle": "Enter the 8-digit code sent to {email}",
     "@otpSubtitle": { "placeholders": { "email": { "type": "String" } } },
     "otpHint": "8-digit code",
     "otpInvalid": "Enter the 8-digit code",
     "otpVerify": "Verify",
     "otpResend": "Resend code",
     "otpResendIn": "Resend in {seconds}s",
     "@otpResendIn": { "placeholders": { "seconds": { "type": "int" } } },
     "otpResent": "A new code has been sent",
     "otpChangeEmail": "Use a different email",
     "otpEmailNotRegistered": "Email not registered. Please sign up first.",
     "otpExpired": "Code expired. Please request a new one.",
     "otpSendFailed": "Failed to send code. Try again."
     ```
  2. Di `app_id.arb`, operasi identik setelah `"themeDark": "Gelap"`:
     ```json
     "otpLoginButton": "Masuk dengan kode email",
     "otpTitle": "Cek email Anda",
     "otpSubtitle": "Masukkan kode 8 digit yang dikirim ke {email}",
     "@otpSubtitle": { "placeholders": { "email": { "type": "String" } } },
     "otpHint": "Kode 8 digit",
     "otpInvalid": "Masukkan kode 8 digit",
     "otpVerify": "Verifikasi",
     "otpResend": "Kirim ulang kode",
     "otpResendIn": "Kirim ulang dalam {seconds} dtk",
     "@otpResendIn": { "placeholders": { "seconds": { "type": "int" } } },
     "otpResent": "Kode baru telah dikirim",
     "otpChangeEmail": "Gunakan email lain",
     "otpEmailNotRegistered": "Email belum terdaftar. Silakan daftar dulu.",
     "otpExpired": "Kode kedaluwarsa. Minta kode baru.",
     "otpSendFailed": "Gagal mengirim kode. Coba lagi."
     ```
  3. Jalankan `flutter gen-l10n` sekali setelah kedua arb disimpan. Dilarang menambah key lain atau mengubah key lama.
- Behavior dipertahankan: Semua key lama tidak berubah nilai. `template-arb-file` tetap `app_en.arb`.
- Error handling: Jika `gen-l10n` gagal karena JSON koma hilang, perbaiki koma saja, jangan ubah struktur. Jika placeholder error, pastikan nama `{email}`/`{seconds}` cocok dengan `@` definition.
- Test: Tidak ada test logika di S4. Verifikasi via S9 (`flutter test` tetap hijau; widget yang belum pakai key tidak terpengaruh).
- Command verifikasi: `flutter gen-l10n` lalu `flutter analyze`.
- Hasil diharapkan: `gen-l10n` sukses, `app_localizations_en.dart`/`_id.dart` mengandung getter `otpLoginButton` dkk, `analyze` 0 issue.
- Completion criteria: 13 key baru ada di kedua arb + generated getters ada.
- Tidak boleh diubah: `l10n.yaml`, key non-OTP, file Dart manual.

### S2 — Bloc: events, `pendingOtpEmail`, handlers

- Tujuan langkah: Menambah alur kirim/verifikasi OTP dengan semantik fallback identik password (wall stay `guest`).
- Finding/requirement: R1, R2, R4, R8, F2.
- Dependency: Wajib setelah S1 (repo) dan S4 (tidak pakai l10n di bloc, tapi urutan risiko). Blokir S5, S6, S7.
- File yang harus dibaca:
  - `lib/presentation/blocs/auth/auth_bloc.dart` (full 452 baris)
  - `lib/data/repositories/auth_repository.dart` (hasil S1)
- File yang harus diubah:
  - `lib/presentation/blocs/auth/auth_bloc.dart` (satu-satunya)
- Simbol terkait:
  - `AuthOtpSendRequested(email, isGuestAuthWall)`, `AuthOtpVerifyRequested(email, token, isGuestAuthWall)`, `_AuthUserChanged`
  - `AuthBlocState(status, user, errorMessage, infoMessage, explicitSignOut, pendingOtpEmail)`
  - `_onOtpSend`, `_onOtpVerify`, `_resolveStatus`, `_repo.sendEmailOtp`, `_repo.verifyEmailOtp`, `_repo.currentUser`
- Kondisi saat ini:
  - Events baris 11-75: `AuthStarted`, `AuthSignInRequested`, `AuthSignUpRequested`, `AuthSignOutRequested`, `AuthAnonymousRequested`, `AuthUpgradeAnonymousRequested`, `AuthGoogleSignInRequested`, `_AuthUserChanged`. Tidak ada event OTP.
  - State baris 80-121: 5 field, `copyWith` dengan sentinel `_undefined`, `props` 5 elemen. Tidak ada `pendingOtpEmail`.
  - Constructor baris 128-137 mendaftarkan 7 handler. `_onSignIn`/`_onSignUp` punya pola `fallbackStatus = isWall/upgradeGuest ? guest : unauthenticated`.
- Perubahan konkret (urutan wajib):
  1. Setelah class `AuthGoogleSignInRequested` (baris 63-68) dan sebelum `_AuthUserChanged` (baris 70), sisipkan persis:
     ```dart
     class AuthOtpSendRequested extends AuthEvent {
       final String email;
       final bool isGuestAuthWall;
       const AuthOtpSendRequested(this.email, {this.isGuestAuthWall = false});
       @override
       List<Object?> get props => [email, isGuestAuthWall];
     }

     class AuthOtpVerifyRequested extends AuthEvent {
       final String email;
       final String token;
       final bool isGuestAuthWall;
       const AuthOtpVerifyRequested(this.email, this.token, {this.isGuestAuthWall = false});
       @override
       List<Object?> get props => [email, token, isGuestAuthWall];
     }
     ```
  2. Di `AuthBlocState`: tambah field `final String? pendingOtpEmail;`, tambah di constructor `this.pendingOtpEmail`, tambah param `Object? pendingOtpEmail = _undefined` di `copyWith` dan cabang `identical(pendingOtpEmail, _undefined) ? this.pendingOtpEmail : pendingOtpEmail as String?`, tambah ke `props` sebagai elemen ke-6. Jangan ubah sentinel atau field lain.
  3. Di constructor `AuthBloc`: daftarkan `on<AuthOtpSendRequested>(_onOtpSend);` dan `on<AuthOtpVerifyRequested>(_onOtpVerify);` setelah `on<AuthGoogleSignInRequested>`.
  4. Tambah dua handler setelah `_onSignUp` (baris 404) dan sebelum `_onSignOut` (baris 406), persis logika:
     ```dart
     Future<void> _onOtpSend(AuthOtpSendRequested e, Emitter<AuthBlocState> emit) async {
       final prevStatus = state.status;
       final prevUser = state.user;
       emit(state.copyWith(status: AuthStatus.submitting, errorMessage: null, infoMessage: null, explicitSignOut: false));
       try {
         await _repo.sendEmailOtp(email: e.email);
         emit(state.copyWith(status: prevStatus, user: prevUser, pendingOtpEmail: e.email, errorMessage: null, infoMessage: null));
       } on Failure catch (f) {
         final fallbackStatus = e.isGuestAuthWall ? AuthStatus.guest : AuthStatus.unauthenticated;
         emit(state.copyWith(status: fallbackStatus, user: prevUser, pendingOtpEmail: null, errorMessage: f.message));
       }
     }
     Future<void> _onOtpVerify(AuthOtpVerifyRequested e, Emitter<AuthBlocState> emit) async {
       emit(state.copyWith(status: AuthStatus.submitting, errorMessage: null, infoMessage: null, explicitSignOut: false));
       try {
         await _repo.verifyEmailOtp(email: e.email, token: e.token);
         final user = _repo.currentUser;
         final status = _resolveStatus(user);
         emit(state.copyWith(status: status, user: user, pendingOtpEmail: null, errorMessage: null, infoMessage: null));
       } on Failure catch (f) {
         final fallbackStatus = e.isGuestAuthWall ? AuthStatus.guest : AuthStatus.unauthenticated;
         // Pertahankan user sebelumnya agar wall tidak kehilangan sesi anon.
         emit(state.copyWith(status: fallbackStatus, pendingOtpEmail: e.email, errorMessage: f.message));
       }
     }
     ```
  5. DILARANG memanggil `grantRegisteredBonus()` atau `createGuestMigrationToken/migrateGuestStickers` di kedua handler (R2=false tidak ada user baru; R4=boleh hilang).
  6. DILARANG mengubah `_onUserChanged`: ia tetap menimpa `status/user` dan clear `error/info`, tapi JANGAN clear `pendingOtpEmail` di sana (biarkan handler yang mengatur; jika `_onUserChanged` menimpa, navigasi OTP bisa hilang). Jika perlu, tambahkan `pendingOtpEmail: state.pendingOtpEmail` eksplisit? Tidak — `copyWith` tanpa argumen mempertahankan nilai lama via sentinel, jadi tidak perlu diubah. Jangan sentuh.
- Behavior dipertahankan: `_resolveStatus`, `explicitSignOut` handling, guest-wall stay-`guest`, normal fail → `unauthenticated`, semua handler lama byte-identik.
- Error handling: `Failure` → `fallbackStatus` + `errorMessage=f.message` (raw, dilokalkan di UI via S3). Exception non-`Failure` di OTP JANGAN ditangkap terpisah (biarkan crash terdeteksi test; konsisten dengan `_onSignIn` yang hanya catch `Failure`). Jika repo throw `UnknownFailure`, itu subclass `Failure` sehingga tertangkap.
- Test: S7. Tidak ada test di S2.
- Command verifikasi: `flutter analyze`.
- Hasil diharapkan: 0 issue, tidak ada `missing_enum_constant`, `copyWith` tetap compile di semua call-site lama (karena param baru opsional via sentinel).
- Completion criteria: Dua event + satu field + dua handler ada, semua test lama (`auth_bloc_*`) masih compile.
- Tidak boleh diubah: `lib/app.dart`, `lib/core/auth_gate_policy.dart`, repo, l10n, test.

### S3 — Error mapping aman di `safe_error_message.dart`

- Tujuan langkah: Ubah pesan mentah OTP menjadi pesan lokal aman tanpa bocor endpoint/stack.
- Finding/requirement: R6, F3 (gap bagistruk `otp_expired` mentah).
- Dependency: Wajib setelah S4 (memakai getters l10n baru). Independen dari S2 secara compile, tapi urutan risiko setelah S2.
- File yang harus dibaca:
  - `lib/core/errors/safe_error_message.dart` (72 baris)
  - `test/safe_error_message_test.dart` (70 baris, pola grup test)
- File yang harus diubah:
  - `lib/core/errors/safe_error_message.dart`
- Simbol terkait: `safeErrorMessage(AppLocalizations l10n, String? raw, {String? fallback})`, `_containsAny`, getters `otpEmailNotRegistered`, `otpExpired`, `otpInvalid`, `tooManyRequests`, `connectionError`, `errorOccurred`.
- Kondisi saat ini: Fungsi hanya punya 3 cabang: kosong → fallback/generic, network → `connectionError`, internal → `errorOccurred`, else passthrough `text`. Tidak ada cabang OTP.
- Perubahan konkret (urutan wajib, sisipkan SETELAH blok network baris 24-45 dan SEBELUM blok internal baris 49-62):
  ```dart
  // OTP email login (Supabase Auth, shouldCreateUser=false).
  // Catatan: supabase_flutter sering hilangkan error.code, jadi deteksi via message.
  if (lower.contains('signups not allowed for otp') || lower.contains('otp_disabled')) {
    return l10n.otpEmailNotRegistered;
  }
  if (lower.contains('otp_expired') || lower.contains('token expired') || lower.contains('code expired')) {
    return l10n.otpExpired;
  }
  if (lower.contains('over_email_send_rate_limit') || lower.contains('over_request_rate_limit') || lower.contains('email rate limit')) {
    return l10n.tooManyRequests;
  }
  if (lower.contains('invalid otp') || lower.contains('otp_invalid') || lower.contains('token not found') || lower.contains('invalid token')) {
    return l10n.otpInvalid;
  }
  ```
  Jangan pindahkan blok network/internal. Jangan tambah import baru.
- Behavior dipertahankan: Pesan network/internal lama tetap prioritas/mapping sama. Pesan curated lain tetap passthrough. Input null/kosong tetap fallback.
- Edge case: Pesan campuran misal `"AuthException: otp_expired, token not found"` → kena cabang expired dulu (urutan di atas menentukan). Ini disengaja: expired lebih actionable (minta kode baru) daripada invalid.
- Test: S7 (tambah 4 grup kecil). Tidak ubah test lama.
- Command verifikasi: `flutter analyze`, lalu `flutter test test/safe_error_message_test.dart`.
- Hasil diharapkan: analyze bersih, test lama tetap hijau (belum ada test OTP, jadi tidak ada regresi).
- Completion criteria: 4 cabang baru ada dengan urutan persis di atas, semua pesan OTP mentah tidak lagi passthrough mentah.
- Tidak boleh diubah: `test/*` di langkah ini, `*_arb`, bloc, repo.

### S5 — Tombol OTP di `AuthScreen`

- Tujuan langkah: Beri entry-point kirim OTP tanpa ganggu form password/Google/guest.
- Finding/requirement: R1, R4, R8.
- Dependency: Wajib setelah S2 (event) dan S4 (label). Blokir S6 secara navigasi (S5 push ke S6).
- File yang harus dibaca:
  - `lib/presentation/screens/auth/auth_screen.dart` (449 baris)
  - `lib/presentation/blocs/auth/auth_bloc.dart` (hasil S2, untuk nama event/state)
- File yang harus diubah:
  - `lib/presentation/screens/auth/auth_screen.dart`
- Simbol terkait: `_AuthScreenState._submit`, `_googleSignIn`, `AuthOtpSendRequested`, `AuthBlocState(status, pendingOtpEmail, errorMessage)`, `AppLocalizations.otpLoginButton`, `safeErrorMessage`, `OtpVerifyScreen` (dari S6, import di langkah ini tapi file dibuat di S6 — urutan file: buat S6 dulu ATAU tambah import di S5 setelah S6; untuk determinisme: tulis S6 dulu, lalu kembali tambah import+push di S5. Jika eksekutor satu-pass, buat placeholder import di S5 dan pastikan S6 nama class persis `OtpVerifyScreen`).
- Kondisi saat ini:
  - State lokal: `_emailCtrl`, `_passCtrl`, `_formKey`, `_tab`, `_isGuestWall`, `_isSignUp`. Tidak ada `_otpLoading` atau controller OTP.
  - `build` baris 140-141: `submitting = status==submitting`. `BlocConsumer` listener baris 89-139: pop wall jika `authenticated`, snackbar error via `safeErrorMessage`, info via raw.
  - Tombol utama `FilledButton.icon` baris 285-301, divider `or` baris 303-319, Google `OutlinedButton` baris 321-329.
- Perubahan konkret (urutan):
  1. Tambah method setelah `_googleSignIn()` (baris 70-74):
     ```dart
     void _sendOtp() {
       final email = _emailCtrl.text.trim();
       if (!email.contains('@')) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             backgroundColor: context.colors.error,
             content: Text(AppLocalizations.of(context)!.emailInvalid),
           ),
         );
         return;
       }
       context.read<AuthBloc>().add(
         AuthOtpSendRequested(email, isGuestAuthWall: _isGuestWall),
       );
     }
     ```
     Validasi sengaja `contains('@')` saja agar identik dengan validator form baris 215-218. Dilarang pakai regex baru.
  2. Di `builder`, setelah `FilledButton` (baris 301) dan sebelum `SizedBox(height:16)` + divider, sisipkan:
     ```dart
     const SizedBox(height: 12),
     OutlinedButton.icon(
       onPressed: submitting ? null : _sendOtp,
       icon: const Icon(Icons.mark_email_unread_outlined),
       label: Text(l10n.otpLoginButton),
     ),
     ```
     Jangan pindahkan Google/guest button. `submitting` reuse variabel existing (tidak ada state loading terpisah).
  3. Di `listener`, setelah cabang `authenticated` (baris 96-101) dan sebelum `errorMessage` (baris 102), sisipkan navigasi:
     ```dart
     if (state.pendingOtpEmail != null && state.errorMessage == null && state.status != AuthStatus.submitting) {
       final email = state.pendingOtpEmail!;
       // Cegah push ganda saat rebuild: clear via verify atau kirim ulang yang mengatur ulang.
       Navigator.of(context).push(
         MaterialPageRoute(
           builder: (_) => OtpVerifyScreen(email: email, isGuestAuthWall: _isGuestWall),
         ),
       );
       // Jangan clear pendingOtpEmail di sini (bloc own state); push sekali per perubahan email.
       // Guard double-push: listener hanya fire saat pendingOtpEmail berubah (lihat listenWhen di bawah).
     }
     ```
  4. Ubah `listenWhen` baris 85-88 dari `p.status != n.status || p.errorMessage != ... || p.infoMessage != ...` menjadi tambah `|| p.pendingOtpEmail != n.pendingOtpEmail`. Ini mencegah push ganda.
  5. Tambah import `otp_verify_screen.dart` di atas (setelah `auth_bloc.dart` import).
- Behavior dipertahankan: Tab normal/guest-wall, `_submit`, Google, guest entry, snackbar error/info, pop wall hanya saat `authenticated`, guest-wall gagal tetap `guest` (dari S2). Validasi password tidak berubah. Tidak ada auto-submit OTP dari layar ini.
- Error handling: Email invalid lokal → snackbar `emailInvalid`, tidak dispatch event. `sendEmailOtp` gagal (misal email baru) → bloc emit error, listener tampilkan snackbar via `safeErrorMessage` (S3) dan TIDAK push (karena `errorMessage != null` guard + `pendingOtpEmail==null` dari S2).
- Test: Widget test manual di S9; test otomatis bloc di S7. Tidak tambah widget test wajib di S5 (agar atomik).
- Command verifikasi: `flutter analyze`.
- Hasil diharapkan: 0 issue, tidak ada `unused_import` (pastikan S6 sudah ada sebelum analyze final).
- Completion criteria: Tombol muncul di kedua mode (`normal`, `guestAuthWall`), disabled saat `submitting`, email invalid tidak dispatch, email valid dispatch event benar, push hanya saat `pendingOtpEmail` baru dan tanpa error.
- Tidak boleh diubah: `auth_bloc.dart`, `app.dart`, `auth_gate_policy.dart`, validator password, Google flow, `supabase/*`.

### S6 — Layar baru `OtpVerifyScreen`

- Tujuan langkah: Verifikasi kode 8-digit + resend 60s, pola copy `bagistruk/verify_otp_screen.dart` tapi versi BLoC.
- Finding/requirement: R3, R5, R6, R7.
- Dependency: Wajib setelah S2 (events), S4 (strings), S3 (error mapping dipakai di snackbar). S5 bergantung pada nama class ini.
- File yang harus dibaca:
  - `C:\Works\github.com\alamaby\bagistruk\lib\presentation\auth\screens\verify_otp_screen.dart` baris 1-150 (pola timer/guards) — referensi saja, jangan copy Riverpod/go_router.
  - `lib/presentation/screens/auth/auth_screen.dart` (hasil S5, untuk gaya snackbar `context.colors.error/tertiary`)
- File yang harus diubah (dibuat):
  - `lib/presentation/screens/auth/otp_verify_screen.dart` (BARU, satu-satunya file di langkah ini)
- Simbol terkait: `class OtpVerifyScreen(email, isGuestAuthWall)`, `_OtpVerifyScreenState`, `_otpLength=8`, `_formKey`, `_otp TextEditingController`, `_timer Timer?`, `_verifying/_resending bool`, `_cooldown int`, `AuthOtpVerifyRequested`, `AuthOtpSendRequested`, `AuthBloc`, `AuthStatus`, `safeErrorMessage`.
- Kondisi saat ini: File belum ada. Direktori `lib/presentation/screens/auth/` hanya berisi `auth_screen.dart`.
- Perubahan konkret (tulis file baru persis struktur, urutan):
  1. Header imports: `dart:async`, `flutter/material`, `flutter/services`, `flutter_bloc`, `core/errors/safe_error_message`, `core/theme/app_theme`, `l10n/app_localizations`, `../blocs/auth/auth_bloc` (sesuaikan path relatif: dari `screens/auth/` ke `blocs/auth/auth_bloc.dart` = `../../blocs/auth/auth_bloc.dart`; ke `core/*` = `../../../core/*`; ke `l10n` = `../../../l10n/app_localizations.dart` — samakan dengan `auth_screen.dart` baris 4-8).
  2. Widget: `class OtpVerifyScreen extends StatefulWidget { final String email; final bool isGuestAuthWall; const OtpVerifyScreen({super.key, required this.email, this.isGuestAuthWall=false}); }`
  3. State fields persis: `static const int _otpLength = 8; final _formKey=GlobalKey<FormState>(); final _otp=TextEditingController(); Timer? _timer; bool _verifying=false; bool _resending=false; int _cooldown=60; bool get _busy => _verifying||_resending;`
  4. `initState`: `_startCooldown(rebuild:false);` `dispose`: `_timer?.cancel(); _otp.dispose(); super.dispose();`
  5. `_startCooldown({bool rebuild=true})`: copy logika bagistruk (cancel timer, set 60, `Timer.periodic(1s)` decrement, `if (!mounted) return`, saat `<=1` cancel + set 0).
  6. `_verify()`: guard `if (_busy) return;` + `validate`; `setState(_verifying=true)`; `context.read<AuthBloc>().add(AuthOtpVerifyRequested(widget.email, _otp.text.trim(), isGuestAuthWall: widget.isGuestAuthWall));` — JANGAN await repo langsung. Reset `_verifying=false` di listener? Karena bloc async, kelola via `BlocConsumer`: `listener` jika `authenticated` → `Navigator.popUntil`? Spesifikasi deterministik: jika `state.status==authenticated` dan `_isGuestWall` → `Navigator.of(context)..pop()..pop()` (tutup OTP + wall)? Tidak — wall sudah di bawah OTP. Aturan: di OTP screen, jika `authenticated` → `Navigator.of(context).popUntil((r)=>r.isFirst)` TIDAK boleh (merusak MainShell). Aturan benar: `if (state.status==AuthStatus.authenticated && mounted) Navigator.of(context).pop();` (tutup OTP saja; wall di bawahnya juga akan pop sendiri via `AuthScreen` listener yang melihat `authenticated`). Jika bukan wall (normal login), `pop` kembali ke `AuthScreen` yang juga akan rebuild ke home via `_AuthGate`. Dokumentasikan ini sebagai behavior.
  7. `_resend()`: guard `if (_busy||_cooldown>0) return;` `setState(_resending=true)` dispatch `AuthOtpSendRequested(widget.email, isGuestAuthWall: widget.isGuestAuthWall)`; reset `_resending` via listener (atau `Future.delayed`? Pilih listener: saat `pendingOtpEmail==email && error==null` → `_startCooldown()` + snackbar `otpResent`; saat error → `_showError`). Untuk determinisme tanpa async repo di UI: `_resending` di-set false di `BlocConsumer.listener` (bukan langsung setelah dispatch).
  8. `_validateOtp`: `if (code.length != 8) return l10n.otpInvalid; return null;`
  9. UI `build`: `Scaffold(appBar: AppBar(), body: SafeArea(child: BlocConsumer<AuthBloc,AuthBlocState>(listenWhen: status/error/pending berubah, listener: seperti di atas + _showError via safeErrorMessage, builder: Form(key:_formKey, child: Column[ Text(otpTitle), Text(otpSubtitle(email)), TextFormField(controller:_otp, keyboardType:number, inputFormatters:[FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)], autofocus:true, style: fontSize 24 letterSpacing 4, decoration: hintText 8x'0'? gunakan l10n.otpHint), SizedBox, FilledButton(verify, disabled saat _busy atau bloc submitting), TextButton(resend, label cooldown>0 ? otpResendIn(seconds) : otpResend, disabled saat _busy||cooldown>0), TextButton(otpChangeEmail → Navigator.pop)]))))`
  10. `_showError`: copy gaya `AuthScreen` (background `context.colors.error`, icon `error_outline`, text via `safeErrorMessage(l10n, raw)`).
- Behavior dipertahankan: Tidak ubah `AuthScreen`, bloc, repo. Keyboard numeric, paste didukung default `TextFormField`. Autofocus true.
- Error handling: `_busy` guard ganda (lokal + bloc `submitting` disable tombol). Cooldown block resend. `otp_expired` → snackbar `otpExpired` via S3 + user tekan resend. Email baru tidak akan sampai sini (gagal di S5).
- Test: S7 (bloc saja). Widget test OTP tidak wajib (agar atomik), verifikasi manual di S9.
- Command verifikasi: `flutter analyze`.
- Hasil diharapkan: 0 issue, tidak ada `unused_element`, import path benar.
- Completion criteria: File ada, compile, field 8-digit hanya digit, verify dispatch event benar, resend terblok saat cooldown, error tampil via safe message, sukses pop.
- Tidak boleh diubah: File lain apapun di langkah ini. Dilarang tambah package `pinput`/`pin_code_fields`.

### S7 — Test baru + update test lama

- Tujuan langkah: Buktikan setiap requirement punya verifikasi otomatis tanpa analisis ulang.
- Finding/requirement: Semua R1-R8, F2.
- Dependency: Wajib setelah S1-S4 (S2 untuk bloc, S3 untuk error, S1 untuk mock). Independen dari S5/S6 secara compile (mock repo, bukan widget).
- File yang harus dibaca:
  - `test/auth_bloc_guest_wall_test.dart` (pola `MockAuthRepository`, `blocTest`, `when(...).thenThrow`)
  - `test/auth_bloc_signout_test.dart` (pola seed)
  - `test/safe_error_message_test.dart` (pola grup)
  - `lib/presentation/blocs/auth/auth_bloc.dart` (hasil S2, untuk ekspektasi state)
- File yang harus diubah (dibuat/diubah):
  - BARU `test/auth_bloc_otp_test.dart`
  - UBAH `test/safe_error_message_test.dart` (tambah grup, jangan ubah grup lama)
- Simbol terkait: `MockAuthRepository`, `MockUser`, `AuthBloc`, `AuthOtpSendRequested`, `AuthOtpVerifyRequested`, `AuthStatus`, `AuthFailure`, `blocTest`, `when`, `safeErrorMessage`.
- Kondisi saat ini: 28 file test, tidak ada file OTP. `safe_error_message_test` 4 grup (network, internal, curated, empty).
- Perubahan konkret (urutan):
  1. Buat `test/auth_bloc_otp_test.dart` persis kerangka:
     ```dart
     import 'package:bikin_stiker/core/errors/failures.dart';
     import 'package:bikin_stiker/data/repositories/auth_repository.dart';
     import 'package:bikin_stiker/presentation/blocs/auth/auth_bloc.dart';
     import 'package:bloc_test/bloc_test.dart';
     import 'package:flutter_test/flutter_test.dart';
     import 'package:mocktail/mocktail.dart';
     import 'package:supabase_flutter/supabase_flutter.dart';
     class MockAuthRepository extends Mock implements AuthRepository {}
     class MockUser extends Mock implements User {}
     void main() {
       late MockAuthRepository repo; late MockUser guestUser; late MockUser nonAnonUser;
       setUp(() {
         repo = MockAuthRepository();
         guestUser = MockUser(); when(()=>guestUser.id).thenReturn('guest-1'); when(()=>guestUser.isAnonymous).thenReturn(true);
         nonAnonUser = MockUser(); when(()=>nonAnonUser.id).thenReturn('user-1'); when(()=>nonAnonUser.isAnonymous).thenReturn(false);
         when(()=>repo.currentUser).thenReturn(null);
       });
       // T1..T6 di bawah
     }
     ```
  2. T1 kirim sukses normal (R1): seed `unauthenticated`, stub `when(()=>repo.sendEmailOtp(email:any(named:'email'))).thenAnswer((_)async{})`, act `AuthOtpSendRequested('a@mail.com')`, expect `[submitting, unauthenticated+pendingOtpEmail='a@mail.com']`. Verifikasi `verify(()=>repo.sendEmailOtp(email:'a@mail.com')).called(1)`.
  3. T2 kirim email baru ditolak (R2): stub `thenThrow(AuthFailure('Signups not allowed for otp'))`, seed `unauthenticated`, expect `[submitting, unauthenticated+errorMessage='Signups not allowed for otp'+pendingOtpEmail=null]`.
  4. T3 kirim gagal wall stay guest (R4,F2): seed `guest+guestUser`, act `AuthOtpSendRequested('x@mail.com', isGuestAuthWall:true)` dengan stub throw `AuthFailure('Signups not allowed for otp')`, expect `[submitting+guestUser, guest+guestUser+error]`. Ini regresi bounce legal.
  5. T4 verify sukses (R1): stub `verifyEmailOtp` success + `when(()=>repo.currentUser).thenReturn(nonAnonUser)`, seed `unauthenticated`, act `AuthOtpVerifyRequested('a@mail.com','12345678')`, expect `[submitting, authenticated+user=nonAnonUser+pendingOtpEmail=null]`.
  6. T5 verify expired (R6): stub `thenThrow(AuthFailure('otp_expired'))`, seed `unauthenticated`, act verify, expect `[submitting, unauthenticated+error='otp_expired'+pendingOtpEmail='a@mail.com']` (pending dipertahankan agar user bisa resend tanpa ketik email ulang).
  7. T6 verify gagal wall stay guest (R4): seed guest, stub throw `Invalid login`, act `isGuestAuthWall:true`, expect stay `guest`.
  8. Di `test/safe_error_message_test.dart`, TAMBAH grup baru di akhir (jangan ubah grup lama):
     ```dart
     group('otp mappings', () {
       test('otp_disabled maps to otpEmailNotRegistered', () {
         expect(safeErrorMessage(l10n, 'Signups not allowed for otp'), l10n.otpEmailNotRegistered);
       });
       test('otp_expired maps to otpExpired', () {
         expect(safeErrorMessage(l10n, 'otp_expired'), l10n.otpExpired);
       });
       test('rate limit maps to tooManyRequests', () {
         expect(safeErrorMessage(l10n, 'over_email_send_rate_limit'), l10n.tooManyRequests);
       });
       test('invalid otp maps to otpInvalid', () {
         expect(safeErrorMessage(l10n, 'Token not found'), l10n.otpInvalid);
       });
     });
     ```
- Input/expected: Tercantum per T1-T6 + 4 mapping di atas. `pendingOtpEmail` adalah pembeda utama dari test password lama.
- Command verifikasi: `flutter test test/auth_bloc_otp_test.dart test/safe_error_message_test.dart`
- Hasil diharapkan: Semua test baru hijau (10 passed: 6 bloc + 4 mapping) + test lama tidak merah.
- Completion criteria: File baru ada, 6 blocTest + 4 mapping hijau, tidak ada test lama diubah.
- Tidak boleh diubah: Test lama selain tambah grup, kode `lib/*` di langkah ini.

### S8 — Konfigurasi Dashboard Supabase manual (tanpa kode)

- Tujuan langkah: Samakan server dengan app 8-digit + pastikan email terkirim.
- Finding/requirement: R3, R9, F3.
- Dependency: Independen kode, tapi verifikasi manual (S9) blokir sampai S8 selesai. Risiko TERTINGGI jika lupa (semua OTP gagal).
- File yang harus dibaca: `supabase/config.toml` baris 22-32 (site_url + additional_redirect_urls), `C:\Works\github.com\alamaby\bagistruk\supabase\templates\README.md` (tabel template + `{{ .Token }}`).
- File yang harus diubah: TIDAK ADA file repo. Semua via Dashboard. Dilarang buat migrasi/edge function.
- Checklist deterministik (centang satu per satu):
  1. Authentication → Providers → Email ON, Allow new signup ON (tetap ON untuk password; OTP baru tetap diblokir oleh `shouldCreateUser=false` di client).
  2. Authentication → Settings → OTP length = `8`, expiry sesuai kebutuhan (default 1 jam; catat nilai yang dipilih).
  3. Authentication → Email Templates: buka `Confirm signup` dan `Magic Link`, pastikan KEDUANYA mengandung `{{ .Token }}` dan `{{ .ConfirmationURL }}`. Jika salah satu hilang `{{ .Token }}`, kode 8-digit tidak digenerate (kegagalan total S6).
  4. Authentication → URL Configuration: pastikan `Redirect URLs` mengandung `io.supabase.bikinstiker://login-callback` (sudah ada di `config.toml:25`; samakan dengan Dashboard).
  5. Auth → SMTP: set custom SMTP Resend (`smtp.resend.com`, `465 SSL` atau `587 STARTTLS`, user `resend`, pass Resend API key, sender domain terverifikasi). Jangan kirim email auth dari kode app.
  6. Catat nilai OTP length/expiry/SMTP di Progress Log plan (bukti manual).
- Behavior dipertahankan: `enable_signup=true`, `enable_confirmations=false` tidak diubah via kode.
- Edge case: Jika instance disable signup, `true` pun gagal — tapi kita `false`, jadi email baru SELALU gagal by design. Bedakan error ini dari misconfig (jika email LAMA juga `otp_disabled`, berarti Dashboard salah, bukan R2).
- Test/verifikasi: Kirim OTP ke email lama (harus terima kode 8-digit) + ke email baru (harus error `Signups not allowed`, tanpa email). Lihat S9.
- Command verifikasi: Tidak ada CLI; verifikasi via UI Dashboard + smoke manual.
- Completion criteria: 5 checklist di atas bertanda done + smoke dua kasus lolos.
- Tidak boleh diubah: File repo apapun di langkah ini.

### S9 — Verifikasi akhir

- Tujuan langkah: Bukti tidak ada regresi dan semua finding tertutup.
- Dependency: Wajib setelah S1-S8 semua.
- File yang harus dibaca: Tidak ada (hanya jalankan).
- File yang harus diubah: Tidak ada.
- Command verifikasi (urutan wajib, dari repo root):
  1. `flutter pub get`
  2. `flutter gen-l10n` (pastikan tidak ada diff tak terduga selain OTP)
  3. `flutter analyze` → diharapkan `No issues found`.
  4. `flutter test test/auth_bloc_otp_test.dart test/safe_error_message_test.dart test/auth_bloc_guest_wall_test.dart test/auth_bloc_signout_test.dart` → diharapkan `All tests passed`.
  5. `flutter test` (full) → diharapkan semua hijau (baseline 2026-09-20: 208 test; setelah S7 harus ≥218).
  6. Smoke manual: (a) email lama kirim → terima 8 digit → verify sukses → `authenticated`; (b) email baru kirim → snackbar `otpEmailNotRegistered`, tidak ada layar OTP; (c) guest wall OTP sukses → stiker guest hilang (by design R4) + tidak bounce ke legal-consent.
- Completion criteria: `analyze` 0, test target hijau, full test hijau, smoke 3 kasus lolos, Progress Log plan diisi.
- Tidak boleh diubah: Kode apapun di langkah ini. Jika merah, kembali ke langkah terkait, jangan hotfix di S9.

## Risks

- Dashboard lupa set OTP=8 → semua kode gagal validasi. Mitigasi: S8 checklist + smoke.
- Template hilang `{{ .Token }}` → hanya link terkirim, layar OTP rusak total. Mitigasi: S8 poin 3.
- Enumerasi email via sukses/gagal OTP (trade-off `false` yang dipilih user). Mitigasi: pesan sudah jelas `Email belum terdaftar`, cooldown 60s + rate-limit; diterima sebagai keputusan.
- Bug GoTrue alias `+` dilaporkan tetap buat user meski `false`. Mitigasi: jangan andalkan `false` sebagai satu-satunya guard untuk data sensitif.
- Double-push `OtpVerifyScreen` saat rebuild. Mitigasi: `listenWhen pendingOtpEmail` (S5) + guard `error==null && status!=submitting`.
- `pendingOtpEmail` tertimpa `_onUserChanged`. Mitigasi: tidak clear di sana (S2 poin 6).

## Progress Log

- 2026-09-22 12:00:00 — Implementation plan ditulis (S1-S9). Belum ada kode diubah. Menunggu eksekusi bertahap S1→S9.
- 2026-09-22 12:30:00 — S1–S7 selesai. `flutter analyze` 0 issue. Test: 218 passed (baseline 208 + 10 baru: 6 bloc + 4 mapping). S8 (Dashboard: OTP length=8, template `{{ .Token }}`, SMTP Resend) masih menunggu owner.

## Notes

- Skala fitur kecil → tanpa seremonial TOGAF/ODA penuh; hanya Supabase Auth native + pola `bagistruk`.
- Satu file = satu plan. Jangan overwrite plan lain di `plans/`. Jangan commit selain file plan ini sampai eksekusi selesai.
- Env guard: dilarang print/cat `.env*`, `sb_secret_*`, `sb_publishable_*`, `SUPABASE_*`, `CRON_SECRET` ke chat/log. Token hanya via `process.env` / `.env.local` yang gitignored.

---

## Handoff Checklist (untuk model kecil)

- [ ] Baca S1 lalu ubah HANYA `lib/data/repositories/auth_repository.dart` persis snippet. `analyze` file.
- [ ] Baca S4 lalu ubah HANYA dua `.arb` + `flutter gen-l10n`. Jangan sentuh Dart manual.
- [ ] Baca S2 lalu ubah HANYA `lib/presentation/blocs/auth/auth_bloc.dart` urutan 1-6. Jangan panggil bonus/migrasi.
- [ ] Baca S3 lalu ubah HANYA `lib/core/errors/safe_error_message.dart` sisipan persis. Jangan ubah blok lain.
- [ ] Buat S6 `otp_verify_screen.dart` BARU persis spec (nama class `OtpVerifyScreen` wajib sama untuk S5).
- [ ] Baca S5 lalu ubah HANYA `lib/presentation/screens/auth/auth_screen.dart` 5 sub-langkah + import S6.
- [ ] Buat S7 `test/auth_bloc_otp_test.dart` + tambah grup di `safe_error_message_test.dart`. Jalankan test target.
- [ ] Minta owner selesaikan S8 checklist Dashboard (tidak ada kode). Catat nilai di Progress Log.
- [ ] Jalankan S9 urutan 1-6. Stop jika merah, kembali ke langkah terkait. Jangan refactor di luar spec.
- [ ] Dilarang: migrasi DB, edge function, `android/`, `ios/`, `lib/app.dart`, `auth_gate_policy.dart`, package OTP baru, regex email baru, staging/commit selain file plan.
- [ ] Blocker terbuka: nilai expiry OTP Dashboard (pilih default 1 jam jika owner tidak tentukan), kredensial SMTP Resend (owner sediakan), template HTML final (copy dari `bagistruk` lalu ganti brand ke BikinStiker).
