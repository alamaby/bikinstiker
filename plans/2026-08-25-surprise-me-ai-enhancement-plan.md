# Surprise Me AI Enhancement Plan

Created: 2026-08-25 12:00:00

## Objective
Mengubah "Surprise me" dari random curated list lokal menjadi deskripsi stiker
AI-generated via reasoning provider, dengan konfirmasi biaya, kuota gratis
harian, anti-repeat per-user (DB), style-aware terhadap preset terpilih,
batas 200 karakter, dan visual feedback penuh.

## Keputusan Desain (disetujui user)
- **Biaya:** N gratis/hari (default `FREE_DAILY_LIMIT = 3`), setelah itu 1 credit.
- **Anti-repeat:** DB history (`surprise_me_history`) — akurat lintas device.
- **Style-aware:** deskripsi mengikuti style_descriptor preset terpilih (dimuat
  server-side dari DB, tidak percaya client).
- Mode text-only (tipografi) tetap perilaku lokal lama — di luar scope v1.

## Scope
- Migration DB baru (enum, CHECK fix, tabel history, 3 RPC)
- Ekstraksi `_shared/reasoning.ts` + `_shared/operator_alerts.ts`
- Edge Function baru `surprise-me` + entry `config.toml`
- Flutter: repository, cubit, dialog konfirmasi, feedback states, l10n EN/ID
- Test: deno (generate-sticker regression + surprise-me baru), flutter

## Alur End-to-End
1. Klik tombol → fetch `get_surprise_me_quota()` → dialog konfirmasi dinamis
   (gratis sisa X / bayar 1 credit dengan saldo; insufficient → CTA).
2. Confirm → POST `surprise-me {presetId}`:
   - Cooldown in-memory 5s/user + cap 30/hari/user.
   - Hitung pemakaian hari ini dari `surprise_me_history`.
   - Lewat kuota → `charge_surprise_prompt()` deduct atomik (402 jika kurang).
   - Load preset dari DB (style_descriptor valid) + inject randomizer
     server-side (pool subjek × twist acak) + avoid-list 20 prompt terakhir.
   - Reasoning chain failover (config DB `route_scope='reasoning'`).
   - Validasi non-kosong & ≤200 char; retry sekali jika gagal.
   - Insert history → respons `{prompt, balance, freeRemaining, charged}`.
   - Gagal total semua provider → auto-refund → error response.
3. Client sukses → isi TextField + refresh WalletBloc + haptic.
4. Client gagal(refunded) → snackbar + fallback lokal kPromptSuggestions gratis.

## Milestones
1. Phase 1 — DB migration
2. Phase 2 — Shared module extraction (gate: deno test generate-sticker lulus)
3. Phase 3 — Edge function surprise-me + tests
4. Phase 4 — Flutter client + l10n
5. Phase 5 — Verifikasi penuh + housekeeping

## Tasks
- [x] T1: Persist plan file (this file) + update TODO.md
- [x] T2: Fase 1 — Migration `20260825000001_surprise_me_ai.sql` (enum standalone,
      CHECK sign-consistency direplace, tabel history + RLS + index, 3 RPC)
- [x] T3: Fase 2a — **Deviasi dari rencana `_shared/`** (lihat Progress Log):
      export `callReasoningProvider`, `loadReasoningConfigs`, `resolveUserRole`,
      `loadPreset` dari generate-sticker/index.ts; surprise-me import relatif.
- [x] T4: Fase 2b — GATE: deno test generate-sticker 80/80 lulus (dua kali:
      setelah ekspor awal dan setelah ekspor tambahan)
- [x] T5: Fase 3 — Function `surprise-me` + config.toml + deno.json
      (deno.json menyertakan imagescript karena import lintas-function)
- [x] T6: Fase 3b — Deno test surprise-me: 9/9 lulus
- [x] T7: Fase 4a — SurpriseMeRepository (+SurpriseMeQuota/SurpriseMeResult) +
      SurpriseMeCubit/state + DI registration + BlocProvider di app.dart
- [x] T8: Fase 4b — home_screen dialog konfirmasi dinamis (kuota gratis vs bayar),
      spinner + label loading, gating input, listener sukses/gagal dengan
      fallback lokal, haptic feedback, l10n EN/ID (10 key baru), text-only lokal
- [x] T9: Bump versi pubspec → `0.20.0+70`
- [x] T10: Verifikasi — deno 9/9 + 80/80, flutter analyze 0 issues,
      flutter test 138/138, build apk 3 ABI sukses
- [ ] T11: Update PROJECT_MEMORY.md (deploy migration + function masih pending)

## Risks
- Menyentuh generate-sticker (path produksi kritis): mitigasi move-code murni
  + deno test 80/80 sebagai gate sebelum lanjut.
- Race kuota gratis paralel: cooldown 5s; worst case tetap konsumsi kuota N
  (tidak ada kerugian finansial).
- Latensi reasoning ~10–15s worst case chain: feedback visual + timeout +
  refund otomatis.
- Uniqueness lintas user tidak absolut: per-user akurat (DB); lintas-user
  probabilistik — secara UX memang tak terlihat antar user.
- Ongkos reasoning provider naik: kuota gratis 3/hari + cap 30/hari + credit.

## Progress Log
- 2026-08-25 12:00:00 — Plan final disetujui user (kuota gratis→bayar, DB
  history, style-aware). Implementasi dimulai.
- 2026-08-25 13:30:00 — **Deviasi desain Fase 2**: ekstraksi `_shared/reasoning.ts`
  dibatalkan karena helper HTTP dipakai luas oleh kode image provider (diff
  besar & berisiko). Diganti jalur lebih aman dengan reuse yang sama: guard
  `import.meta.main` sudah ada di generate-sticker/index.ts sehingga
  surprise-me import langsung; cukup keyword `export` pada 4 fungsi (nol
  perubahan logika). Konsekuensi: surprise-me/deno.json menyertakan mapping
  `imagescript` (graph import generate-sticker), dan deploy surprise-me
  membawa file generate-sticker sebagai dependency. Gate 80/80 dua kali lulus.
  Semua fase selesai; verifikasi penuh hijau (analyze 0, test 138/138,
  APK 3 ABI).

## Notes
- `kMaxPromptChars = 200` client-side sudah cocok dengan batas server.
- Jebakan migrasi yang wajib ditangani: CHECK sign-consistency dari
  `20260709000026` hanya mengizinkan negatif untuk `generate_sticker` — insert
  ledger `-1` bertipe baru akan gagal tanpa replace constraint. Statement
  `ALTER TYPE ... ADD VALUE` harus berdiri sendiri dalam transaksinya.
- Fallback curated saat provider down dilakukan CLIENT-side (kPromptSuggestions)
  agar server lean dan fallback tidak dikenakan biaya.
