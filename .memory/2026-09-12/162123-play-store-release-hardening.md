# Play Store Release Hardening (AAB, key sama Bagistruk)

Date: 2026-09-12
Time: 16:21:23
Topic: play-store-release-hardening
Status: done implementasi + AAB lokal terverifikasi; pending upload Console (commit `b3132fb`)

## Task / Problem
Siapkan rilis Play: signing release yang benar, target SDK terbaru, minify/proguard, permission AD_ID, AdMob App ID produksi, dan workflow build AAB. Owner putuskan pakai key yang sama dengan Bagistruk, jalur Closed test 12 tester × 14 hari, versi `0.26.5+87`.

## Key Files Changed
- `android/app/build.gradle.kts` - `hasReleaseSigning` guard + fallback debug, pin `compileSdk=36`/`targetSdk=36`, `isMinifyEnabled`/`isShrinkResources=true`
- `android/app/proguard-rules.pro` (NEW) - keep `io.flutter.**` (salin Bagistruk)
- `android/app/src/main/AndroidManifest.xml` - +`ACCESS_NETWORK_STATE`, +`AD_ID`, `allowBackup=false`/`fullBackupContent=false`, AdMob App ID produksi
- `android/key.properties.example` (NEW) - placeholder; `storeFile` `upload-keystore.jks` relatif `android/app/`
- `.github/workflows/playstore.yml` (NEW) - workflow_dispatch: decode `KEYSTORE_BASE64` → `android/app/upload-keystore.jks`, tulis `.env` dari secrets/vars, build AAB, verify bukan debug key, upload artifact (upload Play otomatis masih di-comment)
- `.env` - hapus 2 baris `CLOUDFLARE_*` (secret tidak boleh ter-bundle)
- `.env.example` - peringatan keamanan diperkuat
- `plans/2026-09-12-bikinstiker-play-store-release-plan.md` (NEW)

## Technical / Business Decisions
- Tiga keystore (bagistruk, bikinstiker, waktu-sejak) **byte-identical** SHA-256 `75797589...` → tidak perlu copy; pakai key yang sama.
- `.env` di-bundle verbatim ke AAB (hash identik) dan memuat `CLOUDFLARE_API_TOKEN` produksi → dihapus dari `.env`; client tak pernah membaca variabel tersebut (server baca dari DB).
- `assetlinks.json` di landing page diisi SHA-256 upload key (nilai publik, aman).

## Assumptions & Risks
- `assetlinks.json` ada di repo landing terpisah dan belum di-deploy Vercel; App Links hanya terverifikasi setelah host live.
- `storeFile` Bikinstiker beda dari Bagistruk (`upload-keystore.jks` vs `../upload-keystore.jks`) - workflow sudah disesuaikan, tapi dokumentasi lintas repo bisa membingungkan.
- Rotasi `CLOUDFLARE_API_TOKEN` masih disarankan bila AAB lama yang memuat secret sempat dibagikan.

## Blockers / Unresolved
- Upload ke Closed testing (12 tester × 14 hari) + lengkapi Data safety / App content / listing.
- Deploy landing page (assetlinks) + verifikasi App Links di device.

## Verification
- `flutter analyze` 0; `flutter test` 197/197
- `flutter build appbundle --release` 50.1 MB
- `jarsigner` jar verified + CN=Alam Aby Bashit (DEBUG_KEY=False)
- Merged manifest: targetSdk 36, AD_ID, StickerContentProvider, AdMob prod ID OK
- AAB bersih dari CLOUDFLARE / SERVICE_ROLE / OPENROUTER

## Commit
- `chore(android): harden Play release signing, target sdk 36, minify, ads id, and AAB workflow` (`b3132fb`)

## Related
- Plan: `plans/2026-09-12-bikinstiker-play-store-release-plan.md`
