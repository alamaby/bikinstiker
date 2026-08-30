# Plan: bikin-stiker-landing-page (Vercel)

Created: 2026-07-06 12:30:00

## Objective

Single Vercel deployment at `bikinstiker.com` covering two responsibilities:

1. **Share-mission infrastructure**: serve `/.well-known/apple-app-site-association`, `/.well-known/assetlinks.json`, dynamic `/share-claimed/[id]` fallback HTML, and `/r/[token]` rewrite that 302-redirects to the existing Supabase Edge Function `share-redirect`.
2. **Marketing landing pages**: Home (Hero + Features + How-it-works + Showcase + CTA), Pricing, FAQ, Privacy, Terms — EN + ID.

## Stack (decided)

- Next.js 15 App Router (React Server Components) + TypeScript.
- Tailwind CSS + Shadcn/ui.
- `next-intl` for EN + ID with `[locale]` segment + middleware-based locale detection.
- `@next/mdx` for FAQ / Privacy / Terms content.
- Vercel Analytics (opt-in, off by default).
- Lucide icons.

## Constraints & Assumptions

- Repo: sibling `bikin-stiker-landing-page` at `C:\Works\github.com\alamaby\bikin-stiker-landing-page`. Currently empty (`.git/` only).
- Auto-deploy on push to `main`.
- Custom domain `bikinstiker.com` is owned and configured in Vercel.
- User must supply before production: `APPLE_TEAM_ID`, `ANDROID_SHA256_FINGERPRINT` (release key), real `NEXT_PUBLIC_IOS_APP_URL`.
- No backend of its own; reuse existing `share-redirect` Edge Function for mission logic.
- Out of scope: blog, pricing checkout (in-app), user auth, dynamic OG per page.

## Repository Layout

```
bikin-stiker-landing-page/
  app/
    [locale]/
      layout.tsx                  # Header (locale switcher) + Footer
      page.tsx                    # Home
      pricing/page.tsx
      faq/page.tsx
      privacy/page.tsx
      terms/page.tsx
      share-claimed/[id]/page.tsx # Fallback HTML + client redirect
    globals.css
  components/
    ui/                           # Shadcn primitives (button, card, accordion, dialog)
    home/                         # hero, features, how-it-works, showcase, cta
    pricing/pricing-table.tsx
    faq/faq-accordion.tsx
    share-claimed/open-app-button.tsx  # Client component
  content/                        # MDX source
    faq.en.mdx, faq.id.mdx
    privacy.en.mdx, privacy.id.mdx
    terms.en.mdx, terms.id.mdx
  messages/
    en.json, id.json
  public/
    .well-known/
      apple-app-site-association  # placeholders injected from env
      assetlinks.json
    showcase/01.webp ... 12.webp  # 6-12 sticker samples
    logo.svg, og-default.png, favicon.ico
  scripts/
    inject-placeholders.mjs       # prebuild: fills .well-known from env
    generate-vercel-json.mjs      # prebuild: interpolates SUPABASE_PROJECT_REF
  middleware.ts                   # next-intl locale detection
  next.config.mjs
  vercel.json
  .env.example
  README.md
```

## Key Routes

| Path | Type | Notes |
| --- | --- | --- |
| `/.well-known/apple-app-site-association` | static | Placeholder → injected at build |
| `/.well-known/assetlinks.json` | static | Placeholder → injected at build |
| `/r/[token]` | rewrite (302) | → `https://${SUPABASE_PROJECT_REF}.supabase.co/functions/v1/share-redirect?token=:token` |
| `/share-claimed/[id]` | RSC | Status from query (`?status=ok&credits=N` or `?share_error=...`); meta-refresh + client-side attempt to `bikinstiker://share-claimed/<id>`; visible CTA + store links |
| `/`, `/pricing`, `/faq`, `/privacy`, `/terms` | RSC | Localised via `[locale]` |

## Share-Mission URL Flow

1. User taps Share in app → MissionBloc mints token (Flutter side done).
2. Native share sheet sends text containing `https://bikinstiker.com/r/<token>`.
3. Recipient taps the link.
4. Vercel rewrite in `vercel.json` → 302 to Supabase Edge Function URL.
5. Edge Function `consume_share_token()` → 302 to `https://bikinstiker.com/share-claimed/<id>?status=ok&credits=<N>`.
6. Vercel serves `/share-claimed/[id]`; page attempts to open `bikinstiker://share-claimed/<id>`.
7. App opens via App / Universal Link → MissionsScreen drains cold-start claim → success snackbar.

## vercel.json (template)

```json
{
  "redirects": [
    {
      "source": "/r/:token",
      "destination": "https://__SUPABASE_PROJECT_REF__.supabase.co/functions/v1/share-redirect?token=:token",
      "statusCode": 302
    }
  ]
}
```

`__SUPABASE_PROJECT_REF__` is replaced by `scripts/generate-vercel-json.mjs` at `prebuild`.

## Environment Variables (Vercel dashboard)

| Var | Used by | Example |
| --- | --- | --- |
| `SUPABASE_PROJECT_REF` | `/r/[token]` rewrite | `abcdefghij` |
| `APPLE_TEAM_ID` | apple-app-site-association | `ABCDE12345` |
| `ANDROID_SHA256_FINGERPRINT` | assetlinks.json | `AA:BB:CC:...` |
| `NEXT_PUBLIC_SITE_URL` | SEO canonical | `https://bikinstiker.com` |
| `NEXT_PUBLIC_APP_DOWNLOAD_URL` | Store CTAs | `https://play.google.com/store/apps/details?id=com.alamaby.bikin_stiker` |
| `NEXT_PUBLIC_IOS_APP_URL` | App Store CTA | (real URL, currently unknown) |

`scripts/inject-placeholders.mjs` runs in `prebuild` and aborts the build if any `<PLACEHOLDER>` remains unsubstituted.

## Tasks

1. `pnpm dlx create-next-app@latest bikin-stiker-landing-page --ts --app --tailwind` then move files into the sibling repo.
2. Add deps: `next-intl`, `@next/mdx`, `@tailwindcss/typography`, `class-variance-authority`, `clsx`, `tailwind-merge`, `lucide-react`.
3. `npx shadcn@latest init`; add primitives `button`, `card`, `accordion`, `dialog`.
4. Configure `next-intl`: `[locale]` segment, `i18n.ts`, `middleware.ts`, `messages/{en,id}.json`.
5. Build `app/[locale]/layout.tsx` (header w/ locale switcher + footer).
6. Build home page sections as RSC: `HeroSection`, `FeaturesGrid`, `HowItWorks`, `ShowcaseGallery` (loads static `/showcase/*.webp`), `CtaBanner`.
7. Author MDX content files (FAQ, Privacy, Terms) × EN + ID. Source from `bikinstiker/docs/*.md` for legal pages.
8. Build routes: `/pricing`, `/faq`, `/privacy`, `/terms`.
9. Build `app/[locale]/share-claimed/[id]/page.tsx` + `OpenAppButton` client component. Includes `<meta http-equiv="refresh">` instant attempt + JS fallback at 250 ms + visible "Open in BikinStiker" + store CTAs.
10. Place placeholder `public/.well-known/apple-app-site-association` + `assetlinks.json`.
11. Write `scripts/inject-placeholders.mjs` (prebuild) and `scripts/generate-vercel-json.mjs` (prebuild).
12. Add `.env.example` + README (env vars + deploy steps + iOS/Android validation links).
13. Push to GitHub, create Vercel project, set env vars, attach `bikinstiker.com` custom domain.
14. After first deploy, verify Universal / App Links:
    - iOS: <https://branch.io/resources/aasa-validator/>
    - Android: <https://developers.google.com/digital-asset-links/tools/test-apk-asset-association>
15. Replace placeholder content (real App Store URL, real Team ID, real SHA-256) once user supplies them.

## Validation Commands (for the implementer to run later)

```bash
pnpm install
pnpm dev                                  # http://localhost:3000 → redirect to /en or /id
pnpm build                                # confirm prebuild scripts inject placeholders

curl -I https://bikinstiker.com/.well-known/apple-app-site-association
curl -I https://bikinstiker.com/.well-known/assetlinks.json
curl -I https://bikinstiker.com/r/SAMPLETOKEN
curl -i 'https://bikinstiker.com/share-claimed/<UUID>?status=ok&credits=5'
```

## Risks & Mitigations

- **Placeholders ship to production** → silent Universal/App Link failure. Mitigated by aborting build when any `<PLACEHOLDER>` remains.
- **`bikinstiker://` stripped by some chat apps** → fallback chain: meta-refresh, JS, manual button, store links.
- **`[locale]` segment collision** with top-level routes → always nest under `app/[locale]/...`.
- **Vercel env not set before first production deploy** → redirects break. Documented checklist in README.

## Follow-ups (post-plan, user-side)

- Supply real values for: `APPLE_TEAM_ID`, `ANDROID_SHA256_FINGERPRINT` (release), `NEXT_PUBLIC_IOS_APP_URL`.
- Optionally add separate Android debug SHA-256 for preview environments.
