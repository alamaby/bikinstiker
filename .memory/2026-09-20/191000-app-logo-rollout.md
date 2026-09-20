# App Logo Rollout V2 — T1–T3 implemented, T4/T5 pending

Date: 2026-09-20 19:10:00

## Task
Implement plan `plans/2026-09-20-app-logo-rollout-plan.md` — roll out approved V2 flat logo as single identity across Flutter app + sibling landing. SVG out of scope. Legacy green WA glyph archived (not deleted).

## Key Files Changed
- `.gitignore` — append draft ignore rule
- `assets/images/app-logo.png` — new production in-app master (512×512, flat)
- `docs/archive/app-logo-legacy-2026-09-20.png` — legacy `app_logo.png` renamed via `git mv`
- `android/app/src/main/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png` — overwritten
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-{*}.png` — 15 PNGs overwritten; Contents.json untouched
- `pubspec.yaml` — version bumped `0.26.9+91` → `0.26.10+92`; assets register `- assets/images/app-logo.png` (explicit file, NOT wildcard directory)
- `lib/presentation/screens/auth/auth_screen.dart` — auth header: `Icon(auto_awesome)` replaced with `Image.asset('assets/images/app-logo.png', width:64, height:64, semanticLabel:'BikinStiker logo')`
- `plans/2026-09-20-app-logo-rollout-plan.md` — progress log updated, tasks checked

## Technical Decisions
- **Pubspec deviation:** Plan said `assets/images/` glob; using explicit `- assets/images/app-logo.png` to prevent `draft-app-logo-1.png` from being bundled into APK/AAB. Draft stays physically in `assets/images/` as design source reference, gitignored, but excluded from release artifacts.
- **T0 partial:** Programmatic flat via PIL (distance-threshold 20 from bg `(2,107,186)` → target `(0,114,178)`) produced all handoff masters at `C:\Users\alama\AppData\Local\Temp\opencode\bikin-logo\`. Manual designer review recommended for sparkle/outline fidelity before Play/iOS submission.
- **Build order matters:** First debug build included draft due to glob leak. Release APK/AAB clean after switching to explicit file registration.

## Verification
- `flutter analyze`: 0 issues
- `flutter test`: 208 passed
- APK split-per-abi: armeabi-v7a 21.4MB / arm64-v8a 23.2MB / x86_64 24.7MB
- AAB: 50.1MB
- Bundle hygiene: ZIP listing confirms only `assets/images/app-logo.png` in both APK and AAB; `draft-app-logo-1.png` absent

## Blocked / Pending
- **T4 (landing):** repo `bikin-stiker-landing-page` not present locally at expected path; owner to execute manually. Handoff files available at temp dir if needed.
- **T5 (owner manual):** blocked on T4 landing + Play Console upload + Vercel deploy.

## Risks Noted
- Programmatic flat may not perfectly preserve orange sparkle / navy outline detail vs. manual Figma export. Recommend designer spot-check before Play/iOS upload.
- Launchers on some devices show ~88% of icon (material adaptive circle). Sticker + sparkle must remain readable at 48px mdpi — visible in generated output but needs device confirmation.

## Proposed Commit
`chore(brand): rollout V2 flat app logo PNG-only, archive legacy, wire in-app`
