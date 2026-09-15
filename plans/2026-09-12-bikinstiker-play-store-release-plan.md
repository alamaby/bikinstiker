# BikinStiker — Google Play Store Release Plan

Created: 2026-09-12 00:00:00

## Objective

Menerbitkan `com.alamaby.bikin_stiker` (`0.26.5+87`, versionCode 87) sebagai **AAB signed** dengan **upload key yang sama dengan Bagistruk**, lolos review Play, dan menjalani **closed testing 12 tester × 14 hari** sebelum produksi.

## Scope

- Unifikasi signing ke file `bagistruk/android/upload-keystore.jks` (sumber kebenaran).
- Perbaikan `android/app/build.gradle.kts`: guard signing, pin SDK 36, shrink/proguard.
- Manifest: `AD_ID`, ganti AdMob Test ID → Prod ID.
- Build + verifikasi `flutter build appbundle --release` + cek bukan debug key.
- Workflow CI `playstore.yml` ala Bagistruk (diselaraskan path).
- Checklist Play Console: listing grafis, Data safety, App content, App Links `assetlinks.json`, OAuth SHA-1, privacy policy hosted, closed-test setup.

Di luar scope: iOS App Store, refactor god-classes, migrasi DB baru.

## Milestones

1. **M1 — Kunci disatukan** (backup + verifikasi fingerprint + copy dari Bagistruk).
2. **M2 — Build siap Play** (gradle + manifest + AdMob prod + AAB lokal lolos).
3. **M3 — CI + Console siap** (workflow + listing + policy + App Links + OAuth).
4. **M4 — Closed test jalan** (12 tester opt-in × 14 hari → produksi).

## Tasks

- [x] **T1 Backup + verifikasi key:** ketiga `.jks` (bagistruk/bikinstiker/waktu-sejak) **byte-identical** SHA-256 `75797589BDC18AC75A67948986142D44412B8C3588702807E052FFB4CF2735B3`. Tidak perlu copy. Upload key SHA1 `8C:BD:26:05:F6:D7:B7:5D:11:C0:B5:4A:3A:F8:A4:DA:F3:BB:C8:6A`, SHA256 `ED:BD:CC:77:...:DA`.
- [x] **T2 Copy key Bagistruk → Bikinstiker:** N/A — sudah identik (T1).
- [x] **T3 Gradle hardening** (`android/app/build.gradle.kts`): `hasReleaseSigning` guard + fallback debug; pin `compileSdk=36`/`targetSdk=36`; `isMinifyEnabled/isShrinkResources=true` + `proguard-rules.pro` (NEW).
- [x] **T4 Manifest + AdMob prod:** +`ACCESS_NETWORK_STATE`, +`AD_ID`, `allowBackup=false`; AdMob App ID → produksi `ca-app-pub-4082765898994990~3724794026` (ternyata sudah ada di `.env`, publisher sama Bagistruk).
- [x] **T5 Build AAB lokal:** analyze 0; test 197/197; AAB 50.1 MB; `jarsigner` verified + CN=Alam Aby Bashit, bukan debug; merged manifest targetSdk 36 + AD_ID + provider + AdMob prod OK.
- [x] **T6 CI `playstore.yml`** (NEW) + `key.properties.example` (NEW).
- [ ] **T7 Play Console listing (owner):** buat app `Bikin Stiker` + package `com.alamaby.bikin_stiker`; ikon 512, feature graphic 1024×500, min 2 screenshot, kategori, kontak, URL privacy policy (`https://bikinstiker.com/privacy`? — landing page punya route `/privacy`).
- [ ] **T8 Policy & integrasi (owner):** Data safety (ads, `google_sign_in`, `share_plus`, `app_links`), Advertising ID, App content, **deploy landing page** agar `assetlinks.json` (sudah diisi fingerprint) live, SHA-1 upload key ke Google Cloud OAuth + Supabase Google provider, callback AdMob SSV.
- [ ] **T9 Closed test (owner):** upload AAB → track Closed → 12+ tester → 14 hari → promosi Production.
- [x] **T10 Secret hygiene `.env`:** `.env` ter-bundle verbatim ke AAB dan memuat `CLOUDFLARE_API_TOKEN` produksi (53 char) → **dihapus** dari `.env` (backup di temp). Client tidak pernah membacanya. Verifikasi ulang: AAB tidak lagi memuat CLOUDFLARE/SERVICE_ROLE/OPENROUTER. Catatan `.env.example` diperkuat.
- [ ] **T11 Rotasi token (owner, opsional):** token Cloudflare pernah berada di dalam AAB yang dibuild lokal sebelum T10; jika AAB itu pernah dibagikan, rotasi token di Cloudflare Dashboard. Token di server hanya dipakai dari DB `image_generation_configs.api_key`, bukan env.

## Risks

- **Key tertimpa/hilang = tidak bisa update app selamanya.** Counter: backup offline 2 lokasi + `KEYSTORE_BASE64` di GitHub Secrets; `.gitignore` sudah meng-ignore `*.jks`/`key.properties`.
- **Upload key sama lintas app memudahkan rotasi massal bila bocor.** Counter: trade-off sadar; Play App Signing tetap memisahkan app-signing key per app.
- **Minify/strip merusak `StickerContentProvider` / WhatsApp export.** Counter: smoke export WhatsApp + re-check proguard (`keep io.flutter.**`).
- **TargetSdk ikut Flutter = ditolak saat syarat naik ke 36.** Counter: pin 36 sekarang seperti sibling.
- **AdMob baru + closed test = revenue 0 selama ±14 hari + risiko suspend bila klik sendiri.** Counter: jangan klik iklan sendiri; test device ID selama uji.
- **Akun personal baru tanpa 12 tester aktif = produksi diblokir.** Counter: rekrut 12 tester nyata.

## Progress Log

- 2026-09-12 — Audit read-only selesai. Keputusan terkunci: key dari bagistruk, closed test, lanjut 0.26.5+87, AdMob baru. Plan ditulis.
- 2026-09-12 — T1–T6 selesai. Keystore ternyata identik (tanpa copy); `.env` sudah punya AdMob App ID produksi; landing page + route privacy/terms sudah ada. `assetlinks.json` diisi SHA-256 upload key. Verifikasi: analyze 0, test 197/197, AAB 50.1 MB signed release key. Sisa T7–T9 = aksi Console/owner.
- 2026-09-12 — **T10 temuan keamanan + fix.** AAB release terbukti memuat `.env` apa adanya (hash identik) termasuk `CLOUDFLARE_API_TOKEN` produksi → dihapus dari `.env`, rebuild, verifikasi AAB bersih. Sisa: T7–T9 (Console), T11 (opsional rotasi token).

## Notes

- Tidak ada deviasi standar domain (bukan sistem rating/billing ala C2M/TM Forum).
- Contoh `assetlinks.json`:
  ```json
  [{"relation":["delegate_permission/common.handle_all_urls"],"target":{"namespace":"android_app","package_name":"com.alamaby.bikin_stiker","sha256_cert_fingerprints":["GANTI_SHA256_UPLOAD_KEY"]}}]
  ```
- Contoh `key.properties.example`:
  ```
  storeFile=upload-keystore.jks
  storePassword=CHANGE_ME
  keyAlias=upload
  keyPassword=CHANGE_ME
  ```
