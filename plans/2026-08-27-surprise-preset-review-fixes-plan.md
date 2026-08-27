# Surprise Preset Review Fixes

Created: 2026-08-27

## Objective
Tutup gap implementasi `909f81b` / `supabase:2794370` terhadap plan `plans/2026-08-26-surprise-me-prompt-leak-fix-plan.md`, sesuai keputusan owner: disable button saat loading, keep `requiredRole` hardcode `plus`, verifikasi cukup `analyze+test` tanpa `build apk`.

## Scope
- `supabase/functions/generate-sticker/index.ts:62` (keep hardcode `requiredRole:'plus'` — no change, documented)
- `supabase/functions/generate-sticker/index.ts:499` & `:963` TS errors
- `supabase/functions/generate-sticker/index.ts:1079` (`parseEnhancedPrompt`), `:1118` (`extractPromptFields`) — tambah `@visibleForTesting`
- `supabase/functions/list-presets/index.ts:70` + new `list-presets/index_test.ts` contract
- `lib/presentation/screens/home/home_screen.dart:161` (`_onSurpriseMePressed`), `:577` wiring, `:449` fallback, `:496` loading pattern

Out of scope: skema DB, RLS, billing 150/10k, kompensasi `credit_transactions`.

## Keputusan Owner (Approved)
1. **F2 empty-presets → disable button (opsi B)**
2. **F1 requiredRole → keep hardcode `plus`**
3. **F7 build apk → analyze+test saja**

## Milestones
1. Fase 1 — UI guard (R2/R3)
2. Fase 2 — DX & test coverage (R4/R5)
3. Fase 3 — Type safety & re-verify (R6/R7)

## Tasks
- [x] R2 — `home_screen.dart:577` disable `SurpriseMeButton` saat `presets.isEmpty` (`isNotEmpty`); `home_screen.dart:172` tetap block `null => chooseValidStyle` sinkron `_onGenerate:114`.
- [x] R3 — Tambah komentar di `home_screen.dart:172` jelaskan `null => block` sinkron `_onGenerate:114`, bukan fallback `kawaii` lama `:246`.
- [x] R4 — `generate-sticker/index.ts:1079/1118` tambah `// @visibleForTesting` di atas export.
- [x] R5 — Buat `supabase/functions/list-presets/index_test.ts` 3 kasus: `guest→[guest]`, `free→[guest,free]`, `plus→[guest,free,plus]` — 4 tests passed.
- [x] R6 — Fix TS: `generate-sticker/index.ts:499` `NonNullable<...>[number]>["message"]` + `:963` tambah `ollama/cerebras` branch & exhaustive `never`; `deno test` with check now passes (88 passed with `deno check`).
- [x] R7 — Re-verify: `SUPABASE_URL=... deno test --allow-env --allow-net --allow-read` 88+10+4=102 passed, `flutter analyze lib` No issues, `flutter test` 145 passed.
- [x] R8 — Update `plans/2026-08-26-surprise-me-prompt-leak-fix-plan.md` Progress Log — catat F1 hardcode decision, R2 disable, apk skip.

## Risks
- Disable saat loading: user cold start lihat button disabled 1-2s; lebih baik daripada snackbar palsu. Server tetap 403 sebagai guard kedua.
- Hardcode plus: jika nanti ada tier baru selain plus, perlu revisit F1.

## Progress Log
- 2026-08-27 — Review 8 temuan, owner putuskan disable / hardcode / analyze+test. Plan final dirangkum.
- 2026-08-27 — Build mode entered, persisting plan.
- 2026-08-27 — R2/R3 selesai: `home_screen.dart:172` komentar block + `:577` `enabled: !submitting && presets.isNotEmpty`. R4 `@visibleForTesting`. R5 `list-presets/index_test.ts` 4 tests. R6 TS 499/963 fixed, `deno check` passes. R7 102 deno + 145 flutter passed. Plan closed.

## Notes
- Standar Oracle C2M / TM Forum ODA tidak relevan (non-billing bugfix).
- Contoh validasi setelah fix:
  ```dart
  // home_screen.dart:577
  SurpriseMeButton(
    enabled: !submitting && presets.isNotEmpty,
    onPressed: () => _onSurpriseMePressed(isTextOnly: isTextOnly, presets: presets),
  )
  ```
