# Surprise Me Review Fixes Plan

Created: 2026-08-25 14:30:00

## Objective
Memperbaiki seluruh temuan code review implementasi Surprise Me AI Enhancement:
1 temuan critical (env var salah → function mati di produksi), 1 high UX
(dialog saldo 0), 2 medium (double-wrap error, API widget menyesatkan),
rate-limit feedback, dan catatan ops VALIDATE constraint.

Keputusan user: perbaiki SEMUA temuan actionable + dialog dengan CTA Missions.

## Scope
- `supabase/functions/surprise-me/index.ts` + `index_test.ts`
- `supabase/migrations/20260825000001_surprise_me_ai.sql` (komentar header saja — belum di-deploy)
- `lib/data/repositories/surprise_me_repository.dart`
- `lib/presentation/widgets/surprise_me_button.dart`
- `lib/presentation/screens/home/home_screen.dart`
- `lib/l10n/app_{en,id}.arb` (+2 key) + generated
- `pubspec.yaml`, TODO.md, PROJECT_MEMORY.md

## Temuan & Perbaikan
| ID | Severity | Temuan | Fix |
|----|----------|--------|-----|
| H1 | Critical | `index.ts:266` baca env `SUPABASE_SERVICE_ROLE`; runtime inject `SUPABASE_SERVICE_ROLE_KEY` → semua request 500 di produksi | Ganti nama var + test kontrak yang membaca source file assert env name benar |
| H2 | High UX | Dialog: `balance - 1` render "-1 credit" saat saldo 0; OK tetap aktif → 402 belakangan | Pre-check insufficient: judul/pesan notEnoughCredits, tombol utama jadi CTA ke MissionsScreen, tanpa angka negatif |
| M1 | Medium | `fetchQuota`: ServerFailure tertangkap catch generik → double-wrap UnknownFailure | `on Failure rethrow` sebelum catch |
| M2 | Medium | SurpriseMeButton: internal randomSuggestionFor mati (parent abaikan suggestion); props presetId/textOnly/avoid tak terpakai | Refactor jadi `enabled` + `VoidCallback onPressed`; call site dirapikan |
| M3 | Low | RateLimitedFailure → snackbar generik; retryAfterSeconds tersedia | Key baru `surpriseWaitSeconds({seconds})`, failure handler switch per tipe |
| L1 | Ops | Drop+re-add CHECK constraint menghapus status VALIDATE migrasi lama; tanpa catatan re-VALIDATE | Catatan manual VALIDATE di header migration + deploy checklist TODO |

Out of scope (backlog): skip-enhancement ganda saat generate dari hasil
surprise; unit test wrapper RPC/repository.

## Tasks
- [x] T1 (H1): Env var fix (`SUPABASE_SERVICE_ROLE_KEY`) + contract test env name
      (test command kini butuh `--allow-read` untuk Deno.readTextFile)
- [x] T2 (H2): Dialog pre-check insufficient + CTA Missions (goMissions flag +
      navigasi ter-guard mounted; saldo tak pernah render negatif)
- [x] T3 (M1): fetchQuota `on Failure rethrow`
- [x] T4 (M2): SurpriseMeButton refactor VoidCallback (props presetId/textOnly/
      avoid dihapus); call site dirapikan
- [x] T5 (M3): l10n `surpriseWaitSeconds({seconds})` + `surpriseTopUpViaMissions`
      EN/ID; failure handler switch per tipe Failure
- [x] T6 (L1): Header migration catatan manual VALIDATE + preflight query;
      TODO deploy checklist SME6 diperluas
- [x] T7: Verifikasi — deno surprise-me 10/10 (--allow-read), generate-sticker
      80/80, flutter analyze 0 issues, test 138/138, build apk 3 ABI sukses
- [x] T8: Bump versi patch `0.20.1+71`
- [x] T9: PROJECT_MEMORY.md + progress log
- [ ] T10: Commit + push (dikerjakan setelah entry ini)

## Risks
- Test kontrak membaca source sendiri brittle terhadap reformat; mitigasi:
  assert longgar (substring nama env, bukan posisi baris).
- Dialog kini bisa menavigasi ke MissionsScreen; wajib guard `mounted`
  setelah `await showDialog`.
- Perubahan kecil lainnya bersifat mekanis.

## Progress Log
- 2026-08-25 14:30:00 — Plan dibuat setelah review + keputusan user (semua
  temuan + CTA Missions). Implementasi dimulai.
- 2026-08-25 15:20:00 — Semua fix selesai (T1–T9). Catatan eksekusi:
  contract test env-name butuh `--allow-read` pada perintah deno test
  (terdokumentasi di memory); dart format menolak file .ts (aman, hanya
  file .dart yang diformat). Verifikasi penuh hijau.
