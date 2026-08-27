# Seasonal Preset Styles (September–Desember 2026/2027)

Created: 2026-08-27 11:45:00

## Objective
Menambahkan 20 preset style musiman (5/bulan, Sep–Des) yang tampil paling atas dengan badge "Limited" + info periode; 8 preset plus-only (2/bulan — Set A: Cozy Study Club, Autumn First Leaf, Witchy Potion Lab, Gothic Stained Glass, November Rain Noir, Woodland Sweater Club, Midnight New Year Chrome, Frosted Paper Village); preset plus tampil terkunci (gembok) bagi free/guest termasuk 10 preset plus existing; jendela waktu sekali jalan 2026–2027.

## Keputusan Owner (Approved)
1. 2 preset plus per bulan × 4 bulan = 8 plus (Set A "Premium & craft").
2. Jendela sekali jalan 2026–2027 (migrasi tahun depan menggeser + arsip manual).
3. Semua preset plus (existing + seasonal) tampil terkunci bagi free/guest.
4. Versi preset = konvensi (tanpa kolom baru; `final_prompt` sudah snapshot per generasi).

## Mapping 7 Catatan Kritis → Desain
1. **Availability ≠ prompt** → jendela hanya di `valid_from`/`valid_until`; style_descriptor tanpa bulan/tahun.
2. **UTC konsisten** → timestamptz UTC; anchor batas hari Asia/Jakarta (WIB, UTC+7, preseden daily check-in); `valid_until` = 23:59:59 WIB hari terakhir.
3. **Tidak hapus kedaluwarsa** → baris tetap, is_active true; hilang dari katalog via filter jendela; histori reproducible.
4. **Preset ≠ versi** → konvensi: revisi descriptor hanya via migrasi baru + header catat perubahan.
5. **Alternatif regional** → Frosted Paper Village (plus) & Tropical Holiday Cheer (free) tampil berdampingan; tanpa deteksi lokasi.
6. **Detail dibatasi sticker** → satu subjek fokus, siluet kuat, outline terbaca.
7. **Tanpa nama seniman hidup** → hanya karakteristik visual eksplisit.

## Infrastruktur Existing (tanpa perubahan)
- Skema `sticker_presets` sudah punya `required_role`, `valid_from`/`valid_until`, `is_active`, `sort_order` → tidak ada perubahan skema.
- `generate-sticker` `loadPreset` sudah enforce role (403 preset_forbidden) + jendela (400); `surprise-me` me-reuse.
- Model client sudah parse `requiredRole`/`validFrom`/`validUntil`.

## Tabel 20 Preset (sort 1–20; `input_mode='subject'`)

| sort | id | Label EN | Emoji | Role | valid_from (WIB) | valid_until (WIB) |
|---|---|---|---|---|---|---|
| 1 | back_to_school_doodle | Back-to-School Doodle | 🎒 | free | 2026-08-25 00:00 | 2026-09-20 23:59:59 |
| 2 | cozy_study_club | Cozy Study Club | ☕ | plus | 2026-09-01 00:00 | 2026-09-30 23:59:59 |
| 3 | rainy_days | Rainy Days | 🌧️ | free | 2026-09-01 00:00 | 2026-10-10 23:59:59 |
| 4 | autumn_first_leaf | Autumn First Leaf | 🍂 | plus | 2026-09-10 00:00 | 2026-10-10 23:59:59 |
| 5 | harvest_market | Harvest Market | 🧺 | free | 2026-09-10 00:00 | 2026-10-15 23:59:59 |
| 6 | friendly_spooky | Friendly Spooky | 👻 | free | 2026-10-01 00:00 | 2026-11-02 23:59:59 |
| 7 | witchy_potion_lab | Witchy Potion Lab | ⚗️ | plus | 2026-10-01 00:00 | 2026-10-31 23:59:59 |
| 8 | gothic_stained_glass | Gothic Stained Glass | 🏰 | plus | 2026-10-05 00:00 | 2026-11-05 23:59:59 |
| 9 | pumpkin_patch_clay | Pumpkin Patch Clay | 🎃 | free | 2026-10-01 00:00 | 2026-11-10 23:59:59 |
| 10 | night_forest_linocut | Night Forest Linocut | 🦉 | free | 2026-10-01 00:00 | 2026-11-15 23:59:59 |
| 11 | gratitude_journal | Gratitude Journal | 🙏 | free | 2026-11-01 00:00 | 2026-11-30 23:59:59 |
| 12 | warm_kitchen_table | Warm Kitchen Table | 🍲 | free | 2026-11-01 00:00 | 2026-12-05 23:59:59 |
| 13 | woodland_sweater_club | Woodland Sweater Club | 🧶 | plus | 2026-11-01 00:00 | 2026-12-15 23:59:59 |
| 14 | november_rain_noir | November Rain Noir | 🌂 | plus | 2026-11-01 00:00 | 2026-11-30 23:59:59 |
| 15 | deal_hunter_pop | Deal Hunter Pop | 🛍️ | free | 2026-11-10 00:00 | 2026-12-02 23:59:59 |
| 16 | gingerbread_workshop | Gingerbread Workshop | 🍪 | free | 2026-11-25 00:00 | 2026-12-26 23:59:59 |
| 17 | frosted_paper_village | Frosted Paper Village | 🏘️ | plus | 2026-12-01 00:00 | 2027-01-10 23:59:59 |
| 18 | tropical_holiday_cheer | Tropical Holiday Cheer | 🌴 | free | 2026-12-01 00:00 | 2027-01-02 23:59:59 |
| 19 | midnight_new_year_chrome | Midnight New Year Chrome | 🥂 | plus | 2026-12-15 00:00 | 2027-01-07 23:59:59 |
| 20 | year_in_review_scrapbook | Year in Review Scrapbook | 📔 | free | 2026-12-10 00:00 | 2027-01-15 23:59:59 |

("September Rainy Window" di-rename "Rainy Days" sesuai catatan risiko dokumen sumber.)

## Tasks
- [x] Fase 0 — Persist plan file ini.
- [x] Fase 1a — Migrasi `supabase/migrations/20260827000001_seasonal_presets.sql`: UPDATE sort_order +100 semua preset existing; INSERT 20 preset (upsert) dengan jendela UTC (WIB-anchored).
- [x] Fase 1b — `list-presets/index.ts`: helper `allowedRolesForRequest(url, role)` → null saat `?include_locked=1` (skip filter role); tanpa param → perilaku lama persis.
- [x] Fase 1c — `list-presets/index_test.ts`: kontrak baru (tanpa param: free tanpa plus; dengan param: null roles; nilai lain tetap difilter). Deno 7/7.
- [x] Fase 2a — `sticker_preset.dart`: `isSeasonal` (validUntil != null), `isLockedFor(role)` (urutan enum).
- [x] Fase 2b — `preset_repository.dart`: invoke `list-presets?include_locked=1`.
- [x] Fase 2c — `home_screen.dart`: viewRole efektif (guest≡free via watch AuthBloc+SubscriptionBloc); `selectable` guard (_onGenerate, auto-select, HomePrefill, surprise-me, fallback selector); `_PresetSelector` badge Limited + fallback first selectable; picker diekstrak ke widget publik `lib/presentation/widgets/preset_picker_sheet.dart` (section Seasonal + header info + tile terkunci gembok/dim/snackbar Plus + tanggal berakhir via intl yMMMd locale-aware).
- [x] Fase 2d — `preset_localizations.dart` +40 case; ARB EN/ID +45 key (5 UI + 20 label + 20 desc); gen-l10n sukses.
- [x] Fase 2e — `pubspec.yaml` 0.21.1+73 → 0.22.0+74.
- [x] Fase 3a — NEW `test/sticker_preset_test.dart` (8 test: isSeasonal, matriks isLockedFor, parse jendela waktu).
- [x] Fase 3b — NEW `test/preset_picker_sheet_test.dart` (5 widget test; fixture id di luar key lokalisasi agar tidak bentrok dengan preset_localizations).
- [x] Fase 3c — Verifikasi penuh: flutter analyze 0 issues; flutter test 158/158 (+13); build apk --split-per-abi 3 APK; deno list-presets 7/7; deno generate-sticker 101/101 (regresi).
- [ ] Fase 3d (manual, owner) — Deploy: push submodule → `supabase db push` (migrasi 20260827000001) → `supabase functions deploy list-presets` → smoke app.

## Milestones
1. Fase 1 — Submodule supabase (migrasi + EF + test).
2. Fase 2 — Flutter client (model, repository, UI, l10n, versi).
3. Fase 3 — Test & verifikasi & dokumentasi.

## Risks
- Kontrak list-presets berubah arah dari 909f81b (isolasi listing → flagging); isolasi generasi tetap di loadPreset (403) + test generate-sticker tetap hijau.
- App versi lama tidak kirim include_locked → perilaku lama, nol regresi.
- Preset #1 aktif langsung saat deploy (jendela mulai 25 Agu 2026).
- 18 tile terkunci bagi free user bisa terasa ramai — keputusan owner disengaja (etalase upgrade).
- Cache preset 5 menit: setelah upgrade plus, gembok hilang maks 5 menit (pull-to-refresh memaksa).
- Shift sort_order +100: fungsi mission tidak bergantung sort_order (terverifikasi); risiko rendah.
- Tahun depan butuh migrasi penggeser jendela + arsip manual (Deal Hunter Pop) — catat di TODO.

## Progress Log
- 2026-08-27 11:45 — Plan dibuat & disetujui owner (4 keputusan: Set A plus, sekali jalan 2026–2027, semua plus terlihat terkunci, versi via konvensi).
- 2026-08-27 12:25 — Implementasi selesai. Fase 1 (migrasi + EF + test deno 7/7), Fase 2 (model, repo, widget picker publik, home_screen wiring, l10n EN/ID, versi 0.22.0+74), Fase 3 (analyze 0, test 158/158, APK 3 ABI, deno generate-sticker regresi 101/101). Catatan perbaikan saat implementasi: (1) klausa WHERE shift sort_order awalnya `sort_order <= 20` — salah, bisa merusak urutan relatif; dikoreksi menjadi shift SEMUA baris; (2) resolveUserRole kini hanya dipanggil saat filter role aktif (hemat query per request); (3) fixture test awal bentrok dengan key preset_localizations (label tile bukan id) → id fixture diganti; (4) gen-l10n getter-nya `localizationsDelegates`, bukan `delegates`. Sisa: deploy manual owner (Fase 3d) + sisa SSC5 legacy.

## Notes
- `supabase/` = git submodule (repo privat `bikinstiker-supabase`): commit di submodule, bump pointer di repo utama.
- Deploy manual owner: `supabase db push` + `supabase functions deploy list-presets`.
- Standar TOGAF/C2M tidak diimpose (fitur kecil, proporsional).
