# Showcase Sticker Pack (Credit-Based) + Tier Cap Overhaul

Created: 2026-08-25 (waktu lokal project)
Status: **DISETUJUI OWNER — implementasi berjalan**

## Objective

Fitur showcase sticker pack berbasis kredit (jalur fallback dari plan marketplace cash):
- Seller (plus-only) me-listing pack miliknya: deskripsi, tag, harga kredit 5–100.
- Buyer (free & plus) search, rate up, favorite, dan beli pack → masuk koleksi (copy-on-purchase).
- Free membayar surcharge +25% sebagai benefit plus; free tidak bisa listing.
- Ekonomi tertutup tanpa cash payout → menghindari PJP BI/WHT/KYC/PMSE seller-side.

Dokumen ini melengkapi (bukan menggantikan) `plans/2026-08-25-sticker-pack-marketplace-plan.md`.

## Keputusan Final Owner

| Aspek | Keputusan |
|---|---|
| Bagi hasil | 80% seller / 20% dibakar (sink inflasi) |
| Harga listing | Bebas 5–100 kredit |
| Harga bayar | Plus = harga dasar; Free = `ceil(dasar × 1.25)` (maks 125) |
| Cap kredit | **Free 150 / Plus 10000** (naik dari 50/200) |
| Penyimpanan cap | Helper DB `tier_cap_for(tier)` — single source of truth |
| Listing | Plus-only, maks 3 aktif/seller, pack ≥3 stiker, slot pack terkunci selama listing |
| Moderasi | Pasca-publish + report + auto-suspend setelah N laporan unik (threshold awal 3) |
| Guest | Browse saja; beli/rate/favorite/report wajib akun terautentikasi (bukan guest) |
| Slot pembeli | Pack hasil pembelian memakai slot reguler (`pack_slot_cap`) |
| Pembelian | Sekali per listing per buyer; copy-on-purchase |

## Milestones

1. Fase 0 — Migration tier cap overhaul + fix bug clamp downgrade
2. Fase 1 — Schema showcase + enum + RPC (+ CHECK sign-consistency replace)
3. Fase 2 — Edge Function copy storage + test Deno
4. Fase 3 — Flutter UI + i18n
5. Fase 4 — Legal dokumen + seed + monitoring

## Tasks

### Fase 0 — Cap & Wallet Integrity
- [x] Helper `public.tier_cap_for(tier text) RETURNS integer` (free→150, plus→10000)
- [x] Redefine `downgrade_expired_subscription()` memakai helper + **fix bug clamp**:
      saat turun tier `balance = LEAST(balance, cap_baru)` + ledger `type='expired'`
      negatif untuk selisih yang hangus (audit trail, pola fix C6)
- [x] Redefine `admin_grant_credits()` memakai helper (hapus hardcode 200/50)
      + **bonus fix runtime:** kolom `cancelled_at` ditambah aditif (sebelumnya
      RPC selalu error saat p_set_tier diisi) dan grant di-clamp ke cap
- [x] Backfill semua wallet existing per `tier_now` + default kolom `tier_cap`
- [ ] Verifikasi MCP read pasca-deploy (belum di-deploy): 0 baris over-cap;
      simulasi trigger naik/turun tier via smoke staging
- Catatan: `pack_slot_cap` (free 2 / plus 20) TIDAK diubah.

### Fase 1 — Schema & RPC
- [x] Migration enum (file TERPISAH — pelajaran surprise-me): ADD VALUE
      `showcase_purchase` (negatif) & `showcase_sale` (positif)
- [x] Migration schema: `showcase_listings`, `showcase_ratings`, `showcase_favorites`,
      `showcase_listing_reports`, `showcase_purchases`; RLS strict; GIN tags;
      kolom `sticker_generations.showcase_entitlement_id`; guard existence-join pada
      add/remove sticker, rename, delete pack; RPC SECURITY DEFINER:
      - `create_showcase_listing`, `update_showcase_listing`, `unlist_showcase_listing`
      - `search_showcase_listings`, `get_showcase_detail`
      - `toggle_showcase_rating`, `toggle_showcase_favorite`,
        `report_showcase_listing` (auto-suspend ≥3), `purchase_showcase_pack`,
        `refund_pending_showcase_purchase`
      - helper: `tier_cap_for`, `showcase_price_for`, `showcase_normalize_tags`,
        `showcase_assert_not_guest`
- [ ] Deviasi disengaja: FTS tsvector diganti ILIKE + GIN tags (skala kecil);
      FTS bisa menyusul bila volume naik
- [x] Migration replace CHECK sign-consistency `credit_transactions` untuk 2 nilai baru
      (terpisah lagi + catatan VALIDATE manual di header, pola surprise-me)
- [x] Konstanta tunable sebagai konstanta RPC terdokumentasi (surcharge 25% =
      `(base*5+3)/4`; share = `floor(base*80/100)`; suspend threshold 3)

### Fase 2 — Edge Function & Storage
- [x] Edge Function `showcase-purchase-copy`: salin WebP/PNG/tray ke path buyer via
      service-role, idempotent retry (cleanup by showcase_entitlement_id),
      auto system-refund bila slot penuh / sumber hilang
- [x] Edge Function `showcase-preview`: signed URL batch TTL 3600s; guest boleh
      listing aktif; verify_jwt=false + auth opsional in-handler
- [x] Test Deno 14 kasus (8 + 6): ext/mime mapping, path kloning, slot refund,
      row clone, kontrak env name H1, normalisasi id listing, canViewListing

### Fase 3 — Flutter
- [x] Model `ShowcaseListing`/`ShowcaseDetail`/`ShowcasePreviewUrls`, mapping enum
      CreditTxType baru (+surprise_prompt bonus)
- [x] Repository (mapping Failure: InsufficientCredits/PackSlotLimit/Auth/Server)
      + ShowcaseCubit browse
- [x] UI: browse screen (debounce search, sort chips, grid preview EF),
      detail screen (PageView item URLs, rate/fav/report RadioGroup, dialog beli
      dinamis per tier + saldo, alur owned/open-copy), form sheet owner
      (slider harga 5–100, deskripsi, tags, unlist) dengan gate plus dari
      Pack Detail storefront icon; entry Showcase dari Packs List appbar
- [x] i18n en/id lengkap (~45 key); banner "hangus di cap" ditangani via
      seller_credited/platform_burned snapshot + label riwayat (bukan banner khusus)
- [x] pubspec bump minor `0.21.0+72`

### Fase 4 — Legal & Launch
- [ ] ToS v2: lisensi non-eksklusif, indemnifikasi IP, klausul kredit tanpa nilai
      moneter/no cash-out, refund pembelian kredit 48 jam kegagalan teknis, usia
      lister; re-consent otomatis via registry versi/hash
- [ ] Report/block tampil ✓ (sudah ada); DMCA agent registration (disarankan)
- [ ] Seed konten owner + opsi harga 0; analytics view sederhana (GMV kredit,
      burn rate, top listing)

## Analisa Ringkas (dasar keputusan)

### Teknis
- Reuse preseden: FIFO consume, anti_bot_events rate-limit, FTS index, legal consent registry.
- Jebakan: ALTER TYPE ADD VALUE wajib file terpisah dari DDL pemakainya (CHECK/index/DEFAULT);
  earning di-cap via LEAST dan dicatat aktual (fix C6); copy storage ≤30 WebP (~3MB worst case).
- Guest punya wallet tapi dilarang transaksi (anti-farming bonus registrasi).

### Finansial
- Nol pendapatan langsung; nilai di retensi + konversi plus (surcharge, gate listing,
  kelangkaan slot 2 vs 20, cap 150 vs 10.000).
- Sink inflasi 20% menahan pasokan kredit misi/check-in; melindungi nilai grant plus.
- Biaya inkremental ~nol; risiko utama cold start → mitigasi seed + harga 0.

### Legal
- Tanpa payout → PJP BI/WHT/KYC tidak tersentuh; klausul "kredit tanpa nilai moneter"
  menjaga posisi ini.
- Wajib tetap: UGC report/block/moderasi/takedown <24 jam (Play policy), ToS v2 +
  re-consent otomatis, DMCA agent disarankan.
- Buyer mendapat lisensi pakai, bukan transfer hak cipta (konten AI).

## Risks

- Cold start marketplace kosong → seed owner + opsi bagikan gratis (harga 0).
- Earning hangus di cap jika UX tidak transparan → banner eksplisit; justru driver plus.
- Manipulasi rating multi-akun → dampak rendah (tanpa uang riil), acceptable.
- Play policy: kredit hanya earned (tidak dijual cash) → spending in-app aman;
  JANGAN jual kredit via payment non-Billing di masa depan.
- Bug clamp downgrade (ditemukan saat analisa, fix di Fase 0): tanpa clamp,
  plus→free dengan saldo > cap baru memicu pelanggaran CHECK `balance <= tier_cap`
  dan proses tier gagal total.

## Progress Log

- 2026-08-25 — Plan dibuat hasil analisa teknis/finansial/legal + jawaban kuesioner
  owner (split 80/20, surcharge 25%, harga bebas 5–100, moderasi pasca-publish,
  guest browse-only, slot reguler). Tambahan putaran kedua: cap free 150 / plus 10000
  via helper `tier_cap_for()`, fix bug clamp downgrade, temuan data produksi
  (15 wallet semua free, avg saldo 9.9, max 47; reward rates ±7/hari).
- 2026-08-25 — Implementasi dimulai (owner setujui, keluar plan mode).
- 2026-08-25 — Fase 0–3 selesai: 4 migrasi (00003 tier cap overhaul + bug clamp +
  fix cancelled_at admin RPC; 00004 enum; 00005 schema/RPC/guard; 00006 sign-check),
  2 Edge Functions + deno.json + config.toml, Flutter penuh (model/repo/cubit/3 UI/
  wiring/l10n ~45 key), enum kredit +3 nilai dengan filter & label. Verifikasi:
  deno 14/14, analyze 0 issues, test 142/142, APK 3 ABI sukses. Versi `0.21.0+72`.
  Semua PENDING DEPLOY — checklist di TODO.md SSC5. Sisa Fase 4 (ToS v2, seed,
  analytics) menunggu deploy + keputusan launch.

## Notes

- Semua migrasi non-destruktif (ALTER ADD / CREATE / redefine fungsi, tanpa DROP kolom data).
- Angka threshold (suspend 3 laporan, komisi 20%, surcharge 25%) hidup sebagai konstanta
  RPC/DB agar bisa diubah tanpa redeploy client.
- Referensi pola: `deduct_credit_for_sticker` (FIFO), fix C6 (ledger aktual),
  surprise-me (dialog biaya dinamis + lesson enum terpisah), reward_configs (sentralisasi).
