# Showcase Review Fixes — Rencana Detail

Created: 2026-08-26
Status: **DISETUJUI — eksekusi berjalan**

## Objective

Memperbaiki 11 temuan code review implementasi Showcase Sticker Pack
(2 HIGH, 3 MEDIUM kode + 1 keputusan produk, 6 LOW) tanpa mengubah
keputusan ekonomi/arsitektur yang sudah disetujui owner.

## Keputusan Owner (putaran ini)

| Temuan | Keputusan |
|---|---|
| M4 pack pembelian terkunci saat downgrade | **Biarkan terkunci** — konsisten aturan slot; otomatis terbuka saat upgrade; dicatat di draft ToS v2 (Fase 4 marketplace plan) |
| L9 badge Listed | **Implementasi** via `fetchListedPackIds()` di UI layer + chip pada PackCard |

## Scope

- 1 migrasi baru `20260826000007_showcase_review_fixes.sql` — hanya
  CREATE OR REPLACE FUNCTION (non-destruktif, tanpa enum/CHECK baru →
  aman dari jebakan surprise-me ADD VALUE)
- Edge Functions `showcase-purchase-copy` & `showcase-preview` + test Deno
- Flutter: showcase detail/browse screen, form sheet, repository,
  StickerPackBloc tidak disentuh (badge via UI layer), PackCard,
  widget test gate baru, l10n en/id

## Tasks

### Fase A — DB (migration 00007)
- [x] **M1**: `refund_pending_showcase_purchase` → decrement
      `purchase_count = GREATEST(0, purchase_count - 1)`
- [x] **M3**: `purchase_showcase_pack` hitungan slot → `AND is_locked = FALSE`
      (selaras `create_pack`; EF menyusul di Fase B)
- [x] **L1**: `toggle_showcase_favorite` blok seller own-listing
      (`'Cannot favorite your own listing'`)
- [ ] Header preflight definisi ulang (MCP read pasca-deploy — sisa manual post-deploy)

### Fase B — Edge Function
- [x] **H1** (`showcase-purchase-copy`): sebelum cleanup rows, kumpulkan path
      lama (`image_url`, `image_png_path` dari generations by
      `showcase_entitlement_id`, tray lama via `ent.pack_id`) dengan pure fn
      `collectOrphanPaths()` → `storage.remove()` per bucket → baru delete rows.
      Unit test pure fn: tanpa riwayat clone / dengan PNG derivative / tray ada.
- [x] **M1-EF**: `systemRefund` decrement `purchase_count` listing
- [x] **M3-EF**: count slot EF tambah filter `is_locked=false`
- [x] **L4** (`showcase-preview`): parallelize query items `Future.all`
- [x] **L6**: test tambahan `contentTypeForExt('.gif')→image/png`,
      `extOf('user/a.b.c')→'.c'` → total Deno ≥15

### Fase C — Flutter
- [x] **H2a** (`showcase_detail_screen.dart:_load`): hapus early-return
      `isOwn` — fetch preview selalu (EF mengizinkan seller)
- [x] **H2b** (`showcase_screen.dart`): hapus filter `!l.isOwned` prefetch
- [x] **M2** (`showcase_list_form_sheet.dart` + pack detail): callback
      `onChanged` setelah save/unlist sukses → trigger
      `StickerPackDetailLoadRequested(pack.id)` + refresh state listed icon
- [x] **L9**: repo `fetchListedPackIds(): Future<Set<String>>`;
      PacksListScreen memuat set (FutureBuilder) → `PackCard(isListed:)`
      chip kecil "Listed" (l10n `packListedBadge`)
- [x] **L5**: `OwnerListingSnapshot({listingId, priceCredits, description, tags})`
      sebagai return type `fetchListingForPack` (hilangkan penyalahgunaan field)
- [x] **L3** (`showcase_cubit.dart`): `refresh({bool silent=false})` — silent
      skip emit loading; dipakai reload post-detail; error silent menjaga list
- [x] **L2**: `fetchViewerTier` retry sekali sebelum fallback 'free'
- [x] **L7**: widget test `test/pack_detail_showcase_gate_test.dart`:
      storefront icon tampil saat canRename; tier free → snackbar
      `showcasePlusRequired` (mock ShowcaseRepository via getIt)
- [x] i18n `packListedBadge` (+key lain bila perlu) en/id → gen-l10n

### Fase D — Verifikasi & Dokumentasi
- [x] deno test kedua function penuh; analyze 0 issues; flutter test;
      build apk --split-per-abi
- [x] Update PROJECT_MEMORY.md, TODO.md (SSC5 + migration 00007),
      plan progress log; catatan M4 ke draft ToS v2

## Risks
- Cleanup storage (H1) salah hapus path aktif → mitigasi: hapus HANYA path
  hasil `collectOrphanPaths()` dari baris entitlement tsb; remove dilakukan
  SEBELUM delete rows agar retry tetap aman; unit test daftar path
- Redefine RPC saat fitur belum dideploy produksi → risiko regresi user nol
- Badge Listed menambah 1 query per load packs list — skala ≤20 slot/user,
  dampak dapat diabaikan

## Progress Log
- 2026-08-26 — Review selesai: 2 HIGH, 4 MEDIUM (1 → keputusan produk), 9 LOW;
  kesesuaian inti plan ✅ dengan 3 deviasi terdokumentasi. Owner memilih:
  M4 biarkan terkunci; L9 badge diimplementasi. Plan dibuat.
- 2026-08-26 — Eksekusi dimulai (build mode).
- 2026-08-26 — SELESAI: Fase A–D tuntas. Migrasi `20260826000007` (M1/M3/L1);
  EF H1 orphan-cleanup + M1/M3 sinkron + L4 paralel; Flutter H2a/H2b/M2/L9/L5/
  L3/L2 + widget test gate (3 kasus). Verifikasi: deno 19/19 (13+6),
  analyze 0 issues, flutter test 145/145 (+3), build apk 3 ABI sukses.
  Sisa manual: deploy migration 00007 bersama 00003–00006 + preflight header.

## Notes
- Semua fix SQL = CREATE OR REPLACE → satu file migrasi cukup.
- Urutan deploy tetap 00003…00006 lalu 00007 (atau push gabungan).
- L8 (pagination browse) & analytics view sengaja di luar scope fix.
