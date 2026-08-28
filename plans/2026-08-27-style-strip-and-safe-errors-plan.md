# Fix 4 Temuan Testing — Snackbar Terhalang, Style Injection, Surprise-Me Style Leak, Error Sensitif

Created: 2026-08-27 16:10:00

## Objective
Memperbaiki 4 temuan hasil testing owner: (1) snackbar preset terkunci tak terlihat di balik bottom sheet, (2) style dikontrol murni oleh preset terpilih — teks deskripsi tidak bisa menyuntik style preset lain (tutup celah free→plus), (3) output Surprise Me bebas dari teks style preset, (4) exception mentah (URL endpoint backend, dsb.) tidak pernah dirender ke UI — sistemik semua layar.

## Keputusan Owner (Approved)
1. F1: sheet tetap terbuka — snackbar render di dalam sheet (Scaffold+Messenger lokal).
2. F4: sistemik semua layar (bukan hanya 2 layar screenshot).
3. Versi bugfix: `0.22.1+75`.

## Root Causes (hasil eksplorasi)
- **F1**: `ScaffoldMessenger.of(context)` dari modal bottom sheet menambah SnackBar ke Scaffold ROOT yang berada di bawah ModalBottomSheetRoute + barrier → terjadwal tapi tak terlihat. (`preset_picker_sheet.dart:204-211`)
- **F2**: `userInput` di-embed mentah: `Subject: ${userInput}` (`generate-sticker/index.ts:310`), reasoning user content (`:1184-1188`), dan `buildEnhancedFinalPrompt(positive)` — satu-satunya sanitasi adalah `sanitizeVisualGuidance` (background/border) yang tidak menyentuh style. Server mengontrol style HANYA via `style_descriptor`; teks user bebas mengarahkan gaya preset lain.
- **F3**: reasoning prompt (`Style: ${styleDescriptor}` + guidance) tidak melarang model menuliskan style; output `positive_prompt` hanya dicek seed-leak/panjang (`surprise-me/index.ts:400-414`), tidak pernah dicek terhadap teks style.
- **F4**: pola `errorMessage: e.toString()` di ±12 bloc/cubit (mission_bloc.dart:275, history_bloc.dart:256, preset_bloc.dart:95, sticker_pack_bloc.dart ×10, showcase_cubit.dart:87, profile_cubit.dart ×6, credit_transactions_bloc.dart ×2, legal_consent_cubit.dart:117, auth_repository UnknownFailure ×8, sticker_repository.dart:126/130) dirender mentah di ±20 titik UI. Tidak ada mapper pusat; l10n tidak punya key koneksi.

## Desain

### F1 — preset_picker_sheet.dart
Bungkus konten sheet: `ScaffoldMessenger` → `Scaffold(backgroundColor: Colors.transparent)` → konten existing. SnackBar locked-tap kini render di dalam modal route (di atas konten sheet), sheet tetap terbuka.

### F2+F3 — Style strip (server-side, generate-sticker + surprise-me)
Helper baru di generate-sticker/index.ts (export `@visibleForTesting`, di-import surprise-me):
- `normalizeStyleText(s)` — lowercase, non-alnum→spasi, collapse.
- `stylePhrasesFromDescriptor(descriptor, label)` — split koma → segmen ≥2 kata; + full descriptor; + label ≥2 kata (label 1 kata dilewati — anti false-positive, terdokumentasi).
- `stripStylePhrases(text, phrases)` — regex per frasa: token di-join `[^a-z0-9]+` (tahan "hand-drawn" vs "hand drawn"), flag gi, maks 3 pass, rapikan spasi.

generate-sticker (path `subject` saja; `text_only` dilewati — teks literal harus utuh):
1. Query 1x/request semua preset aktif (`id, label, style_descriptor`, is_active=true) → frasa asing = semua preset KECUALI terpilih.
2. Strip `userInput` sebelum dipakai di mana pun; hasil <2 char → 400 pesan validasi existing.
3. Strip ulang `positive` hasil reasoning (setelah sanitizeVisualGuidance) sebelum buildEnhancedFinalPrompt.

surprise-me:
1. Frasa = SEMUA preset aktif TERMASUK terpilih (temuan: fragmen dari descriptor preset sendiri).
2. Setelah `candidate = enhanced.positive.trim()`: strip → existing checks + min-length (<10 char → ProviderError `prompt_too_short` → retry → refund path existing).
3. Guidance baru: "Describe ONLY the subject/pose/expressions. Never mention art styles, mediums, textures, palettes, or artist names."

### F4 — safeErrorMessage (Flutter)
NEW `lib/core/errors/safe_error_message.dart`: `safeErrorMessage(l10n, raw, {fallback})` — heuristik marker (case-insensitive):
- Jaringan (`socketexception`, `clientexception`, `failed host lookup`, `connection aborted/refused/closed`, `timed out`, `timeoutexception`, `authretryablefetchexception`, `errno`, `supabase.co`, `xmlhttprequesterror`) → `l10n.connectionError`.
- Internal (`exception(`, `error:`, `postgrest`, `functionexception`, `failure:`, `violates`, `permission denied`) → `l10n.errorOccurred`.
- Else raw (pesan server terkurasi aman); kosong → fallback.
l10n baru `connectionError` EN/ID. Pemetaan murni di UI (bloc tanpa l10n tetap simpan raw).
Out-of-scope (dicatat TODO): snackbar tersembunyi di `add_to_pack_sheet` & `sticker_feedback_buttons`.

## Tasks
- [x] F0 — plan file ini.
- [x] F1a — generate-sticker: helper `normalizeStyleText`/`stylePhrasesFromDescriptor`/`stripStylePhrases` (export @visibleForTesting) + `loadForeignStylePhrases`/`loadAllStylePhrases` + strip userInput (subject; hasil <2 char → 400) + strip ulang `positive` reasoning (fallback ke prompt deterministik jika kosong).
- [x] F1b — surprise-me: strip candidate (frasa SEMUA preset aktif) + min-length <10 (`prompt_too_short`) + guidance rule "Never mention art styles, mediums, textures, color palettes, or artist names".
- [x] F1c — test deno: generate-sticker +8 (109/109), surprise-me +2 (12/12). Fix saat test: (1) ekspektasi salah pada descriptor tanpa koma; (2) `stripStylePhrases` disempurnakan — koma telanjang di tepi kini dibersihkan (`^[,\s]+|[,\s]+$`).
- [x] F2a — preset_picker_sheet: ScaffoldMessenger + Scaffold transparan lokal → snackbar render di dalam modal route, sheet tetap terbuka.
- [x] F2b — NEW `lib/core/errors/safe_error_message.dart` + l10n `connectionError` EN/ID + gen-l10n. Fix: marker `authexception` generik dipindah dari bucket jaringan ke internal (hanya `authretryablefetchexception` yang jaringan).
- [x] F2c — mapper diterapkan di 12 file: legal error screen, missions (snackbar+body), history, home (preset error + kartu failure generasi), packs list (snackbar+body), pack detail (snackbar+body), showcase list, showcase detail (body + `_snack` chokepoint), showcase form sheet (`_snack` chokepoint), profile (snackbar error + panel transaksi), auth (snackbar), sticker feedback buttons.
- [x] F2d — pubspec `0.22.1+75`.
- [x] F3a — NEW `test/safe_error_message_test.dart` (15 test: marker jaringan dari screenshot asli, internal, passthrough terkurasi, fallback). Fix: `delegate.load` async → `setUpAll` await.
- [x] F3b — verifikasi penuh: deno generate-sticker 109/109 + surprise-me 12/12 + list-presets 7/7 (regresi); flutter analyze 0 issues; flutter test 173/173 (+15); build apk 3 ABI sukses.
- [x] F4 — PROJECT_MEMORY + TODO + progress log + commit submodule & utama.

## Milestones
1. Fase 1 — Backend strip (submodule).
2. Fase 2 — Flutter (F1 + F4 + versi).
3. Fase 3 — Verifikasi.
4. Fase 4 — Dokumentasi & commit.

## Risks
- Strip konservatif: free user masih bisa menulis 1 kata khas ("linocut") — risiko kecil diterima, terdokumentasi; frasa ≥2 kata menutup kasus copy-paste surprise-me.
- Strip bisa mengubah prompt user yang mengandung frasa descriptor umum — dampak minor.
- 1 query tambahan per generasi (tanpa cache — kesederhanaan).
- Heuristik marker: pesan baru yang mengandung marker → generik (aman-sisi).
- text_only tidak di-strip (teks literal = konten).

## Progress Log
- 2026-08-27 16:10 — Plan dibuat & disetujui (sheet tetap terbuka; error sistemik; versi 0.22.1+75).
- 2026-08-28 09:27 — Implementasi selesai, semua verifikasi hijau (deno 109+12+7; analyze 0; test 173/173; APK 3 ABI). Perbaikan minor saat implementasi: cleanup koma tepi di stripStylePhrases; marker authexception dipindah ke bucket internal; setUpAll async untuk l10n test. Commit submodule: `fix(prompts): strip foreign style text from inputs and surprise-me output`. Commit utama: `fix(ux): visible locked-preset feedback, style-strip backend, safe error messages`. Sisa manual owner: deploy generate-sticker + surprise-me, release APK 0.22.1+75.

## Notes
- Deploy manual owner: push submodule → `supabase functions deploy generate-sticker` + `deploy surprise-me` (tanpa migrasi) → release APK `0.22.1+75`.
- Tanpa perubahan skema DB; 7 catatan kritis plan seasonal tetap berlaku.
