# TODO

## Missions Refresh + Themed Surprise-Me (2026-08-29)

Refresh layar Misi saat error jaringan + Surprise Me bertema preset musiman. Plan: `plans/2026-08-29-missions-refresh-and-themed-surprise-plan.md`. Versi `0.23.0+77`.

- [x] **MR1** Missions error view: RefreshIndicator + tombol retry (re-dispatch `MissionLoadRequested`; `_onLoad` tanpa guard, aman dari error). **Done (2026-08-29)**.
- [x] **MR2** Migrasi `20260829000001_surprise_theme.sql`: kolom `sticker_presets.surprise_theme` + 20 tema domain musiman (tanpa kosakata style agar lolos `stripStylePhrases`). **Done (2026-08-29)** — pending deploy.
- [x] **MR3** `loadPreset` +`surprise_theme` (generate-sticker mengabaikan; hanya surprise-me konsumsi); `buildSurpriseGuidance` +`theme` → "Theme requirement: MUST be about {theme}…"; handler wiring. Deno surprise-me 15/15 (+3), generate-sticker 109/109 (regresi). **Done (2026-08-29)** — pending deploy.
- [x] **MR4** Verifikasi: analyze 0, test 179/179, APK 3 ABI. **Done (2026-08-29)**.
- [ ] **MR5 (manual)** Deploy: push submodule → `supabase db push` (migrasi 20260829) → `supabase functions deploy surprise-me` + `supabase functions deploy generate-sticker` → release APK `0.23.0+77` → smoke: (a) matikan jaringan → buka Misi → pull-to-refresh/tombol retry menyala saat online; (b) pilih preset musiman → Surprise Me → ide seputar tema (mis. doodle back-to-school → ide sekolah).

## Fix "JWT issued at future" saat cold start (2026-08-28)

RCA: skew jam sementara (GoTrue/validator Supabase atau jam perangkat) → gate legal consent menampilkan error screen mentah; retry manual menyembuhkan. Tindakan (opsi 1+2 keputusan owner). Versi `0.22.2+76`.

- [x] **JW1** NEW `lib/core/errors/transient_retry.dart`: `retryOnTransient` (backoff 500ms→1s, maxRetries 2, delay injectable). Dipakai di `LegalConsentCubit._fetchStatus` → retry senyap sebelum error screen; guard `isClosed`. Hanya call read-only — submit path tidak dibungkus. **Done (2026-08-28)**.
- [x] **JW2** `safeErrorMessage` + marker `issued at` / `jwt` → bucket koneksi (pesan ramah tanpa jargon). **Done (2026-08-28)**.
- [x] **JW3** Test +6 (transient_retry 4; marker JWT 2). Verifikasi: analyze 0, test 179/179, APK 3 ABI. **Done (2026-08-28)**.
- [ ] **JW4 (manual)** Release APK `0.22.2+76`; monitor kejadian ulang — kalau masih sering: cek jam perangkat user (H2) dan Supabase status/maintenance (H1/H3); pertimbangkan deteksi clock skew device (banding `DateTime.now()` vs header `Date` respons) bila pola H2 dominan.

## Fix 4 Temuan Testing (2026-08-28)

Snackbar terhalang sheet, style injection via deskripsi, surprise-me style leak, error sensitif di UI. Plan: `plans/2026-08-27-style-strip-and-safe-errors-plan.md`. Versi `0.22.1+75`.

- [x] **F1** Snackbar preset terkunci: ScaffoldMessenger+Scaffold lokal di `preset_picker_sheet.dart` → render di dalam modal route, sheet tetap terbuka. **Done (2026-08-28)**.
- [x] **F2** Foreign-style strip (generate-sticker): helper `stripStylePhrases` + query preset aktif 1x/request; userInput `subject` di-strip sebelum prompt/reasoning; `positive` hasil reasoning di-strip ulang (fallback prompt deterministik). `text_only` sengaja tidak di-strip. Deno 109/109. **Done (2026-08-28)** — pending deploy.
- [x] **F3** Surprise-me: candidate di-strip dengan frasa SEMUA preset aktif + min-length 10 char (`prompt_too_short` → retry/failover/refund) + guidance larang menyebut style/medium/palet. Deno 12/12. **Done (2026-08-28)** — pending deploy.
- [x] **F4** Safe error messages: `lib/core/errors/safe_error_message.dart` (heuristik marker jaringan/internal → `connectionError`/`errorOccurred` terlokalisasi) diterapkan di 12 file render (legal, missions, history, home, packs×2, showcase×3, profile, auth, feedback). Flutter test 173/173 (+15). **Done (2026-08-28)**.
- [ ] **FX5 (manual)** Deploy: push submodule → `supabase functions deploy generate-sticker` + `supabase functions deploy surprise-me` (tanpa migrasi) → release APK `0.22.1+75` → smoke: (a) free tap preset terkunci → snackbar terlihat di atas sheet; (b) surprise-me → hasil tanpa frasa style; (c) matikan internet → error tampil "Tidak ada koneksi internet", tanpa URL/exception.
- [ ] **Follow-up (backlog)**: snackbar tersembunyi di balik sheet pada `add_to_pack_sheet.dart` & `sticker_feedback_buttons.dart` (kelas bug sama F1); label preset 1 kata tidak di-strip (dokumentasi risiko di plan).

## Seasonal Preset Styles (2026-08-27)

20 preset musiman Sep 2026 – Jan 2027 (5/bulan), 8 plus-only (Set A: cozy_study_club, autumn_first_leaf, witchy_potion_lab, gothic_stained_glass, november_rain_noir, woodland_sweater_club, frosted_paper_village, midnight_new_year_chrome). Plan: `plans/2026-08-27-seasonal-presets-plan.md`.

- [x] **SP1** Migrasi `20260827000001_seasonal_presets.sql`: shift sort_order +100 semua preset existing + upsert 20 preset dengan jendela UTC WIB-anchored. **Done (2026-08-27)** — pending deploy.
- [x] **SP2** `list-presets` param `?include_locked=1` (helper `allowedRolesForRequest`) + kontrak test deno 7/7; tanpa param = perilaku lama (app lama aman). `generate-sticker`/`surprise-me` tanpa perubahan (loadPreset tetap enforce 403). **Done (2026-08-27)** — pending deploy.
- [x] **SP3** Flutter: model `isSeasonal`+`isLockedFor`, repo include_locked, widget publik `preset_picker_sheet.dart` (section Seasonal + badge Limited + tanggal berakhir + tile terkunci), guard selectable penuh di home_screen, l10n EN/ID (+45 key), versi `0.22.0+74`. Verifikasi: analyze 0, test 158/158, APK 3 ABI. **Done (2026-08-27)**.
- [ ] **SP4 (manual)** Deploy: push submodule supabase → `supabase db push` (migrasi 00001) → `supabase functions deploy list-presets` → smoke app (free lihat badge+gembok & tidak bisa pilih; plus bisa pilih; generate via preset plus free → 403 dari server). Catatan: preset #1 (`back_to_school_doodle`) langsung aktif setelah deploy (jendela mulai 25 Agu 2026). Tahun depan perlu migrasi penggeser jendela + arsip manual (mis. deal_hunter_pop).

## Showcase Sticker Pack + Tier Cap Overhaul (2026-08-25)

Implementasi fitur showcase berbasis kredit + overhaul cap. Plan: `plans/2026-08-25-showcase-sticker-pack-plan.md`.

- [x] **SSC0 (Fase 0)** Migration `20260825000003_tier_cap_overhaul.sql`: helper `tier_cap_for()` (free 150 / plus 10000), fix bug clamp downgrade (`balance=LEAST` + ledger 'expired' negatif), fix runtime `admin_grant_credits` (kolom `cancelled_at` ditambah aditif + grant di-clamp ala C6), backfill wallet + default kolom. **Done (2026-08-25)** — pending deploy.
- [x] **SSC1a** Migration `20260825000004_showcase_enum_values.sql`: enum `showcase_purchase` (negatif) & `showcase_sale` (positif), file terpisah (lesson surprise-me). **Done (2026-08-25)** — pending deploy.
- [x] **SSC1b** Migration `20260825000005_showcase_schema.sql`: 5 tabel (listings/ratings/favorites/reports/purchases) + RLS strict RPC-only-write + kolom `sticker_generations.showcase_entitlement_id` + guard existence-join pada `add/remove_sticker_to_pack`, `rename_pack`, `delete_pack` + 11 RPC showcase (create/update/unlist/search/detail/toggle rating/favorite/report/purchase/refund + helper price/tags/not-guest). Harga free = ceil(dasar×1.25); split seller floor(dasar×80%) clamp tier_cap; surcharge murni sink. **Done (2026-08-25)** — pending deploy.
- [x] **SSC1c** Migration `20260825000006_showcase_sign_check.sql`: replace CHECK sign-consistency (+2 nilai baru) NOT VALID; VALIDATE manual dicatat di header. **Done (2026-08-25)** — pending deploy.
- [x] **SSC2** Edge Function `showcase-purchase-copy` (salin file tray+stiker ke folder buyer, clone generations, pack+items baru, idempotent retry via showcase_entitlement_id, auto system-refund slot penuh/sumber hilang) + `showcase-preview` (signed URL batch, guest boleh listing aktif) + deno.json + config.toml. Deno test 14/14. **Done (2026-08-25)** — pending deploy.
- [x] **SSC3** Flutter: model ShowcaseListing/Detail/PreviewUrls, repository (mapping Failure: InsufficientCredits/PackSlotLimit/Auth/Server), ShowcaseCubit browse, ShowcaseScreen (search debounce+sort chips+grid preview EF), ShowcaseDetailScreen (PageView item URLs, rate/fav/report RadioGroup, dialog beli dinamis per tier dengan saldo, alur owned/open-copy), form sheet listing owner (slider harga 5–100, deskripsi ≤500, tags ≤8, unlist) + gate plus dari PackDetail storefront icon + entry Showcase dari PacksList appbar + enum CreditTxType (surprise_prompt/showcase_purchase/showcase_sale) + label profil + filter Earnings/Spent + l10n EN/ID (~45 key). **Done (2026-08-25)**.
- [x] **SSC4** Verifikasi penuh: deno 14/14, flutter analyze 0 issues, flutter test 142/142, build apk --split-per-abi sukses (3 APK); versi `0.21.0+72`. **Done (2026-08-25)**.
- [ ] **SSC5 (manual)** Deploy checklist — progres 2026-08-26: `supabase db push` ✅ (5 migrasi 00003–00007), preflight MCP read ✅ (cap free=150 ter-backfill 15 wallet/over_cap 0; enum showcase_purchase/sale; sign-consistency **convalidated=true**; 15 RPC+helper ada; marker fix M1/M3/L1/clamp-downgrade ✅; RLS 5 tabel + policy masing-masing; kolom clone & cancelled_at; admin_grant bebas hardcode), deploy edge functions ✅ (`showcase-purchase-copy`, `showcase-preview`), VALIDATE constraint ✅. **Sisa:** smoke purchase staging via app (RPC pending → EF copy completed → export WhatsApp buyer; opsional verifikasi H1 retry-cleanup & M1 refund) → seed 2–3 pack owner untuk cold start (via akun plus owner di app — sekaligus jadi end-to-end test; atau SQL Editor manual) → ToS v2 via registry legal_consent (re-consent otomatis; klausul M4).

### Showcase Review Fixes (2026-08-26)

Hasil code review implementasi showcase. Plan: `plans/2026-08-26-showcase-review-fixes-plan.md`.

- [x] **SRF-A/B/C** Semua temuan fix selesai (H1 orphan storage, H2 own-listing preview, M1 refund stats, M2 reload after sheet, M3 slot semantics, L1/L2/L3/L4/L5/L6/L7/L9; M4 = keputusan produk tanpa kode). Verifikasi: deno 19/19, analyze 0, test 145/145, APK 3 ABI. **Done (2026-08-26)** — deploy menyatu dengan SSC5.

## Surprise Me Review Fixes (2026-08-25)

Hasil review implementasi Surprise Me AI. Plan: `plans/2026-08-25-surprise-me-review-fixes-plan.md`.

- [x] **SRF1 (Critical)** Env var salah `SUPABASE_SERVICE_ROLE` → harus `SUPABASE_SERVICE_ROLE_KEY` (`surprise-me/index.ts:266`) — semua request 500 di produksi. + test kontrak env name (butuh `--allow-read`). **Done (2026-08-25)**.
- [x] **SRF2 (High UX)** Dialog konfirmasi saat saldo 0: render "-1 credit", OK aktif → 402 belakangan. Fix: pre-check insufficient + CTA ke MissionsScreen. **Done (2026-08-25)**.
- [x] **SRF3 (Medium)** `fetchQuota` double-wrap ServerFailure→UnknownFailure. Fix: `on Failure rethrow`. **Done (2026-08-25)**.
- [x] **SRF4 (Medium)** SurpriseMeButton API mati → refactor VoidCallback, props tak terpakai dihapus. **Done (2026-08-25)**.
- [x] **SRF5 (Low)** Rate-limit snackbar generik → `surpriseWaitSeconds({seconds})` EN/ID. **Done (2026-08-25)**.
- [x] **SRF6 (Ops)** Manual VALIDATE dicatat di header migration `20260825000001` + deploy checklist SME6. **Done (2026-08-25)**.
- [x] **SRF7** Verifikasi penuh (deno 10/10 + 80/80, analyze 0, test 138/138, APK 3 ABI) + versi `0.20.1+71`. **Done (2026-08-25)**.

## Surprise Me AI Enhancement (2026-08-25)

Upgrade "Surprise me" jadi deskripsi AI via reasoning provider. Plan: `plans/2026-08-25-surprise-me-ai-enhancement-plan.md`.

- [x] **SME1** Migration: enum `surprise_prompt` + fix CHECK sign-consistency + tabel `surprise_me_history` + RPC `get_surprise_me_quota` / `charge_surprise_prompt` / `refund_surprise_prompt`. **Done (2026-08-25)** — `20260825000001_surprise_me_ai.sql`, pending deploy.
- [x] **SME2** Reuse reasoning via export langsung dari generate-sticker (deviasi dari rencana `_shared/` — lihat plan). Gate deno 80/80 lulus. **Done (2026-08-25)**.
- [x] **SME3** Edge function `surprise-me`: kuota 3 gratis/hari → charge 1 credit, style-aware preset, randomizer + avoid-list history, ≤200 char, auto-refund on failure, cooldown in-memory. Deno test 9/9. **Done (2026-08-25)** — pending deploy.
- [x] **SME4** Flutter: repository + cubit + dialog konfirmasi dinamis + loading/success/failure feedback + l10n EN/ID (10 key). Text-only mode tetap lokal. **Done (2026-08-25)**.
- [x] **SME5** Verifikasi penuh (deno 9/9 + 80/80, flutter analyze 0, test 138/138, APK 3 ABI) + versi `0.20.0+70`. **Done (2026-08-25)**.
- [ ] **SME6 (manual)** Deploy checklist — progres 2026-08-25: `supabase db push` ✅ (kedua migrasi), preflight data ✅ (0 pelanggaran via MCP read), deploy `surprise-me` + `generate-sticker` ✅. **Sisa:** manual `ALTER TABLE public.credit_transactions VALIDATE CONSTRAINT credit_transactions_sign_consistency;` di SQL Editor + patch credential Cloudflare (opsional, provider masih is_active=false).

## Surprise Me Gap Fixes (2026-08-25)

Hasil audit implementasi fitur "Surprise me". Plan: `plans/2026-08-25-surprise-me-gap-fixes-plan.md`.

- [x] **SM1 (Gap 1)** Label hardcoded `'Surprise me'` tidak memakai l10n — key `surpriseMe` sudah ada di ARB tapi widget pakai string literal (`lib/presentation/widgets/surprise_me_button.dart:30`). Fix: `AppLocalizations.of(context)?.surpriseMe`. **Done (2026-08-25)**.
- [x] **SM2 (Gap 2)** Random tanpa anti-repeat — `randomSuggestionFor()` bisa mengembalikan saran sama berturut-turut (`lib/core/constants/prompt_suggestions.dart:226`). Fix: param opsional `avoid` + injectable `Random`; `home_screen` pass teks prompt saat ini, chip pass `_current`. **Done (2026-08-25)**.
- [x] **SM3 (Gap 3)** Fallback semua saran untuk preset tanpa tag match — audit produksi: 8 preset gambar aktif tanpa coverage: `caricature`, `chibi_3d`, `lego_voxel`, `minimal_line`, `pixel_art`, `retro_sticker`, `vector_flat`, + `watercolor` (terlewat di audit awal). Plus cakupan tipis: `origami`, `stained_glass`, `neon_cyber`. Fix: tambah tag pada saran existing (semua preset kini ≥3 match) + test kontrak cakupan (31 preset ID hardcoded di test). Fallback dipertahankan sebagai safety net. **Done (2026-08-25)**.
- [x] **SM4 (Bonus)** Prefix `'Try:'` hardcoded di `PromptSuggestionChip` (pelanggaran i18n satu keluarga dengan SM1). Fix: key ARB `trySuggestion` (EN/ID) + regen l10n. **Done (2026-08-25)**.
- [x] **SM5** Verifikasi penuh + bump versi `0.19.1+69`. analyze 0 issues, test 138/138, APK 3 ABI sukses. **Done (2026-08-25)**.

## Transparent Sticker Review Findings (2026-08-01)

Hasil code review pipeline transparent WhatsApp sticker. Diurutkan kritis → rendah.

### Critical

- [x] **CR1 — WebP Encoder Missing** (`encodeWEBP()` tidak tersedia di ImageScript 1.2.15 runtime).
  - `supabase/functions/generate-sticker/index.ts:306` — memanggil `canvas.encodeWEBP()` yang tidak exist.
  - **Fix**: Beralih ke **canonical PNG asset** di server. Server meng-encode PNG lossless (512x512, transparan). WebP dihasilkan client-side saat export WhatsApp via `flutter_image_compress`. Edge Function tidak lagi memanggil `encodeWEBP()`.

- [x] **CR2 — Alpha Validation Incorrect** (false-positive pada padding non-square).
  - `supabase/functions/generate-sticker/image_processing.ts:103-144` — `inspectTransparency()` treat any `hasAlpha` sebagai pass.
  - **Fix**: `validateStrictTransparency()` dengan strict corner/ratio checks; inspection dipindah SEBELUM resize di `processStickerImage()`.

### High

- [x] **H1 — Tray Icon Not Resized Properly**
  - `supabase/functions/derive-tray-icon/index.ts:120-135` — composite decoded langsung tanpa resize.
  - **Fix**: `fit()` dengan `RESIZE_NEAREST_NEIGHBOR` sebelum composite ke canvas 96×96 transparan. Validasi dimensi dan transparent corners.

- [x] **H2 — Cache Bypass Risk (legacy opaque files)**
  - `lib/data/repositories/sticker_pack_repository.dart:439-477` — `_isValidWebpCache()` hanya cek VP8X/VP8L capability, bukan actual transparency.
  - **Fix**: Validasi WebP lengkap saat cache write (dimensi, alpha, ukuran, transparent corners). Atomic write via temp file + rename. Error propagation bukan swallow.

- [x] **H3 — Style Descriptor Conflicts** (deskripsi minta `dark/white background`, `white border`)
  - `supabase/migrations/20260701000001_add_15_new_presets.sql:36-37`, `20260702000012_typography_presets.sql:99-104`
  - **Fix**: `sanitizeVisualGuidance()` strip conflicting background/border dari prompt.

- [x] **H4 — 100KB Limit Not Enforced** (upload tetap lanjut walau oversize)
  - `supabase/functions/generate-sticker/index.ts:346-355` — `encodeWebPWithinLimit()` return lowest quality walau >100KB.
  - **Fix**: Server-side PNG canonical (tidak ada batas 100KB di server). Client-side WhatsApp export enforce 100KB via quality loop, reject jika semua quality gagal.

### Medium

- [x] **M1 — PNG Derivative Non-Fatal** (upload PNG boleh gagal)
  - `supabase/functions/generate-sticker/index.ts` — PNG upload failure non-fatal.
  - **Fix**: PNG canonical upload wajib fatal. Single PNG asset dipakai untuk `image_url` dan `image_png_path`.

- [x] **M2 — Native-Transparent Branch Skip Outline/Quality Gates**
  - `supabase/functions/generate-sticker/image_processing.ts:393-405` — early return tanpa outline/gates.
  - **Fix**: `validateStrictTransparency()` + `addWhiteOutline()` pada SEMUA branch accepted.

---

## Code Review Findings (2026-07-09)

Hasil review menyeluruh (Flutter + Supabase), diurutkan kritis → rendah. Temuan baru ditambah di review kedua setelah fix C1-C3, H2.

### Critical

- [x] **C1 — Fitur "share to earn" mati total + reward salah sasaran (`auth.uid()` NULL di service-role).**
  - `supabase/migrations/20260706114120_share_tokens_and_rpcs.sql:221` — `consume_share_token` (dipanggil Edge Function `share-redirect` via service-role) memanggil `complete_mission()` yang memberi reward ke `auth.uid()`. Di konteks service-role tidak ada JWT end-user → `auth.uid()` NULL → `RAISE 'Not authenticated'` → rollback → sharer tak pernah dapat kredit.
  - Cacat desain: andai tak NULL pun, kredit jatuh ke **pembuka link** (`auth.uid()`), bukan **pemilik token** (`v_token_row.user_id`).
  - **Done (2026-07-08)**: migrasi `supabase/migrations/20260708000024_reward_integrity_fixes.sql` menambah `complete_mission_for_user(p_user_id, p_mission_id)` (service_role only), dan `consume_share_token` kini memanggilnya dengan `v_token_row.user_id`.

- [x] **C2 — `complete_mission` bisa dipanggil langsung untuk self-grant kredit (bypass iklan & share).**
  - `supabase/migrations/20260702000013_fix_recurring_mission_limit.sql:95-99` (grant `:169`) — `GRANT ... TO authenticated` + validasi `ad_reward`/`share_app`/`daily_login` = `NULL`. User (termasuk guest anonymous, role `authenticated`) bisa `POST /rest/v1/rpc/complete_mission` dengan mission id → kredit tanpa nonton iklan / tanpa share. Hanya dibatasi cooldown/daily-limit.
  - **Done (2026-07-08)**: `complete_mission` di migrasi `20260708000024` kini `RAISE EXCEPTION` untuk `validation_type IN ('ad_reward','share_app')`. Reward untuk kedua tipe itu hanya lewat jalur service-role (`complete_mission_for_user`): share via token (C1), ad via AdMob SSV (lihat H2).

- [x] **C3 — `claim_daily_checkin` menerima jumlah reward dari client + tanpa tier cap.**
  - `supabase/migrations/20260702000014_daily_checkin_streak.sql:79-82,118-125` — reward = parameter `p_reward_per_day`/`p_bonus_on_completion` dari client; wallet `balance = balance + v_reward` tanpa `LEAST(...,tier_cap)`. Client jahat `claim_daily_checkin(1000000,1000000)` → inflasi kredit arbitrer.
  - **Update**: migrasi `20260708000023_reward_config_sentralisasi.sql` (sudah ada sebelum review ini) sudah men-drop signature dengan parameter dan membaca reward dari `reward_configs` — vektor "reward dari client" sudah tertutup. Sisa bug: 3 update wallet masih `balance + v_reward` tanpa cap.
  - **Done (2026-07-08)**: migrasi `20260708000024_reward_integrity_fixes.sql` mengganti ketiga update tersebut jadi `LEAST(balance + v_reward, v_tier_cap)`.

### High Priority

- [ ] **H1 — `.env` ikut dibundel ke APK/IPA dan memuat `ANTI_BOT_HASH_SALT`.**
  - `pubspec.yaml:59` mendaftarkan `.env` sebagai asset; `ANTI_BOT_HASH_SALT` (server-only, dipakai `supabase/functions/generate-sticker/index.ts:1332`) ikut ter-bundle → bisa diekstrak dari APK, pseudonimisasi IP anti-bot runtuh.
  - `SUPABASE_SERVICE_ROLE_KEY` saat ini kosong di `.env` — pertahankan.
  - **Fix**: `.env` bundel cukup nilai publik (Supabase URL + anon key, AdMob IDs, Google web client id). Pindahkan `ANTI_BOT_HASH_SALT` ke Supabase secrets saja.

- [x] **H2 — Rewarded ad tanpa Server-Side Verification (SSV).**
  - `lib/presentation/blocs/mission/mission_bloc.dart:317-368` — client klaim `rewardEarned` lalu panggil `complete_mission` (lihat C2). Reward murni client-claimed.
  - **Done (2026-07-08)**: Edge Function baru `supabase/functions/admob-ssv/index.ts` (verify_jwt=false) memverifikasi signature ECDSA dari Google verifier-keys, dedup via tabel `ad_ssv_events`, lalu panggil `complete_mission_for_user`. `RewardedAdRepository.loadAndShow` kini set `ServerSideVerificationOptions(customData: {userId, missionId})` sebelum `show()`. `MissionBloc._onWatchAd` tidak lagi memanggil `completeMission` client-side — polling `fetchUserProgress` singkat (5× @2s) untuk deteksi grant SSV yang landing async.
  - **Pending (manual, di luar repo)**: set callback URL Edge Function di AdMob Console (Rewarded ad unit → Server-side verification), lalu uji dengan real device untuk memastikan format signature (DER vs raw) sesuai — lihat komentar di `admob-ssv/index.ts`.

### Medium Priority

- [ ] **M1 — Tidak ada validasi environment variable** (langgar aturan CLAUDE.md poin g). `lib/core/constants/env_constants.dart:9-11` fallback diam ke `''`. Tambah fail-fast di bootstrap (`main.dart` / `SupabaseBootstrap.init`).
- [ ] **M2 — Banner ad di-request untuk user tidak eligible (Plus/guest).** `lib/presentation/widgets/ads_banner_widget.dart:32-39` — `_isEligible` default `true` → `_loadAd()` selalu jalan; cek eligibilitas baru di post-frame. Gate `_loadAd()` di belakang hasil cek.
- [ ] **M3 — Eligibilitas ad tidak reaktif** terhadap upgrade Plus; widget tidak dengar `SubscriptionBloc`. Tambah `BlocListener` untuk dispose ad saat `isPlus` berubah.
- [ ] **M4 — God classes (SRP)**: `home_screen.dart` 1336 baris, `profile_screen.dart` 829, `missions_screen.dart` 701, `pack_detail_screen.dart` 683. Ekstrak sub-widget.

### Low Priority

- [ ] **L1** — `print()` alih-alih `debugPrint`/logging di `lib/core/services/share_mission_service.dart:108` (ikut ke log rilis).
- [ ] **L2** — Cabang menyesatkan `pathSegments.first == 'r'` di `_maybeBuildClaim` (`share_mission_service.dart:121-127`); app hanya associate `/share-claimed/`, token bisa salah diparse sebagai `missionId`.
- [ ] **L3** — `lib/data/repositories/mission_repository.dart:53-64`: `complete_mission` + SELECT terpisah (2 round-trip, race). Sebaiknya RPC me-return baris progress.
- [ ] **L4** — Coverage test tipis: tak ada test MissionBloc share-flow, auth, repositories, atau RPC kritis. Pertimbangkan test pgTAP/integrasi untuk RPC kredit (C1–C3).
- [ ] **L5** — i18n: string error share hardcoded English di `mission_bloc.dart:426-441` (langgar aturan CLAUDE.md poin l).

### Verifikasi (setelah fix C1–C3, H2)
- `supabase db push` untuk apply `20260708000024_reward_integrity_fixes.sql`.
- `supabase functions deploy admob-ssv`.
- C1: buka link share end-to-end → **pemilik token (sharer)** menerima kredit (cek `credit_transactions`), bukan pembuka link; ulangi dalam cooldown 24 jam → ditolak.
- C2 (share): dengan JWT user biasa, `select complete_mission('<share_app mission id>')` → harus error `Mission share_app must be verified server-side`.
- C2 (ad): idem untuk mission `ad_reward` → error serupa. Nonton rewarded ad sungguhan di device (setelah callback URL diset di AdMob Console) → kredit bertambah via SSV, bukan langsung.
- C3: set saldo user = `tier_cap`, lalu `claim_daily_checkin()` → tidak error (no `balance_cap` violation), saldo tetap di cap, progress tetap tercatat.
- H1: build APK release, `unzip` → `.env` tidak memuat salt/secret server.
- M2: login Plus → tidak ada ad request (cek log AdMob/network).
- `flutter analyze`.

## Code Review Findings (2026-07-09) — Review 2: Full Coverage (Flutter + Supabase)

### Critical (NEW)

- [x] **C4 — Guest-to-registered migration mati total (`auth.uid()` NULL di service-role).**
  - **Done (2026-07-09)**: `create-guest-migration/index.ts` beralih `service.rpc()` jadi `userClient.rpc()` agar `auth.uid()` = guest user. `migrate-guest-stickers/index.ts` juga beralih `userClient.rpc()` agar `auth.uid()` = registered target user. Storage copy dijalankan SEBELUM RPC (sehingga jika copy gagal, token tidak terkonsumsi). WebP utama jadi required copy; PNG/tray best-effort.
  - **Risiko residual**: `migrate_guest_stickers` RPC masih `SECURITY DEFINER` + `GRANT TO authenticated`, tapi dilindungi token hash + expiry + consumed guard. Tidak ada perubahan schema RPC.

- [x] **C5 — `create-guest-migration` response parsing salah untuk RPC `RETURNS TABLE`.**
  - **Done (2026-07-09)**: `const rows = Array.isArray(data) ? data : [data]; const row = rows[0]` di kedua Edge Function. Juga ada error 500 jika `migration_token` missing.

- [x] **C6 — `grant_monthly_credits` ledger mencatat full grant tanpa cek sisa cap (financial inflation).**
  - **Done (2026-07-09)**: migrasi `20260709000025_fix_monthly_grant_ledger.sql` — hitung `v_actual_grant := v_new_balance - v_rec.balance`, hanya insert ledger jika `> 0`. Jika cap penuh, `last_grant_at` tetap di-update agar tidak retry bulan ini.

- [x] **C7 — `credit_transactions` perlu constraint `amount <> 0` + consistency sign per type.**
  - **Koreksi dari Review 1**: `type` sudah ENUM (`transaction_type`) sejak init_schema — nilai: `topup`, `daily_reward`, `generate_sticker`, `refund`, `subscription_grant`, `mission_reward`, `expired`, `locked`. `amount > 0` saja salah karena `generate_sticker` pakai amount negatif.
  - **Done (2026-07-09)**: migrasi `20260709000026_fix_credit_tx_constraints.sql` — tambah `CHECK (amount <> 0)` dan `CHECK` sign consistency (reward/grant/refund/topup positive, `generate_sticker` negative, `expired`/`locked` any sign). Semua `NOT VALID`; perlu `VALIDATE CONSTRAINT` manual setelah preflight data bersih.

### High Priority (NEW)

- [ ] **H3 — `admob-ssv` pakai best-effort insert `ad_ssv_events` tanpa transaksi atomic dengan grant.**
  - `supabase/functions/admob-ssv/index.ts:200-236` — Grant via `complete_mission_for_user` RPC, LALU insert `ad_ssv_events`. Jika insert gagal (misal duplicate `transaction_id`), grant sudah terlanjur terjadi dan Google retry → double grant.
  - `supabase/migrations/20260708000024_reward_integrity_fixes.sql:488-490` — `ad_ssv_events` punya `UNIQUE (transaction_id)`, tapi insert dilakukan di edge function setelah RPC.
  - **Fix**: balik urutan: insert `ad_ssv_events` dulu (atomik, catch duplicate), lalu grant. Atau jadikan satu RPC `consume_ad_reward` yang atomic INSERT + grant dalam satu transaksi.

- [x] **H4 — `grant_registered_bonus` masih bergantung `auth.uid()` tapi dipanggil dari RPC service-role (OBSOLETE setelah C4 fix — 2026-07-09).**
  - **Status**: tidak perlu di-fix karena `migrate-guest-stickers` sekarang panggil RPC via `userClient.rpc()` (bukan service-role). `auth.uid()` di dalam RPC sekarang merujuk ke registered user yang legitimate. Bonus registrasi berjalan normal.
  - **Proof**: `supabase/functions/migrate-guest-stickers/index.ts:218` (C4 fix) sekarang `await userClient.rpc("migrate_guest_stickers", ...)` yang membuat SQL `auth.uid()` = target registered user. `grant_registered_bonus()` di SQL line 230 menerima `auth.uid()` bukan NULL.

- [ ] **H5 — AdMob App ID iOS/Android hardcoded test ID; env `ADMOB_APP_ID` tidak dipakai.**
  - `android/app/src/main/AndroidManifest.xml:15-17` — `com.google.android.gms.ads.APPLICATION_ID` = test ID.
  - `ios/Runner/Info.plist:69-70` — `GADApplicationIdentifier` = test ID.
  - `lib/main.dart:20-24` — comment bilang app ID dari env, tapi manifest/plist tetap test ID.
  - Efek: production APK/IPA akan pakai test ID → AdMob tidak serve real ads → revenue 0.
  - **Fix**: gunakan manifest placeholder `${adMobAppId}` + `productFlavors` di Gradle/Xcode; hapus dari `.env` runtime.

- [x] **H8 — Rewarded ad unit ID di env salah menggunakan banner test ID.**
  - `.env` — `ADMOB_REWARDED_ANDROID` dan `ADMOB_REWARDED_IOS` diisi `6300978111` (banner test ID).
  - Akibat `AdConfigService.rewardedAdUnitId()` melihat env tidak kosong → pakai value tersebut → `RewardedAd.load()` error code 3 "Ad unit doesn't match format".
  - **Done (2026-07-09)**: diganti dengan rewarded test ID (`5224354917` Android, `1712485313` iOS).

- [ ] **H6 — `getPublicUrl` dipakai untuk avatar di bucket private.**
  - `supabase/migrations/20260701000008_profile_avatar_bucket.sql:5-6` — bucket `avatars` dibuat dengan `public = false`.
  - `lib/presentation/screens/profile/profile_screen.dart:166` — `storage.from('avatars').getPublicUrl(...)` dipakai untuk display avatar.
  - Efek: di bucket private, `getPublicUrl` mungkin tetap generate URL yang readable (tergantung RLS), tapi kontrak bucket tidak sesuai. Jika bucket policy berubah, avatar broken.
  - **Fix**: set bucket `public = true` (avatar memang seharusnya public), atau pakai `createSignedUrl`.

- [ ] **H7 — `list-presets` edge function baca data pakai service-role tanpa validasi RLS.**
  - `supabase/functions/list-presets/index.ts:52-83` — Semua query (`user_subscriptions`, `sticker_presets`) menggunakan service-role client. Output memang difilter by role, tapi bug filter bisa leak preset Plus/terbatas.
  - Risiko rendah karena `style_descriptor` tidak di-expose, tapi tetap.
  - **Fix**: (1) query subscription pakai user-scoped client dengan JWT asli agar RLS aktif; (2) query preset via SECURITY DEFINER view yang enforce role otomatis.

### Medium Priority (NEW)

- [x] **M5 — `claim_daily_checkin` 3 update wallet identik tanpa `LEAST(...)` di jalur baru (wallet SQL tidak error, tapi ledger bisa overshoot).**
  - **Done (2026-07-08)**: migrasi `20260708000024` sudah menggunakan `LEAST(balance + v_reward, v_tier_cap)`. Tapi `reference_id` reintroduce bug UUID (M11). Sekarang juga fixed.

- [ ] **M11 — `claim_daily_checkin` reintroduce reference_id TEXT ke kolom UUID (regression dari C3 fix).**
  - `supabase/migrations/20260708000024_reward_integrity_fixes.sql:398-399,429-430,468-469` — 3 insert `credit_transactions` menyertakan `reference_id = 'daily_checkin_day_N'` (TEXT) ke kolom UUID.
  - Error: `column "reference_id" is of type uuid but expression is of type text`.
  - Fix sama seperti `20260702000015_fix_daily_checkin_reference_id.sql`: hapus `reference_id` dari 3 insert.
  - **Done (2026-07-09)**: migrasi `20260709000027_fix_daily_checkin_reference_id.sql`.

- [ ] **M6 -- `soft_delete_account` RPC tidak hapus session/refresh token.**
  - `supabase/migrations/20260701000007_user_profiles.sql:61-77` — Soft delete hanya update `user_profiles.is_deleted = true` dan `sticker_packs.is_deleted = true`. Tidak revoke JWT/refresh token di Supabase Auth.
  - User bisa lanjut pakai app sampai token expired (1 jam). CLI/sesi lain tetap aktif.
  - **Fix**: tambah `UPDATE auth.sessions SET revoked = true WHERE user_id = auth.uid()` (jika ada akses ke `auth` schema dari SECURITY DEFINER), atau minta client sign out setelah soft delete.

- [ ] **M7 — `AdsBannerWidget` request ad sebelum cek eligibilitas (post-frame).**
  - `lib/presentation/widgets/ads_banner_widget.dart:32-39` — `_isEligible` default `true`, `_loadAd()` dipanggil di `initState`. Post-frame callback baru update `_isEligible`.
  - Efek: ad request terbuang untuk Plus/guest. Cost kecil (impression tidak dihitung), tapi waste bandwidth + log noise.
  - **Fix**: pindah `_loadAd()` ke dalam `_checkEligibility` callback.

- [ ] **M8 — `AdsBannerWidget` tidak reaktif terhadap upgrade Plus.**
  - `lib/presentation/widgets/ads_banner_widget.dart:41-55` — Eligibilitas dicek sekali di `initState`. Jika user upgrade Plus, banner tetap tampil sampai widget rebuild (pop/re-push screen atau manual refresh).
  - `lib/app.dart:200-212` — `SubscriptionBloc` listener hanya refresh packs, bukan dispose banner.
  - **Fix**: tambah `BlocListener<SubscriptionBloc>` atau pass `isEligible` dari parent via parameter.

- [ ] **M9 — Edge function `derive-tray-icon` dan `list-presets` tidak terdaftar di `config.toml`.**
  - `supabase/config.toml` — hanya `generate-sticker`, `share-redirect`, `admob-ssv` yang terdaftar. `derive-tray-icon`, `list-presets`, `create-guest-migration`, `migrate-guest-stickers` tidak ada entry.
  - Efek: `supabase functions serve` lokal tidak serve function-function ini (kecuali invoke via explicit URL). Deploy mungkin tetap jalan tapi tanpa konfigurasi `verify_jwt`.
  - **Fix**: daftarkan di `config.toml` sesuai kebutuhan.

- [ ] **M10 — God classes/SRP (lanjutan M4).**
  - Konfirmasi ukuran: `home_screen.dart` ~1336 baris, `profile_screen.dart` ~829, `missions_screen.dart` ~701, `pack_detail_screen.dart` ~683, `sticker_pack_bloc.dart` ~420+, `generate-sticker/index.ts` ~1729 baris.
  - Bloc besar (>300 baris) juga perlu dipecah.
  - **Fix**: ekstraksi bertahap — screen menjadi widget-section, bloc dipisah per domain logic.

### Low Priority (NEW)

- [ ] **L6 — `executeQuery` tidak ada; search history `replaceAll` escape mungkin tidak kompatibel dengan PostgREST `ilike`.**
  - `lib/data/repositories/sticker_repository.dart:159-166` — Escape `\` untuk `%`, `_` manual. PostgREST `ilike` menggunakan `\` sebagai escape char secara default, jadi harusnya OK. Tapi belum di-test dengan literal `%` atau `_` di prompt.
  - **Fix**: tambah unit test dengan input mengandung `%` dan `_`.

- [ ] **L7 — Hardcoded App Store ID di `share-redirect`.**
  - `supabase/functions/share-redirect/index.ts:30` — `IOS_APP_STORE = "https://apps.apple.com/app/id000000000"` — placeholder belum diisi ID asli.
  - Efek: iOS user di-redirect ke App Store invalid saat tap share link yang error.

- [ ] **L8 — Error/success messages masih hardcoded English di mission_bloc.**
  - `lib/presentation/blocs/mission/mission_bloc.dart:421,448-462` — `_shareErrorMessage`, `'Failed to prepare share: $err'`.
  - Melanggar prinsip i18n (l10n sudah setup via `flutter_localizations` + `app_localizations_*.dart`).
  - **Fix**: gunakan `context.read<AppLocalizations>()` atau emit error code + resolve di UI layer.

- [ ] **L9 — `ShareMissionService._maybeBuildClaim` parse `/r/<token>` path sebagai share-claim.**
  - `lib/core/services/share_mission_service.dart:126` — `uri.pathSegments.first == 'r'` akan memicu `ShareClaimResult.fromUri` yang parsing token sebagai `missionId`.
  - `android/app/src/main/AndroidManifest.xml:39-45` — App Link hanya untuk `/share-claimed/`, bukan `/r/`.
  - Efek: deep link `/r/<token>` (yang dikirim via share sheet) tidak akan buka app; browser handle sendiri via CDN → redirect ke Edge Function. Tapi jika user buka link langsung di device yang terinstall appnya, Universal/App Link tidak matching → browser fallback. Flow tetap jalan via CDN → Edge Function → redirect ke `/share-claimed/<id>` → App Link.

### Additional Verifikasi Items
- Build APK release, `unzip -l` cek asset `.env` tidak memuat `ANTI_BOT_HASH_SALT`.
- Test end-to-end guest-to-registered migration: sign in anonymous → generate 3 sticker → create migration token → sign up with Google → cek stickers + packs pindah.
- `supabase functions serve` lokal untuk test `list-presets`, `derive-tray-icon`, `admob-ssv`.
- Test RPC `grant_monthly_credits` manual: set balance = cap-2, grant 5, cek ledger = 2, balance = cap.
- `flutter analyze` dan `flutter test`.

## Cloudflare Workers AI Provider

- [x] Fase 0 — Spike REST contract live (2026-08-24): flux-1-schnell=200 JSON `result.image` b64 JPEG; sdxl/dreamshaper=200 binary PNG; error `{success:false,errors:[{code,message}]}`; **flux menolak `negative_prompt`** (400 code 5006) → adapter pakai allowlist param per model family.
  - `plans/2026-08-24-cloudflare-workers-ai-provider-plan.md`; `.env.example` blok Cloudflare.
- [x] Fase 1 — Core `cloudflare` text-to-image (selesai implementasi + review remediation):
  - Migration `20260824000001_add_cloudflare_provider.sql`: CHECK `cloudflare`, seed 3 rows **priority 5 (last-resort), `is_active=false`**, fallback `always`, timeout 90s, idempotent.
  - `index.ts`: `ProviderName+="cloudflare"`, `callCloudflare()` (JSON base64 sniff magic bytes + binary), `buildCloudflareRequestBody()` allowlist per family, guard img2img/inpainting, case dispatcher.
  - Test: 10 test baru, total deno 80/80 lulus; flutter analyze 0 issues; flutter test 133/133.
  - **Pending manual**: `supabase db push` → patch SQL (base_url account id real + api_key + `is_active=true`) → `supabase functions deploy generate-sticker`.
- [ ] Fase 2 — Perluasan text-to-image (`sdxl-lightning`, `flux-2-klein-4b`) — **klein butuh multipart** (doc minim); live-test schema dulu sebelum seed, atau extend guard.
- [ ] Fase 3 — img2img (`@cf/runwayml/stable-diffusion-v1-5-img2img`) & inpainting (`@cf/runwayml/stable-diffusion-v1-5-inpainting`) — butuh `image_b64`+`mask` + kontrak Flutter baru (defer; adapter sudah guard `model_requires_input_image`).
- [ ] Fase 4 — Verifikasi produksi: cek `image_generation_provider_attempt_analytics` menampilkan baris cloudflare setelah aktivasi; promosi prioritas via `UPDATE priority` tanpa redeploy.

## Critical

- [x] Add `.env` ignore rules before committing.
  - Current `git status` shows `.env` as untracked.
  - Add `.env`, `.env.*`, and `!.env.example` to `.gitignore`.
  - Ensure Flutter client `.env` only contains `SUPABASE_URL` and `SUPABASE_ANON_KEY`; never include `SUPABASE_SERVICE_ROLE_KEY` or `OPENROUTER_API_KEY`.
  - **Done (2026-06-07)**: rules added in `.gitignore` (lines 122-124), plus Supabase local artifacts, cross-platform OS metadata, FVM, build artifacts, and signing material (lines 127-160). `pubspec.lock` explicitly tracked. Verified via `git check-ignore`.

- [x] Harden `deduct_credit_for_sticker` RPC ownership checks.
  - `supabase/migrations/20260505000001_init_schema.sql` exposes a `SECURITY DEFINER` RPC with caller-supplied `p_user_id`.
  - Validate `p_user_id = auth.uid()` inside the function, or remove `p_user_id` and derive the user from `auth.uid()`.
  - Keep the atomic wallet lock, sticker row insert, and ledger insert behavior intact.
  - **Done (2026-06-07)**: new migration `supabase/migrations/20260505000004_deduct_credit_user_scope.sql` drops the 4-arg overload, recreates as 3-arg with `v_user_id := auth.uid()` + `IS NULL` guard. Edge function caller in `index.ts` updated in lockstep (no more `p_user_id` in RPC payload). `userId` still kept locally for the storage path.

## High Priority

- [x] Fix nullable field clearing in `AuthBlocState.copyWith`.
  - `lib/presentation/blocs/auth/auth_bloc.dart` currently uses `field ?? this.field`.
  - This prevents intentionally clearing `user`, `errorMessage`, and `infoMessage`.
  - Use explicit clear flags, sentinel values, or a more explicit state model.
  - **Done (2026-06-07)**: applied `Object()` sentinel pattern in `auth_bloc.dart` (`static const Object _undefined = Object()`). Omitted param = keep current value; explicit `null` = overwrite. All existing callers still work without modification.

- [x] Update README paths after moving Flutter app to the repository root.
  - Replace references to `bikin_stiker/lib`, `bikin_stiker/.env`, and `cd bikin_stiker`.
  - Update repository layout so `lib/`, `android/`, `ios/`, `test/`, and `pubspec.yaml` are shown at root.
  - **Done (2026-06-07)**: layout, setup, and running sections in `README.md` rewritten for root-based structure. Migrations table extended with the `20260505000004_*` row.

- [x] Hoist `HistoryBloc` to `app.dart` for state retention (not in original TODO; raised during init-session code review).
  - Per-screen `BlocProvider` in `HistoryScreen` discarded the list + signed-URL cache on every open.
  - **Done (2026-06-07)**: `HistoryBloc` moved into `app.dart`'s `MultiBlocProvider` (lazy). `HistoryScreen` converted to `StatefulWidget`; `HistoryRefreshed` dispatched once in `initState`. Added `HistoryCleared` event, dispatched in `_AuthGate` listener on signout to prevent cross-user data leak via retained state.

## Medium Priority

- [x] Avoid creating signed URLs inside history item builds.
  - `lib/presentation/screens/history/history_screen.dart` calls `signedUrlForPath` in a `FutureBuilder`.
  - Move signed URL resolution/caching into `HistoryBloc` or `StickerRepository`.
  - Avoid repeated signed URL requests during rebuilds and list scrolling.
  - **Done (2026-06-07)**: `StickerRepository.signedUrlForPath` backed by `Map<String, Future<String?>> _signedUrlCache` + private `_fetchSignedUrl`. Repeated calls for the same path share one in-flight `Future`. 1h cache TTL matches server. Concurrent calls deduplicated.

- [x] Add local validation before sticker generation submission.
  - Add client-side guards for empty prompt, max prompt length, and known preset IDs in BLoC/repository.
  - **Done (2026-06-26)**: implemented empty prompt, max-length, and preset whitelist validation in `_onGenerate()`.

- [x] Remove silent error swallow in `_fetchSignedUrl`.
  - **Done (2026-06-26)**: `_fetchSignedUrl` now throws `GenerationFailure`; history thumbnails show an error placeholder for signed URL failures.

- [x] Use `CachedNetworkImage` consistently in generated sticker result UI.
  - **Done (2026-06-26)**: `_ResultPanel` now uses `CachedNetworkImage` with loading and error widgets.

- [x] Smooth wallet loading indicator on re-login.
  - **Done (2026-06-26)**: low-credit warning is suppressed while wallet state is loading.

- [x] Improve `_AuthGate` for `AuthStatus.submitting`.
  - **Done (2026-06-26)**: submitting state keeps `AuthScreen` mounted and displays a loading overlay.

- [x] Review untracked project files before first commit.
  - Decide whether `.idea/`, `.metadata`, `.flutter-plugins-dependencies`, and `bikin_stiker.iml` should be tracked.
  - Keep generated/cache files out of Git unless they are intentionally required.
  - **Done (2026-06-07)**: covered by the new `.gitignore` entries (`.claude/`, `.idea/`, `.metadata`, `*.iml`, `*.iws`, `*.ipr`, `.fvm/`, `fvm_config.json`, `.flutter-plugins-dependencies`, plus Supabase local artifacts and signing material). `pubspec.lock` explicitly kept tracked for reproducible builds.

## Tests And Verification

- [ ] Add focused tests for auth state transitions.
  - Cover sign-in failure, sign-up info message, sign-out user clearing, and stale snackbar prevention.

- [ ] Add tests around sticker generation error mapping.
  - Cover insufficient credits, malformed function response, and generic function failures.

- [x] Add a contract check for preset IDs across Dart and the Supabase edge function.
  - **Done (2026-06-26)**: test parses the `PRESETS` object from `supabase/functions/generate-sticker/index.ts` and compares it with `kStickerPresets`.

- [ ] Run manual verification after fixes.
  - `flutter analyze`
  - `flutter test`
  - `supabase db reset`
  - Local edge function failure-path test with an invalid OpenRouter key to confirm refunds.
  - C1 regression check: `SELECT deduct_credit_for_sticker(1, 'kawaii', 'pwn');` while authenticated as user A should ERROR with "Not authenticated" (proves the old cross-user deduction vector is closed).

## Anti-Bot

- [x] Phase 1 + 2: Server-side rate limiting and submission lock for generate-sticker.
  - Added `anti_bot_events` table for telemetry (allowed + blocked).
  - Added `anti_bot_generation_locks` table to prevent parallel generation per user.
  - Added RPCs `acquire_generation_lock` and `release_generation_lock`.
  - Edge Function now checks cooldown (20s), rolling window (10/10min), daily cap (50/day), and IP cap (30/10min) before deduct credits.
  - Edge Function acquires lock before generate, releases on success/failure.
  - Flutter client maps HTTP 429 → `RateLimitedFailure` and 409 → `GenerationInProgressFailure`.
  - UI shows specific messages with retry timer for rate-limited and in-progress states.
  - **Done (2026-06-27)**: migration `20260627000006_anti_bot_rate_limit.sql`, Edge Function `index.ts`, `failures.dart`, `sticker_repository.dart`, `home_screen.dart`.

- [ ] Phase 3: Add adaptive first-party challenge for suspicious generation requests.
  - Add `anti_bot_challenges` table with one-time challenge records.
  - Add `anti-bot-challenge` Edge Function to issue nonce + difficulty.
  - Implement proof-of-work verification in `generate-sticker`.
  - Require challenge only for suspicious users/IP/device, not every normal request.
  - Return `428 Precondition Required` when challenge is required.
  - Client side: add challenge request + PoW solver (add `crypto` package).
  - Add `ChallengeRequiredFailure` to `failures.dart`.
  - Update `StickerGenBloc` to auto-request challenge and retry generate.
  - Add Flutter secure storage for installation ID.

- [ ] Phase 4: Harden signup abuse protection.
  - Enable email confirmation in Supabase Auth (`enable_confirmations = true`).
  - Move starter credit issuance behind verified-email status (update wallet trigger).
  - Log signup-related anti-bot events by IP hash / device hash.
  - Add signup rate-limit policy (per IP, per window).
  - Review starter credit amount after abuse telemetry is available.
  - Consider adding `email_verified` column to `user_wallets` or check `auth.users.email_confirmed_at`.

## Guest Flow

- [x] Phase 1: DB-driven provider failover.
  - Created migration `20260626000005_image_generation_failover.sql` with `image_generation_configs`, `provider_overrides`, `sticker_generation_attempts`, and `sticker_metadata` tables.
  - Refactored Edge Function for provider failover with retry/fallback and attempt logging.
  - Added provider metadata on sticker rows.
  - **Done (2026-06-26)**.

- [x] Phase 2: Anti-bot rate limit + submission lock.
  - Created migration `20260627000006_anti_bot_rate_limit.sql` with `anti_bot_events` and `anti_bot_generation_locks` tables.
  - Added RPCs `acquire_generation_lock` and `release_generation_lock`.
  - Edge Function checks rate limits before credit deduction.
  - Flutter client maps HTTP 429 → `RateLimitedFailure` and 409 → `GenerationInProgressFailure`.
  - **Done (2026-06-27)**.

- [x] Phase 3: Guest anonymous account flow.
  - Created `LegalConsentRepository` for Terms/Privacy acceptance storage.
  - Created `LegalConsentScreen` with AdMob disclosure.
  - Updated `AuthRepository` with `signInAnonymously()`, `upgradeAnonymousAccount()`, `grantRegisteredBonus()`.
  - Updated `AuthBloc` with `AuthAnonymousRequested`, `AuthUpgradeAnonymousRequested`.
  - Updated `_AuthGate` flow for terms → anonymous session → guest/registered.
  - Created migration `20260627000007_guest_registered_credits.sql` with default 1 credit for all users, `grant_registered_bonus()` RPC.
  - Updated `AuthScreen` with `AuthScreenMode.guestAuthWall` mode.
  - Updated `HomeScreen` for guest mode with locked save/share and `_GuestResultCta`.
  - **Done (2026-06-27)**.

- [ ] Phase 4: Terms/Privacy content.
  - Add legal content for Terms of Service and Privacy Policy.
  - Include AdMob disclosure for planned monetization.
  - Include credit difference disclosure (1 guest vs 5 registered).
  - **Pending**.

- [ ] Phase 5: Save/Share to WhatsApp.
  - Implement download/save to gallery functionality.
  - Implement share to WhatsApp with sticker format.
  - **Pending**.

- [ ] Phase 6: AdMob integration.
  - Add Google AdMob SDK.
  - Implement banner ads for guest users.
  - Implement interstitial ads for registered users (optional).
  - **Pending**.

## DB-Driven Presets

- [x] Phase 1: Add `sticker_presets` table with role + time-window + is_active.
  - Backfill 5 presets from previously hardcoded lists.
  - RLS enabled, no client policies (internal-only).
  - **Done (2026-06-29)**: migration `20260629000009_db_driven_presets.sql`.

- [x] Phase 2: Refactor `generate-sticker` edge function.
  - Drop hardcoded `PRESETS` map.
  - Load preset from DB, validate role + time window + is_active.
  - **Done (2026-06-29)**: `resolveUserRole` + `loadPreset` helpers, `PRESETS` map removed.

- [x] Phase 3: Add `list-presets` edge function.
  - GET endpoint, anonymous-friendly.
  - Filter by caller role + now(); exclude `style_descriptor`.
  - **Done (2026-06-29)**: `supabase/functions/list-presets/index.ts`.

- [x] Phase 4: Flutter integration.
  - New `StickerPreset` model, `PresetRepository`, `PresetBloc`.
  - Wire into `app.dart` and dispatch on auth change.
  - Update `home_screen.dart` with loading/error/empty + pull-to-refresh.
  - Drop `kStickerPresets` from `lib/core/constants/presets.dart`.
  - **Done (2026-06-29)**: all files created and wired.

- [x] Phase 5: Test update.
  - Replace contract test with parser + repository cache unit tests.
  - **Done (2026-06-29)**: 7 tests passing in `test/widget_test.dart`.

## Presets: Operational Risks And Follow-Ups

### Cache Staleness

- [ ] Monitor list-presets traffic after rollout; tune 5-minute TTL if too
  stale or too chatty.
- [ ] Consider Supabase Realtime subscription on `sticker_presets` if
  admin changes need to propagate instantly. (Future, not in current scope.)

### Role Detection Placeholder

- [ ] Build subscription system: implement `resolveUserRole` in
  `generate-sticker/index.ts` to read real `plus` flag (proposed
  source: `user_wallets.is_plus` or
  `auth.users.raw_app_meta_data->>'subscription'`).
- [ ] Mirror the same flag read in Flutter's `roleFor(AuthBlocState)`
  helper in `lib/app.dart`.
- [ ] Add end-to-end check: signed-in `plus` user sees `chibi_3d`
  preset and can generate with it; downgraded user loses access
  silently in UI but is rejected at the edge function with
  `Unknown or unavailable presetId`.

### Anonymous list-presets Traffic

- [ ] Add per-IP rate limit on `list-presets` if anonymous refresh storms
  become a concern. (Out of scope for initial rollout.)

### presetName Drift / Admin Guardrails

- [ ] Document admin rule: never rename `sticker_presets.id` (PK).
  History rows store the ID and will go orphan.
- [ ] Use soft-delete (`is_active = false`) only. Never hard-delete rows.
- [ ] Document in migration comment that admins must use the admin UI
  or SQL with care.

### Edge Function Performance

- [ ] Monitor `generate-sticker` cold-start latency after adding the
  `sticker_presets` lookup. Expect one extra indexed query per
  request, similar in cost to the existing
  `image_generation_configs` lookup.
- [ ] If hot-start latency regresses, consider caching the active preset
  list for the lifetime of the edge function instance (in-memory
  Map keyed by preset ID, refreshed every N minutes).

## Prompt Reasoning Enhancement

- [x] Phase 1: DB migration + provider configs.
  - Extended `route_scope` CHECK to include `reasoning`.
  - Added `reasoning_guidance` to `sticker_presets`, `negative_prompt` to `sticker_generations`.
  - Created `prompt_enhancement_logs` table.
  - Seeded `mistral-small` (priority 1) + `mistral-nemo` (priority 2) with bilingual system prompt.
  - **Done (2026-06-29)**: migration `20260629000010_reasoning_enhancement.sql`.

- [x] Phase 2: Edge function integration.
  - Added `enhancePrompt()` orchestrator with in-memory cache (1h TTL).
  - Added `callPollinationsReasoning()` for Mistral inference.
  - Added `parseEnhancedPrompt()` with 3-level fallback (JSON → code block → regex).
  - Updated provider adapters to inject negative prompt.
  - Wired enhance before credit deduction (silent fallback on failure).
  - **Done (2026-06-29)**: `supabase/functions/generate-sticker/index.ts`.

### Operational Risks

- [ ] Verify Pollinations text API endpoint (`text.pollinations.ai/v1/chat/completions`) returns valid JSON from Mistral models. Check if `response_format: { type: "json_object" }` is supported.
- [ ] Monitor reasoning latency: `mistral-small` should average 0.5-1.5s. If >3s, consider reducing `max_tokens` or switching primary.
- [ ] Monitor success rate: `SELECT success, COUNT(*) FROM prompt_enhancement_logs WHERE created_at > now() - interval '24 hours' GROUP BY success;`. If <80%, check error_message distribution.
- [ ] If `mistral-small` underperforms for Indonesian prompts, swap priority: `UPDATE image_generation_configs SET priority = 0 WHERE model_name = 'mistral-nemo' AND route_scope = 'reasoning';`
- [ ] Consider adding `negative_prompt` to the public sticker API response if clients want to display it (out of scope for now).

## Sticker Packs (Native WhatsApp Integration)

- [x] Phase 1: Sticker pack data model.
  - Add `sticker_packs` table (id, user_id, name, tray_icon_path, identifier, created_at).
  - Add `sticker_pack_items` table (pack_id, sticker_generation_id, position, emoji_tags[], accessibility_text).
  - RLS: user can SELECT/INSERT/UPDATE/DELETE own packs; server-side RPC for pack mutations to maintain invariants.
  - Server RPC: `create_pack`, `add_sticker_to_pack`, `remove_sticker_from_pack`, `rename_pack`, `delete_pack`.

- [x] Phase 2: Pack UI in Flutter.
  - "My Packs" screen accessible from Home AppBar (alongside Missions icon).
  - Pack card: tray icon + name + sticker count (3-30) + last modified.
  - Create pack flow: prompt for name + auto-generate tray icon from first sticker.
  - Add-to-pack action on generation success screen + history detail.
  - Pack detail screen: grid of stickers, add/remove, rename, delete.

- [x] Phase 3: Tray icon generation.
  - Server-side: derive 96×96 PNG tray icon from a sticker image (center crop, optional rounded corners).
  - Storage path: `tray_icons/{user_id}/{pack_id}.png` (≤50 KB target).
  - UI: allow user to override with custom upload OR pick from preset set.

- [x] Phase 4: Pack metadata (emojis + accessibility text).
  - On add-to-pack: prompt user for 1-3 emojis (default: extract from preset's emoji field).
  - On add-to-pack: optional accessibility text (default: derive from preset description).
  - Validate per WhatsApp spec: emojis ≤3, accessibility ≤125 chars.

- [x] Phase 5: Native WhatsApp import (Android first).
  - Declare `StickerContentProvider` in `android/app/src/main/AndroidManifest.xml` with `com.whatsapp.sticker.READ` permission.
  - Implement `StickerContentProvider.kt` exposing pack metadata + sticker file URIs.
  - Add "Export to WhatsApp" button on Pack detail screen: launches `com.whatsapp.intent.action.ENABLE_STICKER_PACK` intent with `sticker_pack_id`, `sticker_pack_authority`, `sticker_pack_name`.
  - Handle `ActivityNotFoundException` (WhatsApp not installed) gracefully.
  - Tray icon auto-derived from first sticker via `derive-tray-icon` Edge Function.
  - Local file cache via `getApplicationDocumentsDirectory()` for ContentProvider serving.

- [ ] Phase 6: Native WhatsApp import (iOS, optional).
  - Add WhatsApp-provided Swift framework as CocoaPods dependency.
  - Or use undocumented `whatsapp://stickerPack` URL scheme with Base64 pasteboard.
  - Update `Info.plist` with `LSApplicationQueriesSchemes: ["whatsapp"]`.
  - Decision: defer until user demand exists (App Store rejection risk noted in WhatsApp docs).

- [ ] Phase 7: Pack validation server-side.
  - Add `validate_pack_for_whatsapp(pack_id)` RPC checking all WhatsApp spec constraints (count 3-30, sizes, dimensions, format).
  - Surface validation errors in UI before "Add to WhatsApp" attempt.
  - Block import if any sticker fails validation.

### Risks
- Apple App Store rejection for "sticker-only" apps. Mitigate by ensuring BikinStiker has substantial other functionality (it does — generator, missions, subscriptions).
- Pack adoption curve: users must collect 3+ stickers before importing. UX must encourage this.
- Storage cost: tray icons + sticker copies in pack-specific paths.

## Daily Check-in Streak

- [x] Phase 1: DB schema + RPCs.
  - Created `daily_checkin_streaks` table with RLS.
  - Created `load_daily_checkin_streak()` and `claim_daily_checkin()` RPCs.
  - Streak logic: 7-day cycle, 1-day gap between cycles, bonus on day 7.
  - **Done (2026-07-02)**: migration `20260702000014_daily_checkin_streak.sql`.

- [x] Phase 2: Flutter model + repository.
  - Created `DailyCheckinStreak` and `DailyCheckinClaimResult` models.
  - Updated `MissionRepository` with streak fetch/claim methods.
  - **Done (2026-07-02)**.

- [x] Phase 3: BLoC integration.
  - Added `MissionDailyCheckinClaimRequested` event and handler.
  - Streak loaded in parallel with missions on screen open.
  - Success snackbar for check-in.
  - **Done (2026-07-02)**.

- [x] Phase 4: UI — streak card + section grouping.
  - Created `DailyCheckinCard` with 7-day box display.
  - Created `MissionSectionHeader` for section titles.
  - Updated `MissionsScreen` with CustomScrollView: Daily Rewards → Quick Rewards → Achievements.
  - **Done (2026-07-02)**.

- [ ] Phase 5: Push notifications (deferred).
  - Add local notification for daily check-in reminder.
  - Schedule notification for next day if not checked in.

- [ ] Phase 6: Lottie animations (deferred).
  - Download Lottie JSON assets from LottieFiles.
  - Add `lottie` package dependency.
  - Replace emoji fallbacks with animated Lottie in DailyCheckinCard.

## Recurring Mission Fix

- [x] Fix `OR TRUE` bug in `complete_mission` RPC.
  - Removed `OR TRUE` from max_completions_per_user check.
  - Added `cooldown_seconds = 86400` to `share_app_daily`.
  - **Done (2026-07-02)**: migration `20260702000013_fix_recurring_mission_limit.sql`.
