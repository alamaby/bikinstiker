# Project Memory - BikinStiker

Last updated: 2026-09-15 16:21:23
Format version: 1

## Current State
- **Current work:** Migrasi `flutter_markdown` (discontinued) → `flutter_markdown_plus ^1.0.12`. Versi app `0.26.6+88`. analyze 0; test 198/198; APK split-per-abi 3 ABI sukses.
- **Track:** BikinStiker - AI-powered WhatsApp sticker generator (Flutter).
- **Verified:** analyze 0; test 198/198; APK 3 ABI (2026-09-15). AAB release 50.1 MB signed non-debug + merged manifest targetSdk 36 / AD_ID / StickerContentProvider / AdMob prod ID bersih dari secret `.env` (2026-09-12).
- **Working tree:** memori dipindah ke `.memory/`; `AGENTS.md` + `PROJECT_MEMORY.md` termodifikasi, belum commit.

## Active Decisions
- **Release signing:** pakai keystore yang sama dengan Bagistruk (tiga keystore byte-identical SHA-256 `75797589...`); `hasReleaseSigning` guard + fallback debug untuk clone segar/CI; pin `compileSdk`/`targetSdk` 36; minify + shrinkResources + `proguard-rules.pro`.
- **Ads:** AdMob App ID produksi `ca-app-pub-4082765898994990~3724794026`; `AD_ID` permission wajib untuk `google_mobile_ads` + disclosure Console.
- **Security:** `.env` ter-bundle verbatim ke APK/AAB — tidak boleh memuat secret server (mis. `CLOUDFLARE_API_TOKEN`; client tak pernah membacanya, server baca dari DB/Vault).
- **Markdown rendering:** pakai `flutter_markdown_plus` (fork resmi Foresight Mobile), bukan `flutter_markdown` yang discontinued; API `Markdown`/`MarkdownStyleSheet` dipakai apa adanya.
- **APK rename hook:** hanya rename APK dengan `lastModified >= buildStartMs - 30 dtk`; sisa basi dihapus (bukan di-rename).

## Open Items / Blockers
- **Rilis Play:** upload ke Closed testing (12 tester × 14 hari), lengkapi Data safety / App content / listing, deploy landing page (assetlinks), verifikasi App Links di device.
- **Backend (SH2):** `supabase db push` migrasi hardening + verifikasi.
- **Legacy tersisa:** deploy MR5, SK4 (disable legacy keys), FX5 smoke, SSC5 smoke, seed pack owner, ToS v2, VALIDATE constraint surprise-me, SK5 deno-check pre-existing, SH3 audit `rls_auto_enable`.
- **Rotasi token:** rotasi `CLOUDFLARE_API_TOKEN` bila AAB lama (yang memuat secret) sempat dibagikan.
- **Markdown migration follow-up:** uji visual dokumen legal di device nyata belum dijalankan (baru widget test render).

## Legacy Archive
- `PROJECT_MEMORY.md` - arsip historis lengkap (49 entri, 2026-07-04 → 2026-09-15). Read-only; jangan tambah entri baru di sana.

## Recent Entries
- [2026-09-15 16:21:23 - init-memory-directory](2026-09-15/162123-init-memory-directory.md)
- [2026-09-15 16:21:23 - migrate-flutter-markdown-to-plus](2026-09-15/162123-migrate-flutter-markdown-to-plus.md)
- [2026-09-12 16:21:23 - play-store-release-hardening](2026-09-12/162123-play-store-release-hardening.md)
- [2026-09-12 16:21:23 - guest-wall-signup-bounce-fix](2026-09-12/162123-guest-wall-signup-bounce-fix.md)
