# Privacy v2026-10-15: Gemini unpaid disclosure — 2026-10-15

## Task / Problem
Keputusan owner: Gemini tetap unpaid. Konsekuensi: Privacy Policy wajib
mengungkapkan bahwa kuota gratis Gemini dipakai Google untuk training/
improvement (+ human review). Baris Gemini yang menyebut "(paid fallback)"
sudah tidak faktual.

## Key files changed
- `docs/privacy-policy-en.md`: baris Gemini -> unpaid-quota fallback +
  training-use notice + link terms; seksi baru 4.1 (AI training use on
  unpaid tiers, no sensitive info, withdrawal tidak menarik data provider);
  Last Updated 2026-10-15 (Effective tetap).
- `docs/privacy-policy-id.md`: mirror ID (4.1 penggunaan data pelatihan).
- `lib/data/repositories/legal_consent_repository.dart`:
  `currentPrivacyVersion` 2026-07-03 -> 2026-10-15 (bundle kembali match
  dengan terms 2026-10-15).
- `test/legal_documents_test.dart`: ekspektasi 2026-10-15 + assertion
  disclosure (EN: unpaid-quota/improve,develop/do not submit sensitive;
  ID: kuota gratis/peninjau manusia).
- `supabase/migrations/20261015000003_privacy_v2026_10_15_gemini_unpaid.sql`
  (NEW, submodule): retire privacy current, insert 2026-10-15
  en `321b769d…`, id `30cbf1d2…` (hash match file).
- Landing `app/[locale]/privacy/page.tsx`: tanggal + baris Gemini +
  catatan training-use ID+EN (lint + tsc bersih, BELUM deploy Vercel).

## Decisions
- Unpaid + disclosure (bukan billing-aktif). Counter: menakutkan sebagian
  user privasi-sensitif; alternatif billing menambah biaya ±$1/bulan pada
  volume kini — ditolak owner, catat untuk evaluasi ulang.

## Assumptions / Risks
- Material privacy change -> re-acceptance seluruh user setelah `db push` +
  rilis APK berisi docs baru (pola mismatch sama seperti ToS).
- Privacy ID tidak punya header tanggal (pre-existing) — hanya EN yang
  diupdate Last Updated.

## Verification
- `flutter test test/legal_documents_test.dart`: 6/6 passed.
- Landing `npm run lint` + `npx tsc --noEmit`: bersih.
- `flutter analyze` TIDAK diulang (perubahan docs + 1 konstanta).

## Blockers
- Migrasi `20261015000003` SUDAH `db push` 2026-10-15 (registry: terms +
  privacy 2026-10-15 current, hash match). APK baru BELUM build;
  landing BELUM deploy.

## Commit proposal
submodule: `feat(legal): register privacy v2026-10-15 gemini unpaid disclosure`
superproject: `docs(legal): disclose gemini unpaid training use`
landing: `docs(landing): sync privacy to gemini unpaid disclosure`
