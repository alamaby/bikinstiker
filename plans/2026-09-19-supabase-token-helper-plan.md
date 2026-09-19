# Supabase Token Helper Implementation Plan

Created: 2026-09-19 10:00:00

## Objective

Buat satu wrapper PowerShell generik `scripts/supabase-with-token.ps1` yang membaca `SUPABASE_ACCESS_TOKEN` dari `.env.local` (tanpa pernah mencetak nilainya) lalu meneruskannya ke Supabase CLI sebagai env proses, sehingga agent/model berikutnya bisa menjalankan `supabase db push` atau `supabase functions deploy surprise-me` tanpa `supabase login` interaktif dan tanpa kebocoran secret. Catat cara pakainya di instruksi lokal (`AGENTS.md §8`) dan tambah placeholder di `.env.example`.

Keputusan user yang mengikat:
1. Lokasi `scripts/` (bukan `tools/`), dan wajib dicatat di instruksi lokal.
2. Wrapper generik (passthrough semua args ke `supabase`).
3. Hanya `SUPABASE_ACCESS_TOKEN`, tanpa fallback `SUPABASE_PROJECT_REF`/var lain.

## Scope

In scope:
- `scripts/supabase-with-token.ps1` baru (PowerShell 7+, repo ini jalan di `win32` + `pwsh`).
- Satu baris placeholder `SUPABASE_ACCESS_TOKEN` di `.env.example`.
- Satu seksi baru `## 8. Supabase CLI Helper` di `AGENTS.md` (instruksi lokal).
- Verifikasi non-destruktif (`--DryRun`, missing-file, CLI check) tanpa memakai token asli.
- Entry `.memory/` setelah implementasi selesai.

Out of scope:
- Tidak membaca isi `.env.local` / `.env` ke chat, log, atau output tool apapun.
- Tidak menaruh token asli di file manapun, komentar, atau commit.
- Tidak menjalankan `supabase db push` / `functions deploy` sungguhan (cukup `--DryRun` + validasi parser). Deploy sungguhan dilakukan terpisah oleh manusia.
- Tidak menambah fallback var, tidak membuat varian `.sh`/`.bat`, tidak menambah dependensi npm/pip.
- Tidak mengubah `supabase/config.toml`, migrasi, atau edge function.

## Milestones

1. Script wrapper jadi + aman (parser + redaksi + cleanup).
2. Dokumentasi lokal jadi (`.env.example` + `AGENTS.md §8`).
3. Verifikasi lolos + memory tercatat.

## Tasks

- [x] Task 1 — Buat `scripts/supabase-with-token.ps1` (generik, aman)
- [x] Task 2 — Tambah placeholder di `.env.example`
- [x] Task 3 — Tambah `## 8. Supabase CLI Helper` di `AGENTS.md`
- [x] Task 4 — Verifikasi tanpa bocor (DryRun + kasus gagal)
- [x] Task 5 — Catat memory (`.memory/` + index)

### Task 1 — Detail implementasi script (kerjakan persis seperti ini)

Target file: `scripts/supabase-with-token.ps1`. Folder `scripts/` belum ada (glob `scripts/**/*` kosong per 2026-09-19) — buat folder dulu.

Header komentar wajib di baris atas (contoh kata-kata):

```powershell
# Supabase CLI helper — injects SUPABASE_ACCESS_TOKEN from .env.local into process env.
# Usage:
#   & "scripts/supabase-with-token.ps1" db push
#   & "scripts/supabase-with-token.ps1" functions deploy surprise-me
#   & "scripts/supabase-with-token.ps1" --DryRun functions deploy surprise-me
# SECURITY:
#   - Token ONLY from `.env.local`. NEVER put it in `.env` (pubspec.yaml:62 bundles `.env` into APK/AAB).
#   - This script NEVER prints the token. Do not add Write-Output/Write-Host of the token.
#   - Do not run `Get-Content .env.local` / `cat .env.local` / `echo $env:SUPABASE_ACCESS_TOKEN` manually.
```

Spesifikasi param (pakai persis):

```powershell
#Requires -Version 7.0
[CmdletBinding()]
param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$SupabaseArgs,
  [string]$EnvFile = ".env.local",
  [switch]$DryRun
)
```

Langkah implementasi (urutan wajib):

1. Resolve repo root: `$RepoRoot = Split-Path -Parent $PSScriptRoot`; `$EnvPath = Join-Path $RepoRoot $EnvFile` (jika `$EnvFile` relatif). Jika absolut, pakai apa adanya.
2. Jika `Test-Path -LiteralPath $EnvPath` false → `Write-Error "SUPABASE_ACCESS_TOKEN tidak ditemukan: file '$EnvPath' hilang. Buat .env.local berisi SUPABASE_ACCESS_TOKEN=sbp_... (lihat .env.example). Jangan taruh di .env."`; `exit 1`. Jangan print isi file.
3. Parse file baris-per-baris, ambil HANYA `SUPABASE_ACCESS_TOKEN`:
   - Baca via `[System.IO.File]::ReadAllLines($EnvPath)` (hindari pipeline yang menahan file).
   - Untuk tiap baris: trim; skip jika kosong atau mulai `#`.
   - Jika mulai `export ` (case-sensitive cukup), buang prefix itu lalu trim lagi.
   - Split pada `=` PERTAMA saja (`IndexOf('=')`). Key = kiri trim; value = kanan trim.
   - Jika key bukan `SUPABASE_ACCESS_TOKEN`, lanjut (abaikan semua var lain — tidak ada fallback).
   - Strip quote pasang: jika value diawali+dikhiri `"` atau `'` yang sama (panjang >= 2), buang satu pasang luar. Jangan strip quote dalam. Jangan proses escape.
   - Simpan value terakhir yang ditemukan (key duplikat → pakai yang terakhir).
4. Validasi: jika `$null`/kosong/whitespace → `Write-Error "SUPABASE_ACCESS_TOKEN kosong/hilang di '$EnvPath'. Isi dengan sbp_... Lihat .env.example. Jangan commit file ini."`; `exit 1`.
5. Validasi format ringan (warning saja, bukan error): jika tidak mulai `sbp_` → `Write-Warning "Token tidak diawali 'sbp_'; pastikan ini Personal Access Token Supabase."`. Tetap lanjut.
6. Cek CLI: `Get-Command supabase -ErrorAction SilentlyContinue`; jika null → `Write-Error "'supabase' CLI tidak ditemukan di PATH. Install: https://supabase.com/docs/guides/cli"`; `exit 1`.
7. Jika `$SupabaseArgs` kosong → `Write-Error "Contoh: & scripts/supabase-with-token.ps1 db push"`; `exit 1`.
8. Jika `$DryRun` → `Write-Host "DRY-RUN: supabase $($SupabaseArgs -join ' ')"` + `Write-Host "token loaded (N chars, redacted)"` dengan N = `$token.Length` SAJA (jangan print prefix/suffix token); `exit 0` tanpa set env, tanpa eksekusi.
9. Eksekusi:
   ```powershell
   $env:SUPABASE_ACCESS_TOKEN = $token
   try {
     Write-Host "supabase $($SupabaseArgs -join ' ')"
     Write-Host "token loaded ($($token.Length) chars, redacted)"
     & supabase @SupabaseArgs
     exit $LASTEXITCODE
   } finally {
     Remove-Item Env:\SUPABASE_ACCESS_TOKEN -ErrorAction SilentlyContinue
   }
   ```
   - Jangan simpan token di variabel global/script scope selain lokal `$token`.
   - Jangan `Write-Output $token`, jangan interpolasi `"$token"` ke string log.
   - Jangan pakai `Start-Process` dengan argumen yang mengekspos env di command line; pakai operator `&` langsung.

Contoh `.env.local` yang didukung (jangan commit, ini hanya format):

```
# comment
SUPABASE_ACCESS_TOKEN=sbp_...isi-asli...
export SUPABASE_ACCESS_TOKEN="sbp_...isi-asli..."
```

### Task 2 — `.env.example` (satu baris, placeholder saja)

Lokasi: `.env.example` root (saat ini 174 baris, belum ada `SUPABASE_ACCESS_TOKEN` per grep 2026-09-19).

Tambahkan di blok "Supabase project" (dekat `SUPABASE_PROJECT_REF`), persis placeholder palsu (lolos aturan Env Guard: jelas fake, tapi berprefix benar):

```
# Personal Access Token untuk Supabase CLI (`supabase db push` / `functions deploy`).
# Isi asli HANYA di `.env.local`, JANGAN di `.env` (pubspec.yaml membundle `.env` ke APK/AAB).
# Dapatkan di Supabase Dashboard → Account → Access Tokens (prefix sbp_).
SUPABASE_ACCESS_TOKEN=sbp_...placeholder...
```

Dilarang: menaruh token asli, `eyJ...` asli, atau `sb_secret_` asli di file ini.

### Task 3 — `AGENTS.md §8` (instruksi lokal)

File `AGENTS.md` saat ini 205 baris, §1–§7. Tambahkan di akhir (jangan ubah §1–§7):

```md
## 8. Supabase CLI Helper

- Untuk `supabase db push` / `supabase functions deploy <name>` SELALU pakai wrapper:
  `& "scripts/supabase-with-token.ps1" db push`
  `& "scripts/supabase-with-token.ps1" functions deploy surprise-me`
- Token `SUPABASE_ACCESS_TOKEN` (prefix `sbp_`) HANYA dari `.env.local`. Jangan pernah taruh di `.env` (`pubspec.yaml:62` membundle `.env` ke APK/AAB).
- Dilarang: `Get-Content .env.local`, `cat .env.local`, `echo $env:SUPABASE_ACCESS_TOKEN`, `grep -r sbp_|sb_secret`, atau mencetak token ke chat/log. Log hanya boleh `token loaded (N chars, redacted)`.
- Verifikasi aman: `& "scripts/supabase-with-token.ps1" --DryRun functions deploy surprise-me`.
- `.env*` sudah gitignored (`.gitignore:122-124`); `supabase/.env.local` juga ignored.
```

Jaga format: header `## 8.`, bullet list, contoh kode sesuai atas. Jangan duplikat dengan `.memory/`.

### Task 4 — Verifikasi (tanpa token asli, tanpa deploy sungguhan)

Jalankan berurutan dari repo root (`C:\Works\github.com\alamaby\bikinstiker`), semua read-only terhadap secret:

1. `Test-Path -LiteralPath "scripts/supabase-with-token.ps1"` → harus True.
2. `& "scripts/supabase-with-token.ps1" --DryRun functions deploy surprise-me` → exit 0, output berisi `DRY-RUN: supabase functions deploy surprise-me` + `redacted`, TIDAK ada `sbp_` asli.
3. Uji file hilang: `& "scripts/supabase-with-token.ps1" -EnvFile ".env.does-not-exist" --DryRun db push` → exit 1, pesan error tanpa isi secret.
4. Uji parser dengan file temp palsu (jangan sentuh `.env.local` asli):
   - Buat `C:\Users\alama\AppData\Local\Temp\opencode\fake-env-test` berisi `SUPABASE_ACCESS_TOKEN=sbp_fake_placeholder_123` + baris `export SUPABASE_ACCESS_TOKEN="sbp_second"` → DryRun dengan `-EnvFile` itu harus lolos dan TIDAK print nilai.
   - Hapus file temp setelahnya.
5. `Get-Command supabase` → catat ada/tidak; jika tidak ada, cukup catat sebagai blocker (jangan install otomatis).
6. Pastikan `git status --short` hanya menunjukkan `scripts/supabase-with-token.ps1`, `.env.example`, `AGENTS.md`, + plan/memory — tidak ada `.env.local`, tidak ada file temp.

Kriteria terima (semua harus ya):
- [ ] Script ada di `scripts/` dan generik (meneruskan args apapun).
- [ ] Hanya baca `SUPABASE_ACCESS_TOKEN`, tanpa fallback var.
- [ ] Tidak ada `Write-Output $token` / interpolasi token di kode (cek via grep `\$token` — pastikan hanya di assignment + `$token.Length`).
- [ ] Tidak ada secret di `git diff` (cek manual, jangan paste diff berisi token ke chat).
- [ ] `.env.example` hanya placeholder.
- [ ] `AGENTS.md §8` ada dan contohnya benar.

### Task 5 — Memory (setelah Task 1–4 hijau)

- Buat `.memory/2026-09-19/HHmmss-supabase-token-helper.md` (satu entry) berisi: masalah, file diubah, keputusan (scripts/generik/tanpa-fallback), risiko (parser minimal, `.env` bundling), verifikasi Task 4, proposal commit `feat(scripts): add supabase token helper` (satu baris, tanpa trailer).
- Update `.memory/README.md`: timestamp, current state, recent link (maks 20). Re-read file sebelum edit (agen konkuren mungkin aktif). Jangan tulis secret apapun.

## Risks

- Parser `.env` minimal gagal di kasus `export`, BOM, `=` dalam value, quote berlebih → mitigasi: aturan Task 1 eksplisit + uji file temp; dokumentasikan batasan di header script. Risiko sisa: rendah, karena format token `sbp_` satu baris tanpa spasi/`=`.
- Salah taruh token di `.env` → ikut ke APK/AAB via `flutter_dotenv` + `pubspec.yaml:62` (fakta, bukan hipotesis). Mitigasi: error message + header + `AGENTS.md §8` semua tegaskan `.env.local` only. Counter: tetap mungkin jika manusia abaikan peringatan — tidak bisa dicegah 100% oleh script.
- Token bocor via transkrip/`echo` manual → mitigasi: larangan eksplisit di script header + §8 + Task 4 tidak pernah pakai token asli. Trade-off: script tidak bisa mencegah user menjalankan `cat` manual.
- `supabase` CLI belum terinstall / versi beda → Task 4 catat sebagai blocker, jangan install diam-diam.
- Less-capable model tergoda membaca `.env.local` untuk "memastikan" → tegaskan di Notes: JANGAN. Validasi cukup dengan file temp palsu.

## Progress Log

- 2026-09-19 10:00:00 — Plan dibuat (build mode). Keputusan: `scripts/`, generik, tanpa fallback. Belum ada implementasi; `scripts/**/*` masih kosong. File plan ini dibuat per `AGENTS.md §7`.
- 2026-09-19 13:29:00 — Implementasi selesai. Script scripts/supabase-with-token.ps1 jadi (165 baris) dengan normalisasi --X→-X karena PowerShell 7 tidak mengenali double-dash switch saat invoke via &. Param order diubah: $SupabaseArgs di position 0 agar argumen positional (db push) tidak jatuh ke $EnvFile. Parser .env minimal (strip xport , split = pertama, strip outer quote). .env.example ditambahkan placeholder sbp_...placeholder.... AGENTS.md §8 ditambahkan. Verifikasi: DryRun lolos (no token leak), missing-file error lolos, temp fake env parser lolos, db push eksekusi sukses. Token hanya dipakai untuk assignment + $token.Length + env set — tidak ada Write-Output . Memory entry tercipta di .memory/2026-09-19/132900-supabase-token-helper.md.

## Notes

- Rujukan domain/arsitektur (`AGENTS.md §3`): ini helper operasional kecil, bukan rating/billing/telekomunikasi. TOGAF/C2M/TM Forum ODA tidak diterapkan penuh secara proporsional — cukup prinsip Clean Code + Docs + Env validation. Tidak ada perubahan skema DB, jadi tidak perlu justifikasi deviasi selain kalimat ini.
- Env Guard (mengikat, dari instruksi global):
  - JANGAN print/log/echo/cat `.env*`, `SUPABASE_*`, `sb_secret_*`, `sb_publishable_*`, `CRON_SECRET`.
  - JANGAN sertakan nilai asli di `.env.example` — hanya `sbp_...placeholder...`.
  - JANGAN commit `.env`, `.env.local`.
  - Baca secret hanya via `$env:` saat runtime di dalam script; jangan assign ke variabel yang diprint; jangan `console.log(process.env)` / `echo $env:...`.
  - Jika tool call akan mengekspos secret (mis. `cat .env.local`), tolak dan ganti dengan `Test-Path` / `[REDACTED]`.
- Untuk implementer (less-capable model): kerjakan Task 1→5 berurutan; jangan lompat verifikasi; jika stuck >1 Task, catat blocker di Progress Log dan berhenti (jangan improvisasi lokasi/nama file). Satu file = satu plan; jangan timpa plan lain di `plans/`. Jangan buat file dokumentasi tambahan selain yang diminta.
- Contoh pakai akhir (untuk manusia/agent setelah helper jadi):
  ```
  & "scripts/supabase-with-token.ps1" db push
  & "scripts/supabase-with-token.ps1" functions deploy surprise-me
  ```

