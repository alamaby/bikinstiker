# Migrasi Supabase Legacy Keys → sb_publishable / sb_secret

Created: 2026-08-30 10:06:00

## Objective
Analisa + implementasi migrasi dari legacy JWT API keys (`SUPABASE_ANON_KEY`/`SUPABASE_SERVICE_ROLE_KEY`, deprecated akhir 2026) ke new API keys (`sb_publishable_...`/`sb_secret_...`), dengan strategi dual-read helper agar lokal (CLI legacy-only), CI, dan produksi tetap jalan keduanya. Keputusan owner: implementasi langsung + dual-read (bukan SDK `@supabase/server`, bukan swap langsung).

## Analisa (ringkas — detail di PROJECT_MEMORY)
- Mapping: publishable→anon (RLS tetap), secret→service_role (BYPASSRLS). Bukan JWT; hanya header `apikey`. Kedua jenis jalan berdampingan sampai legacy di-disable manual (reversible).
- Platform inject env **plural JSON** ke Edge Functions: `SUPABASE_SECRET_KEYS` / `SUPABASE_PUBLISHABLE_KEYS` (`JSON.parse(...)['default']`), berdampingan dengan legacy vars. Setelah legacy di-disable, legacy vars mati (issue #37648).
- verify_jwt gateway hanya paham legacy — selama legacy aktif verifikasi user-JWT tetap jalan; saat disable: flip `verify_jwt=false` + auth in-function (auth.getUser() sudah ada di 7 function; admob-ssv/share-redirect public).
- Discrepancy ditemukan: admob-ssv & share-redirect (public, verifikasi sendiri) tidak punya `verify_jwt=false` di config.toml padahal migrasi 20260708000024 mendokumentasikannya.
- CI ping-supabase.yml memakai service_role di apikey+Authorization.
- Tidak berubah: RLS, storage signed URL, auth.getUser(), verifikasi Ed25519 admob, user access token (tetap JWT — migrasi "JWT signing keys" terpisah, out of scope).

## Tasks
- [x] F1a — NEW `supabase/functions/_shared/keys.ts`: `resolveSupabaseKeys()` + `resolveAnonKey()` (dual-read JSON baru → fallback legacy) + `keys_test.ts` (6/6; +`_shared/deno.json` import map).
- [x] F1b — Swap deklarasi env di 10 functions (nol perubahan logika).
- [x] F1c — Update 3 test kontrak env-name; config.toml + verify_jwt=false admob-ssv & share-redirect.
- [x] F2 — Flutter dual-read (PUBLISHABLE ?? ANON), .env.example, README, ping workflow fallback sb_secret, pubspec `0.23.2+79`.
- [x] F3 — Verifikasi penuh + docs (checklist hari-H disable legacy) + commit & push.

## Risks
- Nama env plural non-intuitif — ditangani helper + test.
- Disable legacy bisa memicu "Invalid JWT" (#41834) — checklist disable-day: flip verify_jwt=false + deploy; reversible.
- Local CLI legacy-only — fallback helper wajib dipertahankan.
- `.env` owner campuran lama/baru — dual-read Flutter menoleransi keduanya.

## Progress Log
- 2026-08-30 10:06 — Plan dibuat & disetujui (implementasi + dual-read).
- 2026-08-30 11:05 — Implementasi selesai, semua verifikasi hijau (deno 156: keys 6 + generate-sticker 109 + surprise-me 15 + list-presets 7 + showcase 13+6; analyze 0; test 183/183; APK 3 ABI). Catatan: (1) `_shared/` butuh deno.json sendiri untuk resolve `std/assert`; (2) `deno check` admob-ssv & migrate-guest-stickers gagal **pre-existing** (WebCrypto typing — terverifikasi gagal juga di HEAD via stash), sarankan dibereskan terpisah.

## Notes
- Tanpa migrasi DB. Checklist disable-day di TODO.md; sumber resmi: docs migrasi & API keys, GH discussion #29260, issue #37648, discussion #41834.
