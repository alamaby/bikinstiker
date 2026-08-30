# Fix Critical C4-C7 (Code Review 2026-07-09)

Created: 2026-07-09

## Objective
Tutup semua critical open findings C4-C7:
- C4: Guest-to-registered migration mati karena RPC dipanggil via service-role tanpa `auth.uid()`.
- C5: `create-guest-migration` salah parsing response RPC `RETURNS TABLE`.
- C6: `grant_monthly_credits` ledger mencatat full reward walau wallet kena cap.
- C7: `credit_transactions` tidak punya `amount <> 0` + type/sign consistency.

## Scope
- `supabase/functions/create-guest-migration/index.ts`
- `supabase/functions/migrate-guest-stickers/index.ts`
- New migration: C6 monthly grant fix
- New migration: C7 constraints

## Tasks
- [x] C4/C5: Fix create-guest-migration Edge Function (userClient.rpc + array parsing)
- [x] C4/C5: Fix migrate-guest-stickers Edge Function (userClient.rpc + storage copy before DB)
- [x] C6: New migration fix grant_monthly_credits ledger actual delta
- [x] C7: Preflight credit_transactions + new migration constraints
- [x] Verifikasi: flutter analyze (clean, pre-existing warning only)
- [x] Update TODO.md progress + PROJECT_MEMORY.md

## Risks
- Storage copy before DB migration dapat meninggalkan orphan files jika RPC gagal. Mitigasi: semua asset path yang akan di-DB-update WAJIB copy sukses; jika gagal token tidak dikonsumsi.
- Constraint `VALIDATE` AMAN: preflight 0 row, sudah validasi sukses.
- Enum `transaction_type` tidak ditambah; tipe yang dipakai sudah ada.

## Progress Log
- 2026-07-09 — Mulai implementasi C4/C5 fix.
- 2026-07-09 — C4/C5 done: Edge Functions pindah ke userClient.rpc, storage copy sebelum DB, array parsing fix.
- 2026-07-09 — C6 done: migrasi `20260709000025` grant_monthly_credits actual delta.
- 2026-07-09 — C7 done: migrasi `20260709000026` constraints NOT VALID.
- 2026-07-09 — flutter analyze: 1 pre-existing warning (unused_import dart:io di rewarded_ad_repository.dart). No new issues.
- 2026-07-09 — C4 follow-up: token expiry check sebelum storage copy + PNG/tray icon jadi required (semua path yang DB-update harus copy sukses).
- 2026-07-09 — C7 VALIDATE CONSTRAINT sukses (preflight 0 row).
- 2026-07-09 — H4 marked obsolete karena C4 fix memulihkan auth context.
