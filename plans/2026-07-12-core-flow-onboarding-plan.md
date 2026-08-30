# Onboarding Core Flow

Created: 2026-07-12

## Objective

Tambah onboarding 3 langkah untuk core flow: generate sticker, add sticker to pack, export pack to WhatsApp. Tampil satu kali per perangkat usai sesi user siap. Bisa replay dari Profile tanpa mengubah status completed.

## Scope

- Onboarding `PageView` 3 halaman.
- Persist completion via `SharedPreferences`.
- Gate di `app.dart` setelah legal consent + session guest/auth.
- Entry replay di layar Profile.
- Contextual guidance tipis setelah aksi nyata (home, add-to-pack, pack detail).

## Technical Design

### Persistence

`OnboardingRepository` wrap `SharedPreferences` key `onboarding.core_flow.completed.v1`.
Repo lokal saja -- preferensi perangkat, bukan data bisnis lintas perangkat.

### App Gate Order

Legal consent -> auth/guest session ready -> onboarding belum selesai -> OnboardingScreen -> HomeScreen.

### Replay

Profile -> How It Works -> OnboardingScreen(mode replay) -> kembali Profile. Completion state tidak diubah.

### Contextual Guidance

- Home: inline "Next: add this sticker to a pack." usai generate sukses.
- AddToPackSheet: snackbar dinamis (pack N sticker / ready).
- PackDetail: inline callout saat pack punya >= 3 sticker.

## Tasks

- [x] Buat plans/2026-07-12-core-flow-onboarding-plan.md
- [x] Buat `OnboardingRepository` dengan key `onboarding.core_flow.completed.v1`.
- [x] Register repository di `lib/core/di.dart`.
- [x] Buat `OnboardingScreen` dengan tiga step, Skip, Back, Next, dan CTA akhir.
- [x] Tambah gate onboarding ke `lib/app.dart`.
- [x] Tambah `How It Works` ke Profile dan navigation replay.
- [x] Tambah inline guidance setelah generation pertama di home_screen.dart.
- [x] Perbaiki feedback Add to Pack berdasarkan jumlah sticker.
- [x] Tambah pack-ready callout saat jumlah sticker mencapai minimum export.
- [x] Tambah unit test repository persistence.
- [x] Tambah widget test untuk step navigation, Skip, completion, dan replay.
- [x] Bump versi feature `0.15.5+58` menjadi `0.16.0+59`.
- [x] Update `PROJECT_MEMORY.md`.
- [x] Jalankan full Flutter verification.

## Files

### New
- `lib/data/repositories/onboarding_repository.dart`
- `lib/presentation/screens/onboarding/onboarding_screen.dart`
- `test/onboarding_repository_test.dart`
- `test/onboarding_screen_test.dart`

### Update
- `lib/core/di.dart`
- `lib/app.dart`
- `lib/presentation/screens/profile/profile_screen.dart`
- `lib/presentation/screens/home/home_screen.dart`
- `lib/presentation/widgets/add_to_pack_sheet.dart`
- `lib/presentation/screens/packs/pack_detail_screen.dart`
- `pubspec.yaml`
- `PROJECT_MEMORY.md`

## Risks

- Onboarding sebelum Home menghalangi user ingin cepat generate -> Skip 1 tap.
- SharedPreferences tidak sinkron antar perangkat -> upgrade profile DB hanya jika diperlukan.
- User skip lalu lupa flow -> Replay Profile + contextual guidance.

## Progress Log

- 2026-07-12 15:12:00 -- Plan file created.
- 2026-07-12 16:30:00 -- Semua task selesai. `flutter analyze` 0 error (pre-existing only), `flutter test` 132/132 lulus.
