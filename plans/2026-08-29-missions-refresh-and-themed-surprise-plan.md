# Refresh Layar Misi saat Error + Surprise-Me Bertema Preset Musiman

Created: 2026-08-29 09:05:00

## Objective
Dua temuan testing: (1) layar Misi saat gagal jaringan tidak punya cara refresh selain buka ulang app; (2) Surprise Me menghasilkan ide seputar domain tema preset musiman yang terpilih (mis. back_to_school_doodle → ide seputar sekolah), bukan subjek generik acak.

## Keputusan Owner (Approved)
- Kedua perbaikan dieksekusi bersama; versi `0.23.0+77` (perilaku surprise-me berubah = minor).

## Root Causes
1. `missions_screen.dart`: `MissionLoadRequested` hanya dipicu saat `status == initial`; body error = `Center(Text)` tanpa RefreshIndicator/tombol. `_onLoad` (mission_bloc.dart:256) tanpa guard → re-dispatch dari error aman.
2. `reasoning_guidance` = panduan STYLE yang dipakai `enhancePrompt` generasi normal → tidak boleh dipakai untuk tema. Tidak ada kanal domain tema di rantai surprise-me (seed generik 60×40).

## Desain
- **F1 Flutter**: helper `_reload` → re-add `MissionLoadRequested(userId)`; body error = RefreshIndicator + ListView (AlwaysScrollableScrollPhysics) + ikon + `safeErrorMessage` + tombol retry (pola `_PresetErrorView`); view loaded juga dibungkus RefreshIndicator (pull-to-refresh umum).
- **F2 Migrasi** `20260829000001_surprise_theme.sql`: `ADD COLUMN IF NOT EXISTS surprise_theme TEXT` (aditif nullable) + UPDATE 20 preset musiman dengan tema domain EN (subjek/objek/situasi; TANPA kosakata style/medium/palet agar tak benturan `stripStylePhrases`). Non-musiman NULL = perilaku lama.
- **F3 EF**: `loadPreset` select + `PresetRecord.surprise_theme` (default null; generate-sticker mengabaikannya). `buildSurpriseGuidance` + `theme?` → instruksi "Theme requirement: MUST be about {theme}... seed is only a twist suggestion". Handler pass `preset.surprise_theme`.
- **F4**: deno +3 (guidance tema ada/tidak ada, kontrak handler); flutter analyze/test/apk.

## Tasks
- [x] F0 — plan file ini.
- [x] F1 — missions_screen: branch error kini RefreshIndicator + ListView (AlwaysScrollableScrollPhysics) + ikon + safeErrorMessage + tombol retry. (View loaded ternyata SUDAH punya RefreshIndicator sejak awal — gap-nya murni branch error.)
- [x] F2 — Migrasi `20260829000001_surprise_theme.sql`: ADD COLUMN surprise_theme + UPDATE 20 tema musiman (redaksi menghindari kosakata style descriptor, sudah cross-check terhadap frasa stripper).
- [x] F3 — loadPreset select + `PresetRecord.surprise_theme` (default null); `buildSurpriseGuidance` + `theme?` → "Theme requirement: MUST be about {theme}... seed is only a twist suggestion"; handler pass `preset.surprise_theme`.
- [x] F4 — Verifikasi penuh: deno surprise-me 15/15 (+3), generate-sticker 109/109 (regresi loadPreset), flutter analyze 0, flutter test 179/179, APK 3 ABI sukses.
- [ ] F5 — Docs + commit & push kedua repo (dikerjakan setelah entry ini).

## Risks
- Tema mempersempit variasi (by design); avoid-list + twist seed jaga keberagaman dalam domain.
- Tema yang mirip frasa descriptor bisa ter-strip — mitigasi: redaksi tema menghindari kosakata descriptor.
- Spinner RefreshIndicator sebentar tumpang tindih loading bloc (pola home, diterima).
- ADD COLUMN aditif instan di ~50 row.

## Progress Log
- 2026-08-29 09:05 — Plan dibuat & disetujui.
- 2026-08-29 10:20 — Implementasi selesai, semua verifikasi hijau (deno 15/15 + 109/109 regresi; analyze 0; test 179/179; APK 3 ABI). Temuan saat implementasi: view loaded layar misi sudah punya RefreshIndicator sejak awal — hanya branch error yang perlu diperbaiki.

## Notes
- Hanya surprise-me konsumsi tema; generasi normal & text_only tak tersentuh.
- Deploy manual owner: push submodule → `supabase db push` (20260829) → deploy `surprise-me` + `generate-sticker` (loadPreset shared) → release APK `0.23.0+77`.
