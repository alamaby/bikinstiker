# Supabase From-Address + db push + Function Deploy

Date: 2026-09-23
Topic: supabase-from-deploy

## Task

1. Set email `from` ke `noreply@updates.alamaby.com`.
2. Bantu `supabase db push` dan deploy edge function.

## Files Changed

- `.env.example` — `OPERATOR_ALERT_FROM` placeholder (2 lokasi: definisi +
  contoh `secrets set`) diganti ke
  `BikinStiker Alerts <noreply@updates.alamaby.com>` + catatan verifikasi
  domain subdomain di Resend.

## Decisions

- Kode (`operator_alerts.ts:231`) membaca `from` dari env, tidak ada alamat
  hardcoded — jadi perubahan hanya di placeholder + live secret.
- Live secret di-set via wrapper (tanpa redeploy, per catatan `.env.example`):
  `secrets set OPERATOR_ALERT_FROM="BikinStiker Alerts
  <noreply@updates.alamaby.com>"` → sukses.
- Deploy ulang 3 function yang tertunda sejak Fase 7 domain
  (`share-redirect`, `surprise-me`, `generate-sticker`) → ketiganya
  `Deployed Functions on project epyrnsqumejnehtkddxx`.
- `.env.example` DIBIARKAN uncommitted (user tidak minta commit).

## Assumptions / Risks

- Subdomain `updates.alamaby.com` diasumsikan tercakup verifikasi root
  `alamaby.com` di Resend — WAJIB dikonfirmasi di resend.com/domains + test
  kirim sebelum diandalkan, kalau tidak API return 403.
- Sender SMTP Auth Supabase (Dashboard) masih manual — set ke
  `noreply@updates.alamaby.com` agar konsisten dengan template OTP.

## Blockers (RESOLVED 2026-09-23)

- `db push` awalnya GAGAL: remote punya migrasi yatim `20260923005310`
  (applied 2026-09-23 00:53 UTC / 07:53 WIB) tanpa file lokal. User
  mengonfirmasi isinya `sticker_moderation_flag` dari sesi lain.
- Investigasi read-only menemukan objeknya: `sticker_generations.is_flagged`
  (boolean NOT NULL DEFAULT false), `flagged_at` (timestamptz NULL),
  `flag_reason` (text NULL), + index
  `sticker_generations_flagged_created_idx (is_flagged, created_at DESC)`.
- Perbaikan: tulis backfill
  `supabase/migrations/20260923005310_sticker_moderation_flag.sql` (versi sama,
  DDL ekuivalen defensif IF NOT EXISTS, non-destruktif) → `db push` =
  `Remote database is up to date.` → `migration list` 1:1 sinkron penuh.
  TIDAK memakai `repair` (riwayat tetap jujur).

## Verification

- `supabase migration list` — semua versi lokal == remote kecuali yatim di atas.
- `secrets set` → `Finished supabase secrets set.`
- Deploy ×3 → `Deployed Functions on project epyrnsqumejnehtkddxx` (peringatan
  `Docker is not running` dan CLI v2.116.0 vs v2.117.0 adalah noise).
- Token tidak pernah tercetak (wrapper log `redacted`).

## Commit Proposal

`chore(config): set operator alert from to noreply@updates.alamaby.com`

## Related

- Plan: `plans/2026-09-22-email-otp-login-plan.md` (S8 SMTP)
- Memory: `.memory/2026-09-16/124956-provider-chain-rca-and-silent-alert-noop.md`
  (Fase 6 Resend)
