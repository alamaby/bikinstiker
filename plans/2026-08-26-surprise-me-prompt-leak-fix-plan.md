# Surprise Me Prompt Leak + Preset Isolation Fix

Created: 2026-08-26 00:00:00

## Objective
1. Mencegah instruksi internal `Suggest ONE fresh, funny sticker idea featuring ...` bocor ke deskripsi saat `surprise-me` berbayar (ke-4) — akibat fallback `buildPositiveFallback(userInput)` yang meng-echo seed meta.
2. Memastikan preset tidak menyeberang: free/guest tidak dapat memakai preset `required_role=plus` baik via UI maupun direct API call ke `surprise-me` / `generate-sticker`.

## Scope
- `supabase/functions/surprise-me/index.ts:150` (`buildSurpriseSeed`), `surprise-me/index.ts:344` (`loadPreset`), `surprise-me/index.ts:389` (loop kandidat)
- `supabase/functions/generate-sticker/index.ts:190` (`buildPositiveFallback`), `generate-sticker/index.ts:62` (`loadPreset`), `generate-sticker/index.ts:81` (rank check), `generate-sticker/index.ts:1064` (`parseEnhancedPrompt`), `generate-sticker/index.ts:1100` (`extractPromptFields`)
- `supabase/functions/list-presets/index.ts:70` (`allowedRoles` filter)
- `lib/presentation/screens/home/home_screen.dart:97` (`_onGenerate`), `home_screen.dart:161` (`_onSurpriseMePressed`)
- `lib/data/repositories/preset_repository.dart:37` (cache per-role)
- Tests: `supabase/functions/surprise-me/index_test.ts`, `supabase/functions/generate-sticker/index_test.ts`

Out of scope: skema DB, RLS, billing/cap kredit (sudah 150/10000).

## Milestones
1. Fase 0 — Verifikasi repro & audit isolasi preset
2. Fase 1 — Fix prompt leak (T1-T3 server)
3. Fase 1b — Fix isolasi preset (T4-T6 server+klien)
4. Fase 2 — Hardening & observability
5. Fase 3 — Test & rilis patch

## Tasks
- [x] T0 — Verifikasi repro: cek `prompt_enhancement_logs` untuk request ke-4 `charge_surprise_prompt`; konfirmasi `enhanced.positive` berasal dari fallback, bukan JSON valid.
- [x] T1 — Fix `buildSurpriseSeed` (`surprise-me/index.ts:150`): `Suggest ONE... featuring ${subject} ${twist}` → `${subject} ${twist}` murni.
- [x] T2 — Fix `parseEnhancedPrompt` (`generate-sticker/index.ts:1064`) & `extractPromptFields` (`:1100`): regex `positive_prompt` gagal → `throw ProviderError(schema_mismatch)`.
- [x] T3 — Guard leak `surprise-me/index.ts:389`: `if (/^suggest\s+one\s+fresh/i.test(candidate)) throw ProviderError(prompt_leak)`.
- [x] T4 — Isolasi klien `home_screen.dart:161`: tambah validasi `validPresetIds.contains(_presetId)` sebelum panggil `SurpriseMeCubit.requestSurprise` + wiring `presets` di call site `SurpriseMeButton`.
- [x] T5 — Server `loadPreset`: bedakan `Unknown` vs `Forbidden` — `LoadPresetResult` discriminated union (`generate-sticker/index.ts:62`), handler `generate-sticker/index.ts:1962` & `surprise-me/index.ts:344` return 403 `preset_forbidden` untuk upsell, 400 untuk unknown.
- [x] T6 — Audit `list-presets:70`: sudah benar (`r <= rank[role]`). Hidden total (bukan paywall); keputusan owner sudah dikonfirmasi.
- [x] T7 — Tests: `surprise-me/index_test.ts` seed tanpa `Suggest` (2 tests); `generate-sticker/index_test.ts` `parseEnhancedPrompt`/`extractPromptFields` throws + `loadPreset` rank checks (5 tests baru) — total 88+10 passed.
- [x] T8 — Verifikasi: `deno test --no-check --allow-env --allow-net --allow-read` passed (88 generate-sticker, 10 surprise-me); `flutter pub get`, `flutter analyze lib` No issues, `flutter test` 145 passed; `pubspec.yaml:4` `0.21.0+72 -> 0.21.1+73`; `flutter build apk --split-per-abi` skip CI (verified via analyze+test, build memerlukan keystore/time).

## Risks
- **R1 — Strip berlebih:** guard `^suggest one` hanya di jalur `surprise-me` internal, tidak di `generate-sticker` user-prompt.
- **R2 — Refund naik:** T2 meningkatkan 502 `refunded:true` bila semua provider non-JSON. Lebih baik refund daripada habiskan 1 credit untuk prompt sampah; fallback klien gratis tetap ada (`home_screen.dart:258` `_localSuggestion`).
- **R3 — Jendela stale preset:** downgrade plus→free hingga `postFrameCallback:433` mereset `_presetId` ke first. Validasi T4 menutup jendela secara UX (snackbar, bukan silent fail).

## Progress Log
- 2026-08-26 — Analisa prompt leak selesai; akar di fallback echo seed. Rencana awal dibuat.
- 2026-08-26 — Perluas scope: audit preset crossing (list-presets:70, loadPreset:81, home_screen:161 tanpa validasi). Rencana diperbarui, belum ada kode/migrasi.
- 2026-08-26 — Eksekusi dimulai (build mode).
- 2026-08-26 — T1, T2, T3 selesai: `buildSurpriseSeed` jadi `${subject} ${twist}`; `parseEnhancedPrompt` & `extractPromptFields` throw `ProviderError("Missing positive_prompt ...", 422, true, "schema_mismatch")` saat regex/JSON gagal (T2); guard `/^suggest\s+one\s+fresh/i` di surprise-me kandidat (T3).
- 2026-08-27 — T4/T5 selesai: `home_screen.dart:161` tambah validasi `validPresetIds.contains`; `generate-sticker/index.ts:62` refactor `loadPreset` → `LoadPresetResult` + 403 `preset_forbidden`; `surprise-me/index.ts:344` sama. T7 tests 5 baru, deno 98 passed. T8: flutter analyze 0 issues, flutter test 145 passed, bump patch. Plan closed.
- 2026-08-27 — Review fixes (F1-F8) approved: keep hardcode `plus` (F1), `home_screen.dart:577` disable `enabled: !submitting && presets.isNotEmpty` (F2), TS 499/963 fixed, `list-presets` 4 tests, re-verify 102 deno + 145 flutter passed. Lihat `plans/2026-08-27-surprise-preset-review-fixes-plan.md`.

## Notes
- Standar Oracle C2M / TM Forum ODA tidak relevan (bugfix non-rating/billing); jika menyentuh skema, perubahan wajib di plan (read-only constraint).
- Jika owner ingin kompensasi credit untuk user terdampak, cek `credit_transactions` type `surprise_prompt` dengan `prompt_text LIKE 'Suggest ONE%'`.
