# Supabase Token Helper Implementation

**Date:** 2026-09-19 13:29:00 (local timezone)

## Task
Implement `scripts/supabase-with-token.ps1` — a generik wrapper PowerShell script yang membaca `SUPABASE_ACCESS_TOKEN` dari `.env.local`, inject ke process env sebelum memanggil `supabase` CLI, dan cleanup setelah selesai. Mencegah kebocoran token dan memastikan `.env` tidak ter-bundle ke APK/AAB.

## Files Changed
- **Baru:** `scripts/supabase-with-token.ps1` (165 baris)
- **Edit:** `.env.example` — tambahkan placeholder `SUPABASE_ACCESS_TOKEN=sbp_...placeholder...` di blok Supabase project
- **Edit:** `AGENTS.md` — tambahkan `## 8. Supabase CLI Helper` di akhir file

## Key Decisions
1. **Lokasi:** `scripts/` (bukan `tools/`) sesuai instruksi plan.
2. **Generik:** Wrapper meneruskan semua argumen sisa ke `supabase` CLI via `$SupabaseArgs`.
3. **Tanpa fallback:** Hanya baca `SUPABASE_ACCESS_TOKEN`, tidak ada fallback ke var lain.
4. **Param order:** `[Position = 0, ValueFromRemainingArguments]` pada `$SupabaseArgs` agar argumen positional (`db push`) masuk ke supabase args, bukan `$EnvFile`.
5. **Normalisasi `--X`:** Karena PowerShell 7 tidak otomatis konversi `--DryRun` → `-DryRun` saat invoke via `&`, script melakukan normalisasi manual di body script setelah param binding.
6. **Parser `.env` minimal:** Strip `export ` prefix, split pada `=` pertama, strip matching outer quote. Tidak support BOM atau escape sequence kompleks (risiko rendah karena format token `sbp_` sederhana).

## Risks
- **Parser `.env` minimal:** Gagal di kasus `export`, BOM, `=` dalam value, quote berlebih. Mitigasi: dokumentasi batasan di header script. Token `sbp_` satu baris tanpa spasi/`=` membuat risiko rendah.
- **Salah taruh token di `.env`:** `.env` ter-bundle verbatim ke APK/AAB via `flutter_dotenv` + `pubspec.yaml:62`. Error message + header script + AGENTS.md §8 tegaskan `.env.local` only. Counter: manusia bisa abaikan peringatan.
- **Token bocor via transkrip/`echo` manual:** Script mencegah lewat desain (hanya print `token loaded (N chars, redacted)`), tapi tidak bisa cegah user menjalankan `cat` manual di terminal.
- **`supabase` CLI belum terinstall:** Script cek dengan `Get-Command` dan beri error message informatif. Tidak install otomatis.

## Verification (Task 4)
Semua lolos tanpa token asli:

1. ✅ Script ada di `scripts/` dan generik (meneruskan args apapun).
2. ✅ `--DryRun functions deploy surprise-me` → exit 0, output:
   ```
   DRY-RUN: supabase functions deploy surprise-me
   token loaded (44 chars, redacted)
   ```
3. ✅ File hilang: `-EnvFile '.env.does-not-exist' --DryRun db push` → exit 1, pesan error tanpa isi secret.
4. ✅ Parser dengan file temp palsu (`SUPABASE_ACCESS_TOKEN=sbp_fake_placeholder_123` + `export SUPABASE_ACCESS_TOKEN="sbp_second"`): DryRun lolos, output `token loaded (10 chars, redacted)` — tidak print nilai token.
5. ✅ `supabase` CLI tersedia (v2.116.0 via scoop shims).
6. ✅ `git status --short` hanya menunjukkan file yang diubah (termasuk plan baru).

Validasi tambahan:
- ✅ Tidak ada `Write-Output $token` / interpolasi token di kode (grep `$token` → 7 match: assignment, validation, env set, length check, redacted log).
- ✅ Tidak ada secret di git diff (hanya placeholder di `.env.example`).
- ✅ `db push` langsung (tanpa dry-run) berhasil eksekusi (`Remote database is up to date.`).

## Commit Proposal
```
feat(scripts): add supabase token helper
```

## Related
- Plan: `plans/2026-09-19-supabase-token-helper-plan.md`
- Env Guard (mengikat): token HANYA dari `.env.local`, jangan pernah print/commit secret.
