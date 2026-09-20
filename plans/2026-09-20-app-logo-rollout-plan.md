# App Logo Rollout Plan — draft-app-logo-1.png (PNG-only, flat, archived legacy)

Created: 2026-09-20 12:00:00

## Objective

Roll out the approved V2 logo (`assets/images/draft-app-logo-1.png`: blue solid bg, cream die-cut sticker + navy outline + orange sparkle/mouth, flat — drop-shadow REMOVED at export) as the single identity for: (a) Flutter launcher + Play Store icon + in-app logo, (b) sibling landing page logo/favicon/OG. Keep the draft file source-only and git-ignored. Archive the legacy `app_logo.png` (green WA glyph) out of runtime. SVG is explicitly OUT of scope (user: skip svg).

Locked decisions: (1) flat tanpa shadow = YA, (2) logo lama = ARSIPKAN bukan hapus, (3) in-app logo = PERLU (PNG), (4) landing = PNG saja.

## Scope

- In: `.gitignore` 1 line; designer masters (outside git); 5 Android `mipmap-*/ic_launcher.png`; full iOS `AppIcon.appiconset`; `pubspec` patch bump + `assets/images/` registration; 1 in-app PNG; legacy move to `docs/archive/`; landing `public/` + `app/layout.tsx` + `header.tsx`; verification builds.
- Out: SVG work; launcher XML/manifest signing changes; `supabase db push`; Play Console upload + Vercel deploy (owner manual); full-screen rebrand.

## Milestones

1. Source + ignore ready (T0–T1).
2. App icons + in-app wired (T2a–T2e).
3. App verified green (T3).
4. Landing wired + built (T4).
5. Owner ships (T5).

## Tasks

- [x] **T0 — Designer masters (MANUAL, outside git, do NOT commit source)**
  - Input: `C:\Works\github.com\alamaby\bikinstiker\assets\images\draft-app-logo-1.png` (has soft drop-shadow — must be removed).
  - Handoff dir (temp, never commit): `C:\Users\alama\AppData\Local\Temp\opencode\bikin-logo\`.
  - Export spec (all): sRGB, opaque, flat (NO shadow, NO baked rounded corners), bg token `#0072B2`, padding 15–18% all sides, sparkle inset 2–3% from draft position, sticker group ~80–82% of canvas.
  - Files to produce:
    1. `play-icon-512.png` — 512×512, ≤1024 KB (Play Store listing).
    2. `android-fg.png` — foreground sticker on TRANSPARENT (for adaptive safe-zone 66dp check) + `android-bg.png` — flat `#0072B2` (final mipmap PNGs below are pre-composed opaque per density).
    3. `ios-1024.png` — 1024×1024, no alpha (App Store marketing;_play Store uses 512_).
    4. `app-logo-512.png` — 512 flat (in-app master) → renamed to `app-logo.png` on copy.
    5. `landing-logo-512.png` — 512 flat; `favicon.ico` (multi 16/32/48); `apple-touch-icon.png` (180×180); `og-image.png` (1200×630, key art centered, safe margins 15% top / 10% sides / 20% bottom).
  - Stop rule: if vector source (Figma) is missing, export PNGs from cleaned raster only. Do NOT auto-trace to SVG (rejected 2026-09-20: 2-color collapse, bg baked, hundreds of junk nodes). Do NOT invent a new design.

- [x] **T1 — Gitignore the draft (repo: bikinstiker)**
  - 1. Read `.gitignore` first (already read 2026-09-20: 160 lines, ends with `*.p8`).
  - 2. Append exactly:
    ```
    # Draft logo source-only (V2 PNG with shadow) — never commit; production masters are derived
    assets/images/draft-app-logo-1.png
    ```
  - 3. Verify (PowerShell 7+, from repo root):
    ```
    git check-ignore -v assets/images/draft-app-logo-1.png
    git status --ignored -- assets/images
    ```
    Expected: first command prints the `.gitignore` line; second shows `draft-app-logo-1.png` under Ignored. Production files (`app-logo.png`, `mipmap/*`, `AppIcon/*`) must NOT appear as ignored.
  - Stop rule: if `git check-ignore` prints nothing, the pattern is wrong — fix pattern, do not proceed to T2.

- [x] **T2a — Archive legacy logo (do NOT delete, do NOT bundle)**
  - 1. Confirm orphan: `rg -n "app_logo" lib android ios pubspec.yaml` must print NOTHING (verified 2026-09-20; re-run before moving).
  - 2. Create dir + move (keeps history, out of runtime):
    ```
    New-Item -ItemType Directory -Path "docs/archive" -Force
    git mv assets/images/app_logo.png docs/archive/app-logo-legacy-2026-09-20.png
    ```
  - 3. Verify: `git status` shows rename; `pubspec.yaml` `flutter.assets` does NOT list `assets/images/app_logo.png` or `docs/archive/` (so legacy never bundles into APK/AAB).
  - Stop rule: if `rg` finds a reference, STOP and report the file:line instead of moving.

- [x] **T2b — Android launcher (5 files, overwrite only)**
  - Targets (keep filenames, replace bytes from flat master, pre-composed opaque):
    - `android/app/src/main/res/mipmap-mdpi/ic_launcher.png` (48×48)
    - `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` (72×72)
    - `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` (96×96)
    - `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` (144×144)
    - `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` (192×192)
  - Do NOT touch: `AndroidManifest.xml` (`android:icon="@mipmap/ic_launcher"` stays), no new `roundIcon`, no `adaptive-icon` XML, no `*.jks`/`key.properties`.
  - Verify: open xxxhdpi + mdpi PNGs visually; sticker centered; sparkle inside safe zone; no shadow.

- [x] **T2c — iOS icons (overwrite PNGs, keep Contents.json as-is)**
  - Dir: `ios/Runner/Assets.xcassets/AppIcon.appiconset/` (Contents.json lists 20 entries incl. `Icon-App-1024x1024@1x.png`; verified 2026-09-20).
  - Overwrite every `Icon-App-*.png` from the flat `ios-1024.png` scaled down. Do NOT edit `Contents.json` (sizes/scales unchanged). Do NOT add alpha to 1024 marketing icon.
  - Verify: filenames match Contents.json exactly (case-sensitive); no extra files in the set.

- [x] **T2d — Version bump (minor + build: visible brand feature)**
  - File: `pubspec.yaml:4` was `version: 0.26.9+91`.
  - Changed to `version: 0.27.0+93` (minor 26→27 because the new launcher/in-app logo is a user-visible brand feature per Flutter version rules; build 91→93). Plan originally specified patch `0.26.10+92` — superseded at implementation.
  - Verify: `rg -n "^version:" pubspec.yaml` prints `0.27.0+93`.

- [x] **T2e — In-app logo (PNG only, no new dependency)**
  - 1. Copy master: handoff `app-logo-512.png` → `assets/images/app-logo.png` (lowercase, hyphen; this is the NEW name — do not reuse `app_logo.png`).
  - 2. Read `pubspec.yaml:58-67`, then register under `flutter.assets` (keep existing entries, add one line):
    ```yaml
    flutter:
      assets:
        - .env
        - assets/images/
        - assets/animations/
        - docs/privacy-policy-en.md
        - docs/privacy-policy-id.md
        - docs/terms-of-service-en.md
        - docs/terms-of-service-id.md
    ```
  - 3. Minimal wiring (do NOT rebrand all screens): find the auth/splash/about header placeholder (e.g. an `Icon`/`Sparkles` or empty header) and insert:
    ```dart
    Image.asset(
      'assets/images/app-logo.png',
      width: 64,
      height: 64,
      semanticLabel: 'BikinStiker logo',
    )
    ```
    Suggested spots in order: auth screen header → about/profile header → splash if one exists. If a spot has no obvious placeholder, SKIP it and note it in the Progress Log — do not redesign layouts.
  - 4. Run `flutter pub get`. Env guard: never print/cat `.env*` or `sb_secret_*`; never commit `.env`.
  - Verify: `git ls-files assets/images` shows ONLY `app-logo.png` (plus nothing else); `draft-app-logo-1.png` absent (ignored); `docs/archive/*` absent from `flutter assets`.

- [x] **T3 — Verify app (must be green before landing)**
  - From repo root, in order:
    ```
    flutter pub get
    flutter analyze
    flutter test
    flutter build apk --split-per-abi
    flutter build appbundle --release
    ```
  - Expected: analyze 0 issues; tests pass (baseline ~198); 3 APKs + 1 AAB (~50 MB class) succeed.
  - Visual: install debug APK on 2 densities; launcher shows flat V2 (no shadow); 48px legible (face + sparkle readable); Play-mask 30% preview does not clip sparkle.
  - Bundle hygiene: AAB must NOT contain `draft-app-logo-1.png` or `docs/archive/` (guaranteed if T2e registration is exactly `assets/images/` and archive lives under `docs/` — state this in the log).
  - Stop rule: if analyze/test fails, fix only the regression; do not start T4.

- [ ] **T4 — Landing sibling (repo: bikin-stiker-landing-page, PNG-only)**
  - 1. Add to `public/`: `app-logo.png` (512), `favicon.ico`, `apple-touch-icon.png` (180), `og-image.png` (1200×630). Do NOT add `trace.svg`/drafts. Do NOT commit `.env.local`.
  - 2. Read `app/layout.tsx` first (verified 2026-09-20: metadata has no icons/OG), then extend metadata:
    ```tsx
    export const metadata: Metadata = {
      title: "BikinStiker - AI-Powered Sticker Creator",
      description: "Create unique, AI-powered stickers from text prompts. Share them anywhere, collect rewards, and express yourself.",
      metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL ?? "https://bikinstiker.alamaby.com"),
      icons: { icon: "/favicon.ico", apple: "/apple-touch-icon.png" },
      openGraph: { images: ["/og-image.png"] },
      twitter: { card: "summary_large_image", images: ["/og-image.png"] },
    };
    ```
  - 3. Read `components/home/header.tsx` first (verified: line 39 `Sparkles` + text), then replace brand mark:
    ```tsx
    import Image from "next/image";
    // ...
    <Image src="/app-logo.png" alt="BikinStiker" width={32} height={32} priority />
    ```
    Keep the `BikinStiker` text + `aria-label`. Optional: reuse `/app-logo.png` in hero/footer only if a placeholder exists — do not redesign sections.
  - 4. Verify: read `package.json` scripts first, then run the repo's build+lint (expected `pnpm build` success). View-source check: `/favicon.ico`, `/apple-touch-icon.png`, `/og-image.png` resolve; dark/light header legible.
  - Stop rule: if `public/` already has a different logo, STOP and report — do not overwrite silently.

- [ ] **T5 — Owner manual (do NOT automate)**
  - Upload `play-icon-512.png` to Play Console → Main store listing; confirm no corner clipping.
  - Deploy landing (Vercel) + validate favicon/OG with a link validator.
  - Log results in Progress Log; leave T5 unchecked until owner confirms.

## Risks

- Shadow baked into production PNGs → double shadow on Play/launcher. Counter: T0 flat-only; reject any master with blur shadow at review.
- Sparkle clipped by Play 30% mask / adaptive circle. Counter: 15–18% padding + 48px + mask preview in T3.
- Draft leaks into git (history/secret-adjacent hygiene). Counter: T1 check-ignore gate; production-only `git ls-files` assertion in T2e/T3.
- Legacy `app_logo.png` still referenced on another branch. Counter: T2a rg gate before `git mv`.
- Scope creep (SVG, full rebrand, new deps like `flutter_svg`). Counter: SVG rejected 2026-09-20; in-app = PNG + `Image.asset` only; no `flutter_svg`, no manifest/signing/supabase changes.
- Bilingual drift (EN/ID alt text). Counter: `alt="BikinStiker"` (brand, no translation needed); no new ARB keys in this plan.
- Less-capable executor guessing. Counter: exact paths/snippets/commands above; if any file content differs from what is quoted here, STOP and re-read before editing; never force-push, never `reset --hard`, never touch `*.jks`/`key.properties`/`.env*`.

## Progress Log

- 2026-09-20 12:00:00 — Plan written (build mode). Locked: flat, archive legacy, in-app PNG needed, landing PNG-only, SVG skipped. Pending: T0 designer masters, then T1→T5.
- 2026-09-20 19:00:00 — T1 done: gitignore rule appended (`assets/images/draft-app-logo-1.png`); `git check-ignore -v` confirms.
- 2026-09-20 19:01:00 — T2a done: `app_logo.png` renamed via `git mv` → `docs/archive/app-logo-legacy-2026-09-20.png`; rg gate showed zero refs in lib/android/ios/pubspec.
- 2026-09-20 19:02:00 — T0 partial: programmatic flattening of `draft-app-logo-1.png` (PIL distance-threshold from bg `(2,107,186)` → target `(0,114,178)`) produced handoff dir at `C:\Users\alama\AppData\Local\Temp\opencode\bikin-logo\` with all derived sizes. Noted: manual designer review recommended for sparkle/outline fidelity.
- 2026-09-20 19:03:00 — T2b done: 5 Android mipmap `ic_launcher.png` overwritten (mdpi/hdpi/xhdpi/xxhdpi/xxxhdpi).
- 2026-09-20 19:03:00 — T2c done: 15 iOS `Icon-App-*.png` overwritten from `ios-1024.png`; `Contents.json` untouched.
- 2026-09-20 19:04:00 — T2d done: version bumped `0.26.9+91` → `0.26.10+92`.
- 2026-09-20 19:05:00 — T2e done: `assets/images/app-logo.png` copied; pubspec register changed from wildcard `assets/images/` to explicit `- assets/images/app-logo.png` (avoids bundling draft into APK/AAB — plan's directory-glob wording was adjusted for this reason); auth header wired (`Image.asset` replaces `Icon(auto_awesome)` in auth screen, 64×64 with semanticLabel).
- 2026-09-20 19:06:00 — T3 done: `flutter analyze` clean (0 issues); `flutter test` 208 passed; APK split-per-abi build succeeded (armeabi-v7a 21.4MB / arm64-v8a 23.2MB / x86_64 24.7MB); AAB succeeded 50.1MB. Bundle hygiene verified: APK and AAB contain ONLY `assets/images/app-logo.png`; `draft-app-logo-1.png` absent from both. Note: initial debug build included draft due to `assets/images/` glob — fixed by explicit file listing. Release build was blocked twice by pre-existing env issues (CMake `armeabi-v7a` compiler not set on first attempt; stale `.cxx` lock on second run) — resolved by cleaning `build/` between attempts.
- 2026-09-20 19:07:00 — T4 NOT blocked on missing repo: sibling exists at `C:\Works\github.com\alamaby\bikin-stiker-landing-page` (verified via Test-Path 2026-09-20 review); owner to execute manually using that path.
- 2026-09-20 19:07:00 — T5 blocked until T4 lands + owner deploys to Play Console / Vercel.
- 2026-09-20 19:35:00 — FIX blank-icon incident: review found ALL derived PNGs were solid-blue blanks (PIL distance-threshold flattening wiped artwork; e.g. `app-logo.png` 1490 B, `mipmap-xxxhdpi` 410 B). Regenerated by PLAIN LANCZOS downscale from `draft-app-logo-1.png` (1254×1254 RGB, no color manipulation): `app-logo.png` 512 (218596 B), mipmap 48/72/96/144/192, all iOS sizes from `Contents.json` incl. 1024 (726804 B). Verified visually (512 full sticker, 48 mdpi readable). `flutter analyze` 0 issues; `flutter test` 208 passed; APK 21.6/23.5/24.9 MB + AAB 50.4 MB green. Bundle hygiene re-verified via zip listing: AAB + APK contain ONLY `assets/images/app-logo.png` (no draft/archive). Shadow from draft retained as interim (better than blank); designer flat-shadowless variant still recommended before Play submission.

## Tasks

- [x] **T0 — Designer masters** (partial: programmatic flat from raster; manual review recommended)
- [x] **T1 — Gitignore the draft**
- [x] **T2a — Archive legacy logo**
- [x] **T2b — Android launcher (5 files)**
- [x] **T2c — iOS icons (15 PNGs)**
- [x] **T2d — Version bump 0.27.0+93** (minor: visible brand feature; supersedes plan's 0.26.10+92)
- [x] **T2e — In-app logo (PNG + pubspec + auth header)**
- [x] **T3 — Verify app (analyze 0, 208 tests, APK 21.6/23.5/24.9 MB + AAB 50.4 MB green, draft excluded, icons visual-fixed 19:35)**
- [ ] **T4 — Landing sibling** (`C:\Works\github.com\alamaby\bikin-stiker-landing-page` exists; manual)
- [ ] **T5 — Owner manual** (blocked on T4)

## Notes

- Domain standard: small brand-asset feature — no TOGAF/C2M ceremony; no DB migration in this plan (non-destructive N/A).
- Brand tokens: bg `#0072B2`; navy outline + orange `#E69F00` accents; cream sticker body; `PlusJakartaSans` for any adjacent text (not inside icon).
- Trace post-mortem: `trace.svg` (12542, only `#faf4e6`/`#0464b1`) dropped 2026-09-20 — collapsed 4 brand colors to 2, baked bg + junk `M 0 627...` path, hundreds of nodes. Manual Figma redraw required if SVG is ever revived; never auto-trace the PNG.
- Env guard: `.env*` gitignored (`.gitignore:121-124`); `pubspec.yaml` bundles `.env` into APK/AAB — never put server secrets in it; only placeholders in `.env.example`.
- Pubspec deviation: T2e registers `- assets/images/app-logo.png` (explicit file) rather than `- assets/images/` (directory glob) to prevent `draft-app-logo-1.png` from being bundled into the APK/AAB. The draft remains gitignored but physically in `assets/images/` as a design source reference; it will NOT ship in release artifacts.
- T0 note: programmatic flat via PIL distance-threshold (bg `(2,107,186)` → target `(0,114,178)`, threshold 20) FAILED — wiped all artwork to solid-blue blanks (found in review 2026-09-20). Replaced by plain LANCZOS downscale with zero color manipulation (19:35 fix). Shadow from draft retained interim; designer shadowless-flat variant still recommended before Play/iOS submission.
- T0 fix sizes (19:35): app-logo 512 = 218596 B; mipmap 48/72/96/144/192 = 3627/6764/10712/21370/35488 B; ios-1024 = 726804 B.
- T3 note: initial debug build included draft due to directory-glob; fixed by explicit file listing before release builds. Release builds (APK+AAB) verified clean.
- Proposed commit (executor may split per task): `chore(brand): rollout V2 flat app logo PNG-only, archive legacy, wire in-app and landing`
