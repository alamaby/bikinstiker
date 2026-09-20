# BikinStiker Landing Sync Plan (app truth → bikinstiker.alamaby.com)

Created: 2026-09-16 14:30:00

## Objective

Selaraskan `bikin-stiker-landing-page` (live di `https://bikinstiker.alamaby.com`) dengan kondisi terkini aplikasi Flutter `bikinstiker`, terutama Privacy Policy dan Terms of Service. Sumber kebenaran legal = `bikinstiker/docs/*.md`. Pricing berbayar = roadmap (beri label, jangan hapus). Kontak tunggal = `alam.aby.b@gmail.com`. Android App Links = tetap fallback `bikinstiker://` (tanpa `assetlinks.json`, sesuai plan 2026-09-14).

## Scope

- In scope (repo `bikin-stiker-landing-page`):
  - `app/[locale]/privacy/page.tsx`, `app/[locale]/terms/page.tsx` → render penuh dari `docs/` (EN+ID, locale-aware), ganti email `.example`/`.com` → gmail, ganti `[TO_BE_FILLED_BY_LEGAL]` → `BikinStiker`.
  - `messages/en.json`, `messages/id.json` → pricing faktual + label roadmap, FAQ/kontak benar, tambah key `roadmap`/`current`/`contactEmail`.
  - `components/pricing/pricing-table.tsx` → badge Roadmap untuk Plus/Pro.
  - `components/home/features-grid.tsx` (via messages) → hilangkan klaim Instagram/Telegram/unlimited/4K+API.
  - `app/layout.tsx`, `README.md` → kanonis `https://bikinstiker.alamaby.com` (hapus fallback `bikinstiker.com`).
  - Verifikasi `npm run build` + `npm run lint`.
- Out of scope:
  - Edge function `share-redirect`, Supabase DB/migrasi, kode Flutter — tidak disentuh.
  - `assetlinks.json` — tetap tidak dibuat (keputusan fallback #4).
  - Apple AASA — tetap `appIDs: []` sampai Apple Developer tersedia.
  - Rotasi secret / set Vercel env `SUPABASE_PROJECT_REF` — manual di dashboard (dicatat, bukan dikerjakan di repo).

## Milestones

1. Legal sinkron (P0) — privacy/terms faktual, locale-aware
2. Pricing/FAQ faktual + Roadmap (P1)
3. Domain/SEO/kontak (P2) + build hijau

## Tasks

- [x] Analisa gap landing vs app (read-only, plan mode)
- [x] P0: tulis ulang `privacy/page.tsx` + `terms/page.tsx` dari `docs/` (EN+ID via locale conditional, kontak gmail)
- [x] P0: ganti kontak `privacy@bikinstiker.com` / `legal@bikinstiker.com` / `.example` → `alam.aby.b@gmail.com`
- [x] P1: update `messages/en|id.json` pricing → Free 5 kredit/2 slot (Current), Plus 50 kredit/20 slot (Roadmap), Pro roadmap tanpa klaim 4K/API
- [x] P1: tambah badge Roadmap di `pricing-table.tsx` untuk Plus/Pro (+ roadmapNote)
- [x] P1: perbaiki features/FAQ (WhatsApp saja, slot 2/20, tanpa store-billing fiksi) + header pricing/FAQ locale-aware
- [x] P2: fix `metadataBase` fallback + `README.md` → `bikinstiker.alamaby.com`
- [x] Verifikasi: `npm run lint` (0 error, 10 warning pre-existing) + `npm run build` (14/14 static, dengan `SUPABASE_PROJECT_REF=dummy_verify` lokal; Vercel wajib set var riil)
- [ ] Update memory entry + deploy Vercel + uji live `/en|id/privacy|terms|pricing`

## Risks

- `docs/` sendiri masih berisi `[TO_BE_FILLED_BY_LEGAL]` + wallet cap stale (50 vs DB 150/10000) — me-render apa adanya hanya memindah masalah. Mitigasi: ganti entity → `BikinStiker`, catat utang sinkron wallet-cap di Notes; butuh review legal lanjutan.
  - Counter-argument: menunda sampai legal sempurna membuat landing tetap salah lebih lama; lebih baik faktual-sekarang + tandai sisa.
- Gmail pribadi sebagai kontak legal terlihat kurang profesional dan berisiko spam/akuisisi; tapi itu instruksi eksplisit user (#3). Mitigasi: gunakan `mailto:` link, catat rekomendasi migrasi ke `privacy@alamaby.com` + domain mail di Notes.
- Label Roadmap pada harga ($2.99/$5.99) tetap bisa dibaca sebagai janji harga. Mitigasi: tambah disclaimer "Harga rencana, dapat berubah" + CTA mengarah ke Play Store (unduh gratis), bukan checkout.
- Fallback `bikinstiker://` tanpa App Links = link dibuka browser dulu (trade-off yang sudah diterima di plan 2026-09-14). Tidak diubah di sini.

## Progress Log

- 2026-09-16 14:30:00 — Plan dibuat (build mode). Keputusan user: (1) docs sebagai sumber, (2) pricing = roadmap, (3) kontak alam.aby.b@gmail.com, (4) fallback custom scheme.
- 2026-09-16 14:35:00 — Mulai implementasi P0 di repo landing.
- 2026-09-16 15:00:00 — Implementasi selesai di working tree landing (belum commit/deploy): privacy/terms EN+ID penuh + gmail, pricing faktual + badge Current/Roadmap + roadmapNote, features/FAQ dikoreksi, metadataBase + README kanonis, header pricing/FAQ locale-aware. Lint 0 error (10 warning pre-existing: hero/cta locale unused, open-app-button dead code). Build OK 14/14 (SUPABASE_PROJECT_REF=dummy_verify lokal). Catatan: `.gitignore` termodifikasi pre-existing (`.vercel`, `.env*`) — bukan oleh task ini, dibiarkan. Sisa: commit di repo landing, set SUPABASE_PROJECT_REF riil di Vercel, uji live.
- 2026-09-16 15:10:00 — Commit + push landing selesai: `89407e8 fix(landing): sync privacy terms pricing with app truth plus roadmap badges` (9 file, `main` 8a32816..89407e8). `.gitignore` pre-existing tetap dibiarkan unstaged. Sisa: deploy Vercel (pastikan `SUPABASE_PROJECT_REF` riil ter-set) + uji live `/en|id/privacy|terms|pricing`.

## Notes

- Kanonis: `https://bikinstiker.alamaby.com`. `bikinstiker.com`/`bikinstiker.app` tidak pernah terdaftar — semua fallback/README harus diganti.
- Bundle IDs: Android `com.alamaby.bikin_stiker` (Play, benar di landing); iOS `com.bikinstiker.bikinStiker` (mismatch, di luar scope landing).
- Provider aktual untuk privacy: Supabase, Google AdMob, Google Sign-In, Pixazo, OpenRouter, Gemini, Pollinations, Mistral (reasoning), WhatsApp on-device. Rantai reasoning aktif per RCA 2026-09-16: ollama → openrouter → cerebras zai-glm-4.7 → gpt-oss-120b.
- Fakta tier aktual (DB): Free 5 kredit/bln + 2 slot, Plus 50 kredit/bln + 20 slot; starter 1+4=5; 1 gen = 1 kredit; expiry 30 hari; refund on fail; wallet cap DB 150/10000 (docs tulis 50 — utang sinkron).
- Utang lanjutan (bukan plan ini): `share-claimed/[id]` i18n, validasi `SUPABASE_PROJECT_REF` di Vercel, AASA Apple env, sinkron wallet-cap docs↔DB, alamat legal resmi, migrasi email ke domain sendiri.
