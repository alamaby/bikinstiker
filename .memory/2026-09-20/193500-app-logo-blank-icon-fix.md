# App Logo Blank-Icon Fix — threshold flatten reverted to plain downscale

Date: 2026-09-20 19:35:00

## Task
Review of commit `8f7e4d2` (plan `plans/2026-09-20-app-logo-rollout-plan.md`) found every derived PNG was a solid-blue blank. Fixed by plain downscale regeneration + re-verification.

## Key Files Changed
- `assets/images/app-logo.png` — regenerated 512 (1490 B blank → 218596 B artwork)
- `android/app/src/main/res/mipmap-*/ic_launcher.png` — 5 files regenerated (e.g. xxxhdpi 410 B → 35488 B)
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-*.png` — all sizes regenerated from `Contents.json` (incl. 1024 → 726804 B); `Contents.json` untouched
- `plans/2026-09-20-app-logo-rollout-plan.md` — T2d corrected to `0.27.0+93`, T4 path corrected, fix logged
- `lib/presentation/screens/auth/auth_screen.dart`, `pubspec.yaml`, `.gitignore`, `docs/archive/*` — unchanged by this fix (already correct)

## Technical Decisions
- **Root cause:** PIL distance-threshold flattening (`(2,107,186)` → `(0,114,178)`, threshold 20) classified the whole sticker as background and filled everything solid blue.
- **Fix:** plain `LANCZOS` resize, zero color manipulation. Draft shadow retained as interim — strictly better than blank; designer shadowless-flat variant still recommended before Play submission.
- **Version:** kept `0.27.0+93` (minor: user-visible brand feature). Plan text corrected; `0.26.10+92` never existed in code.
- **T4 correction:** sibling `C:\Works\github.com\alamaby\bikin-stiker-landing-page` EXISTS (Test-Path True) — prior "not present" log was a wrong path. T4 stays manual but unblocked.

## Verification
- Visual: `app-logo.png` 512 shows full sticker (face, sparkle, peel); `mipmap-mdpi` 48px still readable
- `flutter analyze`: 0 issues (18.3s)
- `flutter test`: 208 passed
- APK split-per-abi: 21.6 / 23.5 / 24.9 MB; AAB 50.4 MB
- Zip listing: AAB + arm64 APK contain ONLY `assets/images/app-logo.png` (no `draft-*`, no `archive`)

## Risks Noted
- Retained draft shadow violates Play "no baked shadow" guidance if uploaded as-is — designer flat variant should replace before store submission.
- Auth header `Image 64` (was `Icon 32`) doubles header weight; fits 320px screens but deserves designer review.

## Proposed Commit
`fix(brand): regenerate app icons by plain downscale, correct plan version and landing path`
