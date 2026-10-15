# ToS Commercial Rights Revision (option b) — 2026-10-15

## Task / Problem
Provider sticker (Pixazo Free `flux-1-schnell` + Pollinations `flux` fallback)
tidak memberi hak milik penuh; ToS 6.2 mengklaim lisensi komersial penuh
(distribute/sublicense permanen). Sinkronkan ToS ke opsi b: lisensi
terbatas upstream + atribusi + IP clearance + disclosure AI.

## Key files changed
- `docs/terms-of-service-en.md`: 5.1 rantai aktif (Pixazo primary +
  Pollinations fallback; SDXL/OpenRouter/Gemini disabled; dev variants
  disabled; metadata logged), 5.2 (no uniqueness/copyright warranty,
  Apache-2.0 vs provider terms, atribusi), 6.2 (limited/revocable/
  non-transferable/non-sublicensable/limited-commercial, Pixazo Free
  ownership, UU 28/2014, IP clearance, EU AI Act disclosure), header
  Last Updated 2026-10-15.
- `docs/terms-of-service-id.md`: mirror ID (dapat dicabut, Pixazo Free,
  FLUX.1-schnell, Klirens).
- `lib/data/repositories/legal_consent_repository.dart`:
  `currentTermsVersion` 2026-07-03 -> 2026-10-15 (privacy tetap 2026-07-03).
- `test/legal_documents_test.dart`: ekspektasi split-version + assertion
  klausul baru (revocable/non-transferable/Pixazo Free/FLUX.1-schnell/
  IP clearance; ID: dapat dicabut/Klirens).
- `supabase/migrations/20261015000001_terms_v2026_10_15_commercial_rights.sql`
  (NEW, non-destructive): retire terms current, insert terms 2026-10-15
  en `6114d7d9...93dc77`, id `66dfd136...66d65b8b`. Privacy hash
  re-verified unchanged (en `4c1b0689...`, id `be5b950b...`).
- Verifikasi: rantai aktif hanya `pixazo/flux-1-schnell` x3 + `pollinations/flux`;
  `sdxl-base-1.0` dan `ming-image-0.1-design` confirmed `is_active=false`;
  chain-of-title sudah tersimpan (`sticker_generations.provider_name/
  model_name/provider_config_id` di `generate-sticker/index.ts:2264-2280` +
  `image_generation_attempt_logs`), tanpa perubahan kode.

## Decisions
- Opsi 1b (revisi ToS bersyarat), bukan upgrade Pixazo Paid.
- Self-host ditolak user (tidak bisa) — tetap via provider.
- Split-versioning: terms bump saja (material), privacy tidak bergerak.
  Test lockstep `terms==privacy` diganti eksplisit split.

## Assumptions / Risks
- Hash = SHA-256 bytes UTF-8 file; tervalidasi via privacy hash yang match
  DB persis sebelum migrasi dibuat.
- RISIKO DEPLOY: `LegalConsentScreen` memblokir Continue saat hash lokal !=
  hash server current. Push migrasi sebelum APK baru rilis memblokir user
  lama; rilis APK sebelum push memblokir user baru. Koordinasikan:
  push migrasi + rilis APK ber-ToS-baru dalam jendela yang sama, umumkan
  wajib update. Ini material change (hak user berkurang) -> wajar memaksa
  re-accept.
- Counter: ToS lebih restriktif dapat menurunkan konversi komersial user;
  alternatif (upgrade Pixazo Paid) ditolak user — catat untuk evaluasi
  ulang bila keluhan muncul.

## Blockers / Unresolved
- Migrasi BELUM di-push (`supabase db push` via wrapper) — sengaja, butuh
  keputusan jendela rilis dari owner.
- APK/AAB baru berisi docs revisi BELUM di-build.
- `db push` TERHALANG aturan read-only MCP + butuh koordinasi rollout di atas.

## Verification
- `flutter test test/legal_documents_test.dart`: 6/6 passed.
- `flutter analyze`: No issues found.
- Full `flutter test` + `build apk` TIDAK dijalankan (perubahan docs +
  konstanta; proporsional).

## Commit proposal
`docs(legal): limit sticker license to upstream provider terms`

## Related
- Prior art: `plans/2026-08-02-server-side-legal-consent-audit-plan.md`,
  migrasi `20260802000034_server_side_legal_consent.sql`.
- Open item lama "ToS v2" kini terwujud sebagai v2026-10-15 (terms-only).
