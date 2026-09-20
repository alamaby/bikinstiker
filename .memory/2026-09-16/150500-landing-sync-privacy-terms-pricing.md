# Landing sync: privacy/terms/pricing faktual (bikinstiker.alamaby.com)

Date: 2026-09-16 15:05:00

## Task / Problem

Landing `bikin-stiker-landing-page` (live `bikinstiker.alamaby.com`) menyimpang dari aplikasi: privacy/terms ringkasan generik EN-only, pricing fiksi (Free 20/5, Plus 100/unlimited $2.99, Pro $5.99 + 4K/API), klaim share Instagram/Telegram + unlimited packs + store-billing, kontak `@bikinstiker.com` vs docs `.example`, fallback kanonis `bikinstiker.com` yang tak terdaftar.

## Key files changed

Repo `bikin-stiker-landing-page` (working tree, belum commit):
- `app/[locale]/privacy/page.tsx`, `app/[locale]/terms/page.tsx` — tulis ulang penuh dari `bikinstiker/docs/*` (11/18 seksi, EN+ID conditional, tanggal 2026-07-03)
- `messages/en.json`, `messages/id.json` — pricing faktual + key `current`/`roadmap`/`roadmapNote`, features/FAQ dikoreksi
- `components/pricing/pricing-table.tsx` — badge Current (Free) / Roadmap (Plus/Pro) + roadmapNote
- `app/[locale]/pricing/page.tsx`, `app/[locale]/faq/page.tsx` — header locale-aware
- `app/layout.tsx`, `README.md` — kanonis `https://bikinstiker.alamaby.com`

Plan: `bikinstiker/plans/2026-09-16-bikinstiker-landing-sync-plan.md`

## Decisions

- Legal source = `docs/` (jawaban user #1).
- Paid Plus/Pro = roadmap berlabel, bukan dihapus (#2). Free = Current (5 kredit/2 slot); Plus roadmap (50/20); Pro roadmap (300/20+, klaim 4K/API dibuang).
- Kontak tunggal `alam.aby.b@gmail.com` (#3); entity `[TO_BE_FILLED_BY_LEGAL]` → `BikinStiker`.
- Android = fallback `bikinstiker://` + tombol Play Store, tanpa `assetlinks.json` (#4, pertahankan plan landing 2026-09-14). Open item lama "host assetlinks di Vercel" tidak berlaku lagi.

## Assumptions / Risks

- `docs/` sendiri masih stale soal wallet cap (tulis 50; DB 150/10000) — landing sengaja tidak mempublikasikan angka cap, hanya tier/slot.
- Gmail pribadi sebagai kontak legal kurang profesional + rawan spam; rekomendasi lanjutan: `privacy@alamaby.com` + verify domain.
- Harga roadmap ($2.99/$5.99) ditambah disclaimer "dapat berubah"; tetap bisa dibaca sebagai janji — risiko diterima user.
- Tanpa assetlinks, link https dibuka browser dulu (trade-off diterima 2026-09-14).

## Blockers / Unresolved

- Commit + push + deploy Vercel di repo landing (belum dilakukan).
- `SUPABASE_PROJECT_REF` riil wajib di-set di Vercel (build lokal pakai dummy hanya untuk verifikasi).
- Uji live `/en|id/privacy|terms|pricing|faq` pasca-deploy.
- Lanjutan: i18n `share-claimed/[id]`, AASA Apple env, sinkron wallet-cap docs↔DB, alamat legal resmi.

## Verification

- `npm run lint` — 0 error, 10 warning pre-existing (hero/cta `locale` unused, `open-app-button` dead code).
- `npm run build` (dengan `SUPABASE_PROJECT_REF=dummy_verify`) — OK, 14/14 static routes (`/en|id`, pricing, faq, privacy, terms, share-claimed dynamic).
- `git status` landing — 9 file sumber diubah + `.gitignore` pre-existing (`.vercel`, `.env*`, bukan oleh task ini); generated `vercel.json`/`apple-app-site-association` tetap ter-ignore.

## Commit proposal

`fix(landing): sync privacy terms pricing with app truth plus roadmap badges`

## Related

- Plan: `plans/2026-09-16-bikinstiker-landing-sync-plan.md`
- App docs: `docs/privacy-policy-en|id.md`, `docs/terms-of-service-en|id.md`
- Landing plans: `2026-09-14-remove-android-sha256-fingerprint-requirement.md` (fallback), `2026-09-12-gitignore-cleanup-plan.md`
