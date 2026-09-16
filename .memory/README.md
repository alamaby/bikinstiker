# Project Memory - BikinStiker

Last updated: 2026-09-16 14:25:00
Format version: 1

## Current State
- **Current work:** RCA rantai provider LLM + alert operator senyap + **DB alert sink**. Migrasi `20260916000001`/`20260916065125`/`20260916071704` ter-apply; edge function **terdeploy** (`generate-sticker` v38, `surprise-me` v6 — 12/12 marker baru terverifikasi live). Kredensial Ollama + Cerebras dipatch; regresi `gemma-4-31b` archived sudah dinonaktifkan lagi. Rantai reasoning: ollama p1 → openrouter p3 → cerebras zai-glm-4.7 p5 → gpt-oss-120b p6. deno check bersih; tes hijau (generate-sticker 134/134, surprise-me 15/15).
- **Track:** BikinStiker - AI-powered WhatsApp sticker generator (Flutter).
- **Verified:** analyze 0; test 198/198; APK 3 ABI (2026-09-15). AAB release 50.1 MB signed non-debug + merged manifest targetSdk 36 / AD_ID / StickerContentProvider / AdMob prod ID bersih dari secret `.env` (2026-09-12).
- **Working tree:** `supabase/` (submodule) termodifikasi — `operator_alerts.ts`, `generate-sticker/index.ts` + test, `surprise-me/index.ts`, 3 migrasi baru (`20260916000001_remediate_provider_chain_rca`, `20260916065125_operator_alert_sink`, `20260916071704_deactivate_archived_cerebras_model`); memori + plan baru; belum commit.

## Active Decisions
- **Release signing:** pakai keystore yang sama dengan Bagistruk (tiga keystore byte-identical SHA-256 `75797589...`); `hasReleaseSigning` guard + fallback debug untuk clone segar/CI; pin `compileSdk`/`targetSdk` 36; minify + shrinkResources + `proguard-rules.pro`.
- **Ads:** AdMob App ID produksi `ca-app-pub-4082765898994990~3724794026`; `AD_ID` permission wajib untuk `google_mobile_ads` + disclosure Console.
- **Security:** `.env` ter-bundle verbatim ke APK/AAB — tidak boleh memuat secret server (mis. `CLOUDFLARE_API_TOKEN`; client tak pernah membacanya, server baca dari DB/Vault).
- **Markdown rendering:** pakai `flutter_markdown_plus` (fork resmi Foresight Mobile), bukan `flutter_markdown` yang discontinued; API `Markdown`/`MarkdownStyleSheet` dipakai apa adanya.
- **APK rename hook:** hanya rename APK dengan `lastModified >= buildStartMs - 30 dtk`; sisa basi dihapus (bukan di-rename).
- **Provider chain (2026-09-16):** config aktif tanpa kredensial / ber-`base_url` placeholder dibuang runtime (`partitionRunnableConfigs`) dan tidak boleh dibiarkan `is_active=TRUE`; alert operator wajib berisik saat env belum di-set, bukan no-op senyap.
- **Alert detection:** keputusan alert memakai `errorType` (bukan hanya status code) agar 422 `schema_mismatch`/`missing_api_key`/`opaque_output` ikut tertangkap.
- **Alert kanal (2026-09-16):** DB sink `public.operator_alerts` adalah kanal **primer** dan selalu ditulis lebih dulu (RLS deny-all, service_role only); email Resend hanya kanal kedua opsional. Jangan pernah membalik urutan ini — itulah penyebab insiden senyap 2026-09-16. `queueOperatorAlert(params, service)` menerima service client eksplisit (bukan module singleton) untuk menghindari race antar-request.

## Open Items / Blockers
- **Smoke test end-to-end (2026-09-16):** jalankan satu generation nyata; pastikan `prompt_enhancement_logs` tidak lagi jatuh ke fallback dan `operator_alerts` terisi bila ada insiden.
- **Cloudflare default:** masih nonaktif; aktifkan hanya setelah `base_url` (account id real) + `api_key` dipatch dalam satu UPDATE.
- **Opsional (2026-09-16):** kanal email Resend — `from` = `updates@bikinstiker.alamaby.com`; record Resend (DKIM/SPF) belum ada. Butuh: verify domain di resend.com → API key → `supabase login` → set 4 secret.
- **Redeploy diperlukan (2026-09-16):** `generate-sticker`, `surprise-me`, `share-redirect` — perubahan domain (Fase 7) belum live di produksi.
- **Domain berpindah ke `bikinstiker.alamaby.com` (2026-09-16):** `bikinstiker.com`/`bikinstiker.app` tidak pernah terdaftar; semua referensi (edge function HTTP-Referer, `share-redirect`, `request_share_token()`, 6 override `http_referer` di DB, Android App Link, iOS entitlement, Flutter host check) diarahkan ke host baru. Custom scheme `bikinstiker://` & bundle ID `com.bikinstiker.bikin` **tidak** diubah. Migrasi `20260916152819` ter-apply; **edge function belum dideploy ulang**.
- **App Links belum terverifikasi:** `.well-known/assetlinks.json` di host baru masih 404 — perlu di-host di Vercel (repo landing page terpisah).
- **Utang teknis alert:** dedupe per-isolate (bisa spam setelah cold start); `prompt_enhancement_logs.sticker_generation_id` selalu `null`; `operator_alerts` belum ada retensi/purge.
- **Jangan:** `UPDATE ... SET is_active = TRUE` massal per-provider saat patch kredensial — model known-bad ikut aktif (lihat regresi `gemma-4-31b` 2026-09-16).
- **Rilis Play:** upload ke Closed testing (12 tester × 14 hari), lengkapi Data safety / App content / listing, deploy landing page (assetlinks), verifikasi App Links di device.
- **Backend (SH2):** `supabase db push` migrasi hardening + verifikasi.
- **Legacy tersisa:** deploy MR5, SK4 (disable legacy keys), FX5 smoke, SSC5 smoke, seed pack owner, ToS v2, VALIDATE constraint surprise-me, SK5 deno-check pre-existing, SH3 audit `rls_auto_enable`.
- **Rotasi token:** rotasi `CLOUDFLARE_API_TOKEN` bila AAB lama (yang memuat secret) sempat dibagikan.
- **Markdown migration follow-up:** uji visual dokumen legal di device nyata belum dijalankan (baru widget test render).

## Legacy Archive
- `PROJECT_MEMORY.md` - arsip historis lengkap (49 entri, 2026-07-04 → 2026-09-15). Read-only; jangan tambah entri baru di sana.

## Recent Entries
- [2026-09-16 12:49:56 - provider-chain-rca-and-silent-alert-noop](2026-09-16/124956-provider-chain-rca-and-silent-alert-noop.md)
- [2026-09-15 16:21:23 - init-memory-directory](2026-09-15/162123-init-memory-directory.md)
- [2026-09-15 16:21:23 - migrate-flutter-markdown-to-plus](2026-09-15/162123-migrate-flutter-markdown-to-plus.md)
- [2026-09-12 16:21:23 - play-store-release-hardening](2026-09-12/162123-play-store-release-hardening.md)
- [2026-09-12 16:21:23 - guest-wall-signup-bounce-fix](2026-09-12/162123-guest-wall-signup-bounce-fix.md)
