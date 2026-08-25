# Surprise Me Gap Fixes Plan

Created: 2026-08-25 10:30:00

## Objective
Memperbaiki 3 gap pada fitur "Surprise me" yang ditemukan saat audit implementasi:
1. Label hardcoded `'Surprise me'` tidak memakai key l10n `surpriseMe` yang sudah ada.
2. Random tanpa anti-repeat — saran sama bisa muncul berturut-turut.
3. Fallback `suggestionsForPreset()` mengembalikan SEMUA saran untuk preset tanpa tag match — prompt tidak sesuai gaya preset terpilih.

## Scope
- `lib/presentation/widgets/surprise_me_button.dart`
- `lib/core/constants/prompt_suggestions.dart`
- `lib/presentation/screens/home/home_screen.dart` (passing `avoid`)
- `lib/presentation/widgets/prompt_suggestion_chip.dart` (bonus: prefix "Try:" i18n)
- `lib/l10n/app_en.arb`, `lib/l10n/app_id.arb` (key baru untuk bonus)
- `test/prompt_suggestions_test.dart`, test kontrak cakupan tag baru
- `pubspec.yaml` (version bump)

## Temuan Audit (dasar plan)
- Preset aktif di produksi (query `sticker_presets`): 22 preset gambar + 9 preset tipografi.
- **Cakupan tipografi: 100%** (semua preset punya ≥6 saran match).
- **Cakupan gambar: 7 preset TANPA satu pun saran match** → fallback ke seluruh 30 prompt:
  `caricature`, `chibi_3d`, `lego_voxel`, `minimal_line`, `pixel_art`, `retro_sticker`, `vector_flat`.
- Cakupan tipis: `origami` (1 saran), `stained_glass` (2 saran).
- Key l10n `surpriseMe` sudah ada di ARB + generated code, hanya belum dipakai widget.

## Milestones
1. Phase 1 — Perbaikan kode (Gap 1 & 2)
2. Phase 2 — Konten & kontrak cakupan tag (Gap 3)
3. Phase 3 — Verifikasi penuh

## Tasks

### Phase 1 — Perbaikan Kode
- [x] **T1 (Gap 1)** `SurpriseMeButton`: ganti label hardcoded dengan
      `AppLocalizations.of(context)?.surpriseMe ?? 'Surprise me'`.
- [x] **T2 (Gap 2)** `randomSuggestionFor()`: tambah param opsional `String? avoid`
      dan `Random? rng`. Jika pool > 1 dan mengandung `avoid`, exclude `avoid`
      dari pool sebelum random. Backward-compatible (param opsional).
      - `rng` injectable agar test deterministik (seeded `Random(42)`).
- [x] **T3 (Gap 2)** Wiring caller:
      - `home_screen.dart`: pass `avoid: _promptCtrl.text.isEmpty ? null : _promptCtrl.text`
        ke `SurpriseMeButton` (tambah prop `avoid` di widget).
      - `prompt_suggestion_chip.dart`: pass `avoid: _current` di `_shuffle()`.

### Phase 2 — Konten & Kontrak (Gap 3)
- [x] **T4 (Gap 3)** Tambah `presetTags` untuk 7 preset tanpa coverage dengan
      memetakan saran existing yang relevan secara gaya (tanpa menulis konten
      baru massal), minimal target 3+ saran per preset:
      - `caricature` ← chibi robot, giggling avocado, cat surfing pizza wave
      - `chibi_3d` ← chibi robot, pastel bunny, tiny astronaut
      - `lego_voxel` ← tiny astronaut, cardboard robot, pirate ship in bottle
      - `minimal_line` ← hamster backpack, black cat, ninja cat
      - `pixel_art` ← vintage radio, wizard spell, ninja cat
      - `retro_sticker` ← vintage radio, soda bottle, polaroid, muscle car
      - `vector_flat` ← happy cloud, cheerful mushroom, happy snail
- [x] **T5 (Gap 3)** Perkuat cakupan tipis + temuan audit tambahan:
      - `origami` += sleepy panda, baby fox, black cat (→ total 4)
      - `stained_glass` += tiny dragon, baby fox, wizard spell (→ total 5)
      - **Temuan audit lanjutan**: `watercolor` (plus) juga tanpa tag — ditutup
        via happy cloud, axolotl teacup, baby fox (→ total 3)
      - `neon_cyber` dinaikkan ke 3 via tiny astronaut
- [x] **T6 (Gap 3)** Test kontrak: hardcoded daftar 31 preset ID aktif
      (21 image + 10 text) di `test/prompt_suggestions_test.dart`; assert
      setiap ID punya ≥3 match di pool masing-masing. Fallback tetap
      dipertahankan sebagai safety net untuk preset DB baru (didokumentasikan
      via docstring `suggestionsForPreset`).
- [x] **T7 (Bonus)** i18n prefix `'Try: "$_current"'` di `PromptSuggestionChip`:
      key baru `trySuggestion` (placeholder `{suggestion}`; EN "Try:", ID
      "Coba:") di kedua ARB + `flutter gen-l10n`.

### Phase 3 — Verifikasi & Housekeeping
- [x] **T8** Bump versi `pubspec.yaml`: `0.19.0+68` → `0.19.1+69`
      (klasifikasi bugfix/polish fitur existing → patch bump).
- [x] **T9** Verifikasi: `flutter pub get` ✓, `flutter analyze` 0 issues ✓,
      `flutter test` 138/138 (+5 test baru) ✓, `flutter build apk
      --split-per-abi` sukses 3 APK ✓.

## Risks
- Pemetaan tag bersifat subjektif (penilaian gaya visual). Mitigasi: hanya
  menambah tag pada saran yang jelas cocok; server-side reasoning enhancement
  (`enhancePrompt`) tetap mengadaptasi prompt ke style_descriptor preset,
  sehingga mismatch residu tidak fatal.
- Test kontrak pakai hardcoded preset ID — jika admin menambah preset baru di
  DB tanpa update test, coverage preset baru tidak tertangkap otomatis.
  Mitigasi: fallback behavior dipertahankan sehingga UX tetap aman; test
  adalah regression net, bukan validator runtime.
- Regen gen-l10n (T7) bisa menyentuh file generated lain jika ada key ARB
  yang belum sinkron. Mitigasi: review diff generated files.

## Progress Log
- 2026-08-25 10:30:00 — Plan dibuat berdasarkan audit implementasi + query
  `sticker_presets` produksi. Implementasi belum dimulai.
- 2026-08-25 11:15:00 — Implementasi selesai semua task (T1–T9). Temuan
  tambahan saat implementasi: `watercolor` juga tanpa coverage (terlewat di
  audit awal) — ikut ditutup. Verifikasi penuh lulus: analyze 0 issues,
  test 138/138 (+5), APK release 3 ABI terbangun.

## Notes
- Keputusan desain Gap 2: pendekatan *exclude-last* (param `avoid`) dipilih
  daripada stateful shuffle-bag global karena: (a) mudah ditest deterministik,
  (b) tidak butuh state lintas widget, (c) cukup untuk mencegah repeat langsung
  yang jadi keluhan utama. Limitasi: user bisa melihat nilai yang sama lagi
  setelah 1 tekanan lain — itu acceptable untuk pool 3–15 item.
- Keputusan desain Gap 3: fallback KE SELURUH saran dipertahankan (bukan
  return list kosong / disable tombol) karena UX lebih baik memberi inspirasi
  apa pun daripada tombol mati; reasoning layer server sudah menyesuaikan
  gaya. Fokus perbaikan = menutup celah tag supaya fallback jarang terjadi.
