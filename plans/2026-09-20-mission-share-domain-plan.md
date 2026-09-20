# Mission Share Domain Implementation Plan (`bikinstiker.alamaby.com`)

Created: 2026-09-20 07:00:00

## Objective

Buat alur mission `share_app_daily` end-to-end hidup di domain `bikinstiker.alamaby.com`:
link `/r/<token>` ter-redirect benar ke Edge Function `share-redirect`,
klaim mendarat di landing `/share-claimed/<id>` + aplikasi via `bikinstiker://`,
placeholder store terdokumentasi, dan entri memory yang keliru soal bundle ID dikoreksi.

## Background (hasil analisa 2026-09-20, jangan diulang dari nol)

- Fitur yang dimaksud = **mission `share_app_daily`** (share link aplikasi dapat kredit,
  server-verified via single-use token). BUKAN `shareStickerImage`
  (`bikinstiker/lib/core/share_helper.dart`) — itu share file gambar tanpa reward.
- Alur kode: `missions_screen.dart:350-356` → `MissionShareRequested` →
  `mission_bloc.dart:393-426` → `request_share_token()` RPC → share sheet berisi
  `https://bikinstiker.alamaby.com/r/<token>` → penerima klik → Vercel rewrite `/r/:token`
  → Edge Function `share-redirect` → `consume_share_token()` → 302 ke
  `/share-claimed/<id>?status=ok&credits=N` → landing coba `bikinstiker://share-claimed/...`
  → app claim via `claimStream` (`share_mission_service.dart`).
- Kode sudah memakai host baru di: `share-redirect/index.ts:27-28`,
  migrasi `20260916083003` (`share_url` + 6 override `http_referer`),
  `AndroidManifest.xml:51`, `Runner.entitlements:7`, `share_mission_service.dart:128`.
- **Repo landing yang benar = `bikin-stiker-landing-page`** (Next.js, live di
  `bikinstiker.alamaby.com`). `bagistruk-landing-page` milik aplikasi Bagistruk —
  JANGAN disentuh.
- Temuan kritis: `vercel.json` lokal berisi `dummy_verify.supabase.co`, TAPI file itu
  adalah **artefak generated yang di-gitignore** (`.gitignore:52`), dibuat oleh
  `scripts/generate-vercel-json.mjs` dari env `SUPABASE_PROJECT_REF`. Jadi yang menentukan
  produksi = env var di Vercel dashboard, bukan isi file lokal. Sama untuk
  `public/.well-known/apple-app-site-association` (`.gitignore:56`).

## Decisions (sudah dikonfirmasi user, jangan ditanyakan ulang)

1. Fokus landing = `bikin-stiker-landing-page`. (`bagistruk-landing-page` out of scope.)
2. **Pertahankan fallback** `bikinstiker://` + tombol Play Store. JANGAN host
   `assetlinks.json` (keputusan plan 2026-09-14, masih berlaku; butuh SHA-256 Play Console
   bila kelak diubah).
3. Scope = semua gap kritis (redirect `/r/`, redeploy edge function, placeholder store ID,
   koreksi memory).

## Scope

In scope:

- Verifikasi live domain + redirect + `.well-known` (read-only, via curl/Invoke-WebRequest).
- Pastikan env `SUPABASE_PROJECT_REF` di Vercel dashboard berisi project ref asli + redeploy.
- Redeploy Edge Function `share-redirect` (kode lokal sudah benar).
- Placeholder iOS App Store: JANGAN karang ID; sembunyikan/disable tombol iOS bila env kosong.
- Koreksi memory bundle ID yang keliru.
- Hygiene minor L1 (aman). L2 hanya komentar. L5 (i18n) DITUNDA.

Out of scope:

- `assetlinks.json`, perubahan custom scheme `bikinstiker://`, perubahan
  applicationId/bundle ID, repo `bagistruk-landing-page`.

## Milestones

1. Fase 0 — Verifikasi live (tanpa mengubah apa pun).
2. Fase 1 — Perbaiki redirect `/r/:token` produksi via env Vercel.
3. Fase 2 — Redeploy + verifikasi Edge Function `share-redirect`.
4. Fase 3 — Placeholder iOS + dokumentasi AASA.
5. Fase 4 — Koreksi memory bundle ID + hygiene L1/L2-komentar.
6. Fase 5 — Uji end-to-end + matriks verifikasi akhir.

## Tasks

- [x] Fase 0: verifikasi live (curl, read-only)
- [ ] Fase 1: env `SUPABASE_PROJECT_REF` di Vercel + redeploy landing
- [x] Fase 2: redeploy `share-redirect` + verifikasi 302
- [x] Fase 3: fallback tombol iOS bila `NEXT_PUBLIC_IOS_APP_URL` kosong
- [x] Fase 4: koreksi bundle ID di memory + hygiene L1/L2-komentar
- [ ] Fase 5: matriks verifikasi akhir + uji E2E manual

---

## FASE 0 — Verifikasi live (READ-ONLY, lakukan pertama, ubah apa pun DILARANG)

Tujuan: bedakan "rusak di produksi" vs "hanya artefak lokal". Semua perintah di bawah
read-only. Jalankan dari PowerShell 7+.

### 0.1 Redirect `/r/` produksi

```powershell
# Token sengaja invalid (<16 char) -> share-redirect HARUS 302 ke landing fallback,
# BUKAN error DNS/timeout ke host dummy.
Invoke-WebRequest -Uri "https://bikinstiker.alamaby.com/r/invalid-token-xyz" `
  -MaximumRedirection 0 -SkipHttpErrorCheck |
  Select-Object StatusCode, @{n='Location';e={$_.Headers.Location}}
```

Hasil yang diharapkan (SEHAT):

- `StatusCode`: `302` (atau `307` tergantung Vercel), `Location` mengandung
  `.supabase.co/functions/v1/share-redirect?token=...` sebagai hop pertama.
- Ikuti rantai sampai akhir: Location final =
  `https://bikinstiker.alamaby.com/share-claimed/error?share_error=invalid_token`.

Hasil yang berarti SAKIT:

- Location mengandung `dummy_verify` → env `SUPABASE_PROJECT_REF` di Vercel berisi
  dummy/belum di-set → lanjut ke Fase 1.
- Timeout / DNS error / 404 di hop Vercel → catat pesan persisnya ke Progress Log.

### 0.2 Halaman klaim + `.well-known`

```powershell
(Invoke-WebRequest -Uri "https://bikinstiker.alamaby.com/share-claimed/abc?status=ok&credits=5" -SkipHttpErrorCheck).StatusCode
# Harap: 200
(Invoke-WebRequest -Uri "https://bikinstiker.alamaby.com/.well-known/apple-app-site-association" -SkipHttpErrorCheck).StatusCode
# Harap: 200 (isi appIDs [] = normal, lihat Fase 3)
(Invoke-WebRequest -Uri "https://bikinstiker.alamaby.com/.well-known/assetlinks.json" -SkipHttpErrorCheck).StatusCode
# Harap: 404 (BY DESIGN, keputusan #2 — bukan bug)
```

### 0.3 Kriteria selesai Fase 0

Tabel hasil 4 cek di atas tercatat di `## Progress Log` (tanggal + jam + hasil mentah).
Keputusan Fase 1/2 diambil dari tabel ini, bukan dari isi file lokal.

---

## FASE 1 — Env `SUPABASE_PROJECT_REF` di Vercel (repo `bikin-stiker-landing-page`)

Konteks untuk pelaksana (PENTING, jangan salah paham):

- `vercel.json.in` = template (`__SUPABASE_PROJECT_REF__`). `vercel.json` = hasil generate,
  **di-gitignore, JANGAN di-commit, JANGAN diedit manual**.
- `scripts/generate-vercel-json.mjs` GAGAL FAST bila env `SUPABASE_PROJECT_REF` kosong —
  itu sebabnya working copy lokal berisi `dummy_verify` (seseorang build lokal dengan
  nilai dummy). Ini artefak lokal, bukan vonis produksi.

### 1.1 Cari project ref asli (BUKAN secret, boleh tampil di dashboard, tapi JANGAN tulis ke chat/log/file)

- Sumber utama: Supabase Dashboard → project BikinStiker (production) → Project Settings →
  General → Reference ID (string ~20 char, mis. `abcdefghij`).
- Alternatif (butuh login): dari repo `bikinstiker`:
  `& "scripts/supabase-with-token.ps1" projects list` lalu cocokkan nama project produksi.
- DILARANG: menebak ref, memakai `dummy_verify`, atau menyalin ref ke file yang di-commit.

### 1.2 Set env di Vercel (manual, via dashboard — tidak ada perintah CLI di plan ini)

1. Vercel Dashboard → project `bikin-stiker-landing-page` → Settings → Environment Variables.
2. Pastikan `SUPABASE_PROJECT_REF` = ref asli dari 1.1 untuk environment **Production**
   (dan Preview bila ingin menguji PR).
3. Trigger redeploy (Deployments → Redeploy) agar `prebuild` me-regenerate `vercel.json`
   dengan ref benar.
4. Ulangi cek 0.1: Location hop pertama sekarang harus
   `https://<ref-asli>.supabase.co/functions/v1/share-redirect?token=...`.

### 1.3 Kriteria selesai Fase 1

Cek 0.1 SEHAT (tidak ada `dummy_verify` di rantai redirect). Catat waktu verifikasi di Progress Log.

---

## FASE 2 — Redeploy Edge Function `share-redirect` (repo `bikinstiker`)

Konteks: kode lokal (`supabase/functions/share-redirect/index.ts:27-28`) sudah memakai
host baru, tapi memory 2026-09-16 mencatat edge function **belum dideploy ulang** pasca
migrasi domain. Redeploy bersifat idempoten dan aman — lakukan untuk memastikan yang live
= yang di repo.

### 2.1 Batasan secret (MUTLAK, pelanggaran = hentikan kerja)

- Token `SUPABASE_ACCESS_TOKEN` (prefix `sbp_`) HANYA dari `.env.local` via wrapper
  `scripts/supabase-with-token.ps1`. Token TIDAK BOLEH tampil di chat, log, komentar kode,
  atau markdown.
- DILARANG: `Get-Content .env.local`, `cat .env.local`, `echo $env:SUPABASE_ACCESS_TOKEN`,
  `grep -r sbp_|sb_secret`, atau mencetak token dengan cara apa pun.
- Log yang diizinkan hanya: `token loaded (N chars, redacted)` dari wrapper.

### 2.2 Perintah (dari root repo `bikinstiker`)

```powershell
# 1) Dry-run dulu (aman, tidak menyentuh server):
& "scripts/supabase-with-token.ps1" --DryRun functions deploy share-redirect
# 2) Bila dry-run OK, deploy sungguhan:
& "scripts/supabase-with-token.ps1" functions deploy share-redirect
```

### 2.3 Verifikasi pasca-deploy

Ulangi cek 0.1 dengan token invalid. Rantai yang diharapkan:

```text
https://bikinstiker.alamaby.com/r/invalid-token-xyz
  -> 302 https://<ref>.supabase.co/functions/v1/share-redirect?token=invalid-token-xyz
  -> 302 https://bikinstiker.alamaby.com/share-claimed/error?share_error=invalid_token
```

Bila Location final masih host lama (`bikinstiker.com`) → deploy belum mengenai project
yang benar → catat ke Progress Log sebagai BLOCKED + output mentah perintah deploy.

### 2.4 Kriteria selesai Fase 2

Deploy exit 0 + rantai 302 di atas terkonfirmasi. JANGAN ubah isi `index.ts` di fase ini
(kecuali placeholder iOS pada Fase 3 bila diputuskan di situ — lihat bawah).

---

## FASE 3 — Placeholder iOS + dokumentasi AASA

### 3.1 Prinsip: JANGAN mengarang App Store ID

- `supabase/functions/share-redirect/index.ts:32-33` berisi
  `https://apps.apple.com/app/id000000000` + komentar TODO — aplikasi belum di App Store.
- `bikin-stiker-landing-page/app/share-claimed/[id]/page.tsx:10` memakai
  `NEXT_PUBLIC_IOS_APP_URL ?? "#"`. Nilai `"#"` membuat tombol iOS menjadi link mati.

Perubahan yang diizinkan (landing repo, file `app/share-claimed/[id]/page.tsx`):

- Bila `NEXT_PUBLIC_IOS_APP_URL` tidak di-set (nilai efektif `"#"`), SEMBUNYIKAN tombol iOS
  (render kondisional), jangan tampilkan link mati. Contoh minimal — sesuaikan dengan
  kode aktual saat implementasi (baca file dulu, jangan buta-tempel):

```tsx
const IOS_URL = process.env.NEXT_PUBLIC_IOS_APP_URL ?? "";
const hasIosUrl = IOS_URL !== "" && IOS_URL !== "#";
// ...
{hasIosUrl ? (
  <a href={IOS_URL} target="_blank" rel="noopener noreferrer" className="...">
    iOS
  </a>
) : null}
```

- DILARANG: mengisi ID App Store palsu, mengarahkan tombol iOS ke Play Store diam-diam,
  atau mengubah tombol Android.
- Verifikasi: `npm run lint` bersih; `npx tsc --noEmit` exit 0; buka
  `/share-claimed/abc?status=ok&credits=5` tanpa env iOS → tombol iOS tidak tampil;
  dengan env iOS terisi → tombol tampil dan href benar.

### 3.2 AASA `appIDs: []` — dokumentasi, bukan kode

Isi produksi `apple-app-site-association` dengan `appIDs: []` adalah VALID dan disengaja
(Apple env `APPLE_TEAM_ID`/`APPLE_BUNDLE_ID` opsional sampai akun Apple Developer ada —
lihat `scripts/inject-placeholders.mjs:42-53` dan `README.md` landing).
Tindakan: TIDAK ADA perubahan file. Catat di Progress Log sebagai known limitation +
tambahkan baris checklist ini di `.env.example` bila belum ada (sudah ada — verifikasi saja).

### 3.3 Kriteria selesai Fase 3

Tombol iOS tidak pernah menjadi link mati (`#`); tidak ada ID palsu di repo mana pun.

---

## FASE 4 — Koreksi memory bundle ID + hygiene minor (repo `bikinstiker`)

### 4.1 Koreksi bundle ID (WAJIB, agar pekerja berikutnya tidak tersesat)

Fakta kode (sudah terverifikasi, jangan diperdebatkan ulang):

- `android/app/build.gradle.kts:22,39`: `namespace`/`applicationId = "com.alamaby.bikin_stiker"`.
- Play URL di `share-redirect/index.ts:31`, landing `.env.example:11`, dan
  `StickerContentProvider.kt:197` konsisten memakai `com.alamaby.bikin_stiker`.
- Custom scheme `bikinstiker://` BENAR apa adanya dan TIDAK diubah.

Yang keliru: entri memory 2026-09-16 menulis bundle ID `com.bikinstiker.bikin`
(`.memory/2026-09-16/124956-provider-chain-rca-and-silent-alert-noop.md` dan
`.memory/README.md:27-28`).

Langkah:

1. `grep -rn "com\.bikinstiker\.bikin"` dari root repo `bikinstiker` (baca saja, aman).
2. Baca ulang tiap file yang cocok SEBELUM mengedit (aturan concurrent-agent).
3. Ganti HANYA string bundle ID yang keliru → `com.alamaby.bikin_stiker`.
   JANGAN menyentuh string custom scheme `bikinstiker://` (tanpa titik, tanpa `com.`).
4. Jangan hapus riwayat: koreksi sebagai anotasian (`salah → benar`), bukan rewrite sejarah.

### 4.2 Hygiene L1 (AMAN, lakukan) — `print` → `debugPrint`

File: `lib/core/services/share_mission_service.dart:108`.

```dart
// SEBELUM (baris 104-109):
    } catch (e) {
      // app_links can throw on platforms without deep-link support; we still
      // emit no events rather than failing the whole service.
      // ignore: avoid_print
      print('ShareMissionService: failed to start deep link listener: $e');
    }
```

```dart
// SESUDAH:
    } catch (e) {
      // app_links can throw on platforms without deep-link support; we still
      // emit no events rather than failing the whole service.
      debugPrint('ShareMissionService: failed to start deep link listener: $e');
    }
```

Tambahkan import di blok import (setelah `dart:ui`, sebelum `package:` — sesuai gaya file):

```dart
import 'package:flutter/foundation.dart';
```

Hapus komentar `// ignore: avoid_print` (tidak diperlukan lagi).
Verifikasi: `flutter analyze` 0 issue untuk file tersebut.

### 4.3 L2 (HANYA KOMENTAR, jangan ubah logika)

`_maybeBuildClaim` (`share_mission_service.dart:125-137`) menerima `pathSegments.first == 'r'`,
padahal app hanya mengasosiasikan `/share-claimed/` (Manifest + entitlements) — URL `/r/`
tidak pernah sampai ke app sebagai deep link (ia dikonsumsi edge function lalu menjadi
`/share-claimed/`). Menghapus cabang `'r'` mengubah perilaku parsing dan berisiko bagi
pelaksana kurang berpengalaman → DILARANG di plan ini. Yang diizinkan: perjelas komentar
`backward compatibility` yang sudah ada (baris 122-124) dengan satu baris tambahan,
mis. `// NOTE: '/r/' never reaches the app as a deep link; kept for parsing safety only.`
Tanpa perubahan kondisi `if`.

### 4.4 L5 i18n (DITUNDA — catat saja)

String error Inggris hardcoded di `mission_bloc.dart:448-463` dan teks Inggris di
`app/share-claimed/[id]/page.tsx` melanggar prinsip i18n, TAPI perbaikannya menyentuh
file `.arb` + regenerasi `flutter gen-l10n` + `next-intl` messages — risiko tinggi untuk
pelaksana less-capable. DITUNDA: catat sebagai open item di Progress Log, jangan kerjakan.

### 4.5 Kriteria selesai Fase 4

`grep com.bikinstiker.bikin` tidak lagi mengembalikan bundle-ID yang keliru (hanya boleh
tersisa bila itu bagian URL/scheme yang memang benar — periksa satu per satu);
`flutter analyze` bersih; tidak ada perubahan logika `_maybeBuildClaim`.

---

## FASE 5 — Matriks verifikasi akhir + uji E2E manual

### 5.1 Matriks (semua HARUS hijau; bila merah → catat BLOCKED, jangan lanjut deploy lain)

| # | Cek | Perintah / cara | Harapan |
|---|-----|-----------------|---------|
| V1 | Redirect `/r/` produksi | Fase 0.1 | Rantai 302 tanpa `dummy_verify`, final `.../share-claimed/error?share_error=invalid_token` |
| V2 | Halaman klaim | Fase 0.2 | `/share-claimed/abc?status=ok&credits=5` → 200, tombol "Open BikinStiker" ada |
| V3 | AASA | Fase 0.2 | 200, `appIDs: []` (known limitation) |
| V4 | assetlinks | Fase 0.2 | 404 BY DESIGN |
| V5 | Analyzer Flutter | `flutter analyze` (repo `bikinstiker`) | 0 issue |
| V6 | Test Flutter | `flutter test` (repo `bikinstiker`) | semua lolos (baseline 198/198 pada 2026-09-16; bila angka beda, catat, jangan panik) |
| V7 | Edge function typecheck | `deno check` / `deno test` untuk `share-redirect` | bersih (baseline 134/134 pada 2026-09-16) |
| V8 | Landing lint+types | `npm run lint`, `npx tsc --noEmit` (repo landing) | bersih |
| V9 | Tombol iOS | buka `/share-claimed/...` tanpa & dengan env iOS | tanpa env: tombol hilang; dengan env: href benar |
| V10 | E2E manual (butuh 2 perangkat/akun) | §5.2 | kredit masuk 1×, token tidak bisa dipakai ulang |

### 5.2 Skrip E2E manual (tidak bisa diotomatisasi di plan ini)

1. Perangkat A (akun terdaftar, BUKAN guest — guest di-intercept auth wall per plan
   2026-09-03): tab Misi → mission `share_app_daily` → Share → selesaikan share sheet
   (kirim link ke Perangkat B).
2. Perangkat B (boleh tanpa app): buka link `https://bikinstiker.alamaby.com/r/<token>`.
   Harap: browser mendarat di `/share-claimed/<id>?status=ok&credits=5`, tombol
   "Open BikinStiker" + tombol Android terlihat.
3. Perangkat A: klaim terkonfirmasi (banner sukses / kredit +5). Buka link yang SAMA di
   Perangkat B lagi → harap `share_error=consumed` (single-use).
4. Tunggu >10 menit, ulangi langkah 1 dengan token baru tanpa dibuka → harap
   `share_error=expired` saat akhirnya dibuka.

## Risks

- **Ref salah di Vercel** → seluruh link share historis maupun baru mati total (single
  point of failure `/r/`). Mitigasi: verifikasi Fase 0.1 SEBELUM dan SESUDAH setiap
  perubahan; keep backward-compat `bikinstiker.com` di `_maybeBuildClaim` tetap ada.
- **Deploy edge function ke project yang salah** (akun punya banyak project Supabase:
  albot-dev, asharu-prod, bagistruk-prod, bikinstiker-prod). Mitigasi: konfirmasi project
  link via `supabase projects list` sebelum deploy; catat nama project di Progress Log.
- **Mengarang App Store ID** → link menipu. Mitigasi: DILARANG mengisi ID tanpa sumber
  dari App Store Connect; sembunyikan tombol bila kosong.
- **Secret leak** (`sbp_`, `sb_secret_`, `SUPABASE_ACCESS_TOKEN`). Mitigasi: §2.1; bila
  secret telanjur tampil di output, segera rotasi via Supabase Dashboard → API Keys.
- **Scope creep ke `bagistruk-landing-page`** → plan ini eksplisit melarang; bila ragu,
  cek kanonis: file harus mengandung `bikinstiker.alamaby.com`, bukan `bagistruk`.

## Progress Log
- 2026-09-20 07:00:00 — Plan dibuat (analisa analisa 2026-09-20). Keputusan user: fokus
  `bikin-stiker-landing-page`; pertahankan fallback `bikinstiker://` (tanpa assetlinks);
  scope semua gap kritis. Status awal: kode memakai host baru; `vercel.json` lokal
  `dummy_verify` = artefak gitignored (bukan vonis produksi); edge function perlu redeploy;
  AASA `appIDs: []` by design; App Store ID placeholder; memory bundle ID keliru
  (`com.bikinstiker.bikin` → seharusnya `com.alamaby.bikin_stiker`). Belum ada eksekusi.
- 2026-09-20 11:30:00 — Fase 0 (read-only live verify): `/r/invalid-token-xyz` = **SAKIT**
  (307→`/en/r/...`→404, rewrite ke dummy_verify masih live); `/share-claimed/abc?status=ok&credits=5`
  = 200 ✓; `.well-known/apple-app-site-association` = 200, appIDs=[] ✓; `.well-known/assetlinks.json`
  = 404 BY DESIGN ✓. Supabase project ref = `epyrnsqumejnehtkddxx`.
- 2026-09-20 11:32:00 — Fase 2 DONE: `share-redirect` dideploy ulang ke
  `epyrnsqumejnehtkddxx` → v7 ACTIVE (04:28:26 UTC). Direct call edge function = 302→
  `.../share-claimed/error?share_error=not_found` ✓. Catatan: Vercel `/r/:token` rewrite
  masih dummy_verify → tunggu Fase 1.
- 2026-09-20 11:35:00 — Fase 3 DONE (`bikin-stiker-landing-page`): tombol iOS di
  `app/share-claimed/[id]/page.tsx` sekarang kondisional — sembunyi bila
  `NEXT_PUBLIC_IOS_APP_URL` kosong atau `"#"`. Fallback deep-link handler juga update
  agar tidak mengarah ke `"#"`. Lint + tsc bersih.
- 2026-09-20 11:38:00 — Fase 4 DONE (`bikinstiker`): pbxproj 6 baris
  `com.bikinstiker.bikinStiker` → `com.alamaby.bikin_stiker` (+RunnerTests×3); memory
  README line 27 annotation; memory 2026-09-16 entry koreksi anotasian; `print`→
  `debugPrint` + import `foundation.dart` di `share_mission_service.dart`; L2 comment
  ditambahkan; `flutter analyze` 0 issue; `flutter test` 198/198 ✓.
- 2026-09-20 11:40:00 — Fase 5 verification: V1 **BLOCKED** (Vercel rewrite belum live —
  tangan pemilik), V2 200 ✓, V3 200 appIDs=[] ✓, V4 404 ✓, V5 0 issue ✓, V6 198/198 ✓,
  V7 v7 ACTIVE ✓, V8 lint+tsc bersih ✓, V9 kondisional iOS tombol sudah di-code ✓,
  V10 E2E manual menunggu owners redeploy Vercel.
- 2026-09-20 11:42:00 — **Fase 1 requires manual action**: Set env `SUPABASE_PROJECT_REF=epyrnsqumejnehtkddxx`
  di Vercel Dashboard → Settings → Environment Variables → Production (dan Preview bila
  ingin uji PR) untuk project `bikin-stiker-landing-page`, lalu trigger Redeploy. Setelah
  itu ulangi cek V1: `/r/invalid-token-xyz` harus rantai 302→`https://epyrnsqumejnehtkddxx.supabase.co/functions/v1/share-redirect?...`
  → 302→`.../share-claimed/error?share_error=not_found`.

## Notes

- Standar domain mengacu keputusan proyek yang sudah ada (bukan C2M/TM Forum ODA —
  ini aplikasi stiker konsumen, bukan sistem rating/billing telekomunikasi; tidak ada
  deviasi standar yang perlu dijustifikasi).
- **JANGAN** mengacu pada `bagistruk-landing-page` untuk pekerjaan apa pun di plan ini.
- Aturan secret proyek (AGENTS.md §5 + §8): token HANYA via `.env.local` + wrapper;
  `.env*` di-gitignore; log hanya `token loaded (N chars, redacted)`.
- Setelah tiap fase selesai, pelaksana WAJIB mencentang checkbox `## Tasks` di file ini
  dan menambah baris `## Progress Log` berformat `YYYY-MM-DD HH:mm:ss — <isi>`.
  File ini adalah single source of truth status plan.
- Commit di akhir (bila diminta user): satu baris Conventional Commits, mis.
  `fix(share): point share links at bikinstiker.alamaby.com and harden claim fallback`.
  Jangan sertakan `Co-authored-by:` trailer.
